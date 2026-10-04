# ☕ Coffee Shop Sales Analysis | MySQL

An end-to-end SQL portfolio project: importing and cleaning 149K coffee shop transactions in **MySQL**, then writing queries to answer business questions on sales, orders, quantity, store performance, product mix, and peak trading hours.

---

## 📌 Table of Contents
1. [Business Problem](#-business-problem)
2. [Dataset](#-dataset)
3. [Tools & Skills](#-tools--skills)
4. [Project Workflow](#-project-workflow)
5. [Data Cleaning](#-data-cleaning)
6. [SQL Analysis](#-sql-analysis)
7. [Key Insights](#-key-insights)
8. [Recommendations](#-recommendations)
9. [Repository Structure](#-repository-structure)
10. [How to Run](#-how-to-run)
11. [Limitations & Next Steps](#-limitations--next-steps)
12. [Author](#-author)

---

## 🎯 Business Problem
A coffee shop chain with three New York locations wants to understand its sales performance. The analysis focuses on **May 2023** (the latest full month in the SQL queries) and compares it with **April 2023**.

**KPIs, each with month-over-month (MoM) difference and growth**
1. Total sales
2. Total orders
3. Total quantity sold

**Analysis questions**
1. What do daily sales, orders, and quantity look like for a single day (calendar view)?
2. How do daily sales trend through the month, and which days are above or below the monthly average?
3. How do weekday and weekend sales compare?
4. How does each store location perform?
5. Which product categories contribute the most to sales?
6. Which are the top 10 products by sales?
7. Which days of the week and hours of the day are the busiest?

---

## 📂 Dataset
| Item | Detail |
|---|---|
| File | `Coffee_Shop_Sales.xlsx` (sheet: `Transactions`) |
| Rows | 149,116 transactions |
| Period | 1 Jan 2023 to 30 Jun 2023 |
| Stores | 3 (Astoria, Hell's Kitchen, Lower Manhattan) |
| Products | 80 products, 29 product types, 9 categories |
| Missing values | None |
| Duplicate rows | None (`transaction_id` is unique) |

### Data dictionary
| Column | Type (after cleaning) | Description |
|---|---|---|
| `transaction_id` | INT | Unique ID of each transaction (one row = one order) |
| `transaction_date` | DATE | Date of the sale |
| `transaction_time` | TIME | Time of the sale |
| `transaction_qty` | INT | Units sold in the transaction (1 to 8) |
| `store_id` | INT | Store identifier (3, 5, 8) |
| `store_location` | TEXT | Store name |
| `product_id` | INT | Product identifier |
| `unit_price` | DOUBLE | Price per unit ($0.80 to $45.00) |
| `product_category` | TEXT | e.g. Coffee, Tea, Bakery |
| `product_type` | TEXT | e.g. Barista Espresso, Scone |
| `product_detail` | TEXT | Product name and size |

**Derived metrics**
- `Total Sales = unit_price × transaction_qty`
- `Total Orders = COUNT(transaction_id)`
- `Total Quantity = SUM(transaction_qty)`

---

## 🛠 Tools & Skills
- **MySQL / MySQL Workbench**: database creation, import, cleaning, analysis
- **Excel**: raw data source and file preparation (export to CSV)
- **SQL concepts:** `STR_TO_DATE`, `ALTER TABLE`, `UPDATE`, `CASE`, `GROUP BY`, aggregate functions, window functions (`LAG`, `AVG() OVER`), subqueries, `DAY`, `MONTH`, `DAYOFWEEK`, `HOUR`, `ROUND`, `CONCAT`, `LIMIT`

---

## 🔄 Project Workflow
1. Walk through the raw data and prepare the file (Excel to CSV)
2. Create the database and import the file
3. Clean the data and change data types
4. Write SQL queries for each business requirement
5. Store the query results
6. Document the SQL and insights

---

## 🧹 Data Cleaning
The CSV imports with dates and times as text, so they are converted to proper types first.

**1. Convert the date column to a proper date format, then change its data type**
```sql
UPDATE coffee_shop_sales
SET transaction_date = STR_TO_DATE(transaction_date, '%d-%m-%Y');

ALTER TABLE coffee_shop_sales
MODIFY COLUMN transaction_date DATE;
```

**2. Convert the time column to a proper time format, then change its data type**
```sql
UPDATE coffee_shop_sales
SET transaction_time = STR_TO_DATE(transaction_time, '%H:%i:%s');

ALTER TABLE coffee_shop_sales
MODIFY COLUMN transaction_time TIME;
```

**3. Check the data types of all columns**
```sql
DESCRIBE coffee_shop_sales;
```

**4. Fix the first column name.** The import added a hidden character (BOM), so the column appeared as `ï»¿transaction_id`.
```sql
ALTER TABLE coffee_shop_sales
CHANGE COLUMN `ï»¿transaction_id` transaction_id INT;
```

---

## 📊 SQL Analysis
All queries below filter on **May (month 5)**. Change the month number to analyse another month.

### 1. Total sales
```sql
SELECT ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5;   -- May (current month)
```
**Result: $156,728**

**Total sales KPI: MoM difference and growth (April vs May)**
```sql
SELECT
    MONTH(transaction_date) AS month,
    ROUND(SUM(unit_price * transaction_qty)) AS total_sales,
    (SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty), 1)
        OVER (ORDER BY MONTH(transaction_date)))
        / LAG(SUM(unit_price * transaction_qty), 1)
        OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage
FROM coffee_shop_sales
WHERE MONTH(transaction_date) IN (4, 5)   -- April and May
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date);
```
| Month | Total sales | MoM growth |
|---|---|---|
| 4 (April) | 118,941 | NULL (no previous month in the filter) |
| 5 (May) | 156,728 | **+31.77%** |

### 2. Total orders
```sql
SELECT COUNT(transaction_id) AS Total_Orders
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5;
```
**Result: 33,527 orders**

**Total orders KPI: MoM difference and growth**
```sql
SELECT
    MONTH(transaction_date) AS month,
    ROUND(COUNT(transaction_id)) AS total_orders,
    (COUNT(transaction_id) - LAG(COUNT(transaction_id), 1)
        OVER (ORDER BY MONTH(transaction_date)))
        / LAG(COUNT(transaction_id), 1)
        OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage
FROM coffee_shop_sales
WHERE MONTH(transaction_date) IN (4, 5)
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date);
```
| Month | Total orders | MoM growth |
|---|---|---|
| 4 (April) | 25,335 | NULL |
| 5 (May) | 33,527 | **+32.33%** |

### 3. Total quantity sold
```sql
SELECT SUM(transaction_qty) AS Total_Quantity_Sold
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5;
```
**Result: 48,233 units**

**Total quantity KPI: MoM difference and growth**
```sql
SELECT
    MONTH(transaction_date) AS month,
    ROUND(SUM(transaction_qty)) AS total_quantity_sold,
    (SUM(transaction_qty) - LAG(SUM(transaction_qty), 1)
        OVER (ORDER BY MONTH(transaction_date)))
        / LAG(SUM(transaction_qty), 1)
        OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage
FROM coffee_shop_sales
WHERE MONTH(transaction_date) IN (4, 5)
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date);
```
| Month | Total quantity | MoM growth |
|---|---|---|
| 4 (April) | 36,469 | NULL |
| 5 (May) | 48,233 | **+32.26%** |

**KPI summary (May vs April)**
| KPI | April | May | Difference | MoM growth |
|---|---|---|---|---|
| Total sales | $118,941 | $156,728 | +$37,787 | +31.77% |
| Total orders | 25,335 | 33,527 | +8,192 | +32.33% |
| Total quantity | 36,469 | 48,233 | +11,764 | +32.26% |

### 4. Calendar table: daily sales, quantity, and orders
```sql
SELECT
    SUM(unit_price * transaction_qty) AS total_sales,
    SUM(transaction_qty)              AS total_quantity_sold,
    COUNT(transaction_id)             AS total_orders
FROM coffee_shop_sales
WHERE transaction_date = '2023-05-18';   -- 18 May 2023
```
**Result (18 May 2023): $5,583.47 sales, 1,659 units, 1,192 orders**

To show the values in rounded "K" format:
```sql
SELECT
    CONCAT(ROUND(SUM(unit_price * transaction_qty) / 1000, 1), 'K') AS total_sales,
    CONCAT(ROUND(COUNT(transaction_id) / 1000, 1), 'K')             AS total_orders,
    CONCAT(ROUND(SUM(transaction_qty) / 1000, 1), 'K')              AS total_quantity_sold
FROM coffee_shop_sales
WHERE transaction_date = '2023-05-18';
```
**Result: 5.6K sales, 1.2K orders, 1.7K units**

### 5. Sales trend over the period (average daily sales)
```sql
SELECT AVG(total_sales) AS average_sales
FROM (
    SELECT SUM(unit_price * transaction_qty) AS total_sales
    FROM coffee_shop_sales
    WHERE MONTH(transaction_date) = 5          -- May
    GROUP BY transaction_date
) AS internal_query;
```
The inner query totals sales for each date in May; the outer query averages those daily totals.

**Result: about $5,055.73 average daily sales in May**

**Daily sales for the selected month**
```sql
SELECT
    DAY(transaction_date) AS day_of_month,
    ROUND(SUM(unit_price * transaction_qty), 1) AS total_sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5
GROUP BY DAY(transaction_date)
ORDER BY DAY(transaction_date);
```

**Daily sales compared with the average (above, below, or equal)**
```sql
SELECT
    day_of_month,
    CASE
        WHEN total_sales > avg_sales THEN 'Above Average'
        WHEN total_sales < avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_status,
    total_sales
FROM (
    SELECT
        DAY(transaction_date) AS day_of_month,
        SUM(unit_price * transaction_qty) AS total_sales,
        AVG(SUM(unit_price * transaction_qty)) OVER () AS avg_sales
    FROM coffee_shop_sales
    WHERE MONTH(transaction_date) = 5
    GROUP BY DAY(transaction_date)
) AS sales_data
ORDER BY day_of_month;
```
**Result: 17 days above average and 14 days below.** The best day was 19 May ($5,657.90) and the weakest was 29 May ($3,959.50).

### 6. Sales by weekday and weekend
```sql
SELECT
    CASE WHEN DAYOFWEEK(transaction_date) IN (1, 7) THEN 'Weekends'
         ELSE 'Weekdays' END AS day_type,
    ROUND(SUM(unit_price * transaction_qty), 2) AS total_sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5
GROUP BY CASE WHEN DAYOFWEEK(transaction_date) IN (1, 7) THEN 'Weekends'
              ELSE 'Weekdays' END;
```
| Day type | Total sales | Share |
|---|---|---|
| Weekdays | $116,627.84 | 74.4% |
| Weekends | $40,099.92 | 25.6% |

### 7. Sales by store location
```sql
SELECT
    store_location,
    SUM(unit_price * transaction_qty) AS Total_Sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5
GROUP BY store_location
ORDER BY SUM(unit_price * transaction_qty) DESC;
```
| Store | Total sales (May) |
|---|---|
| Hell's Kitchen | $52,598.93 |
| Astoria | $52,428.76 |
| Lower Manhattan | $51,700.07 |

### 8. Sales by product category
```sql
SELECT
    product_category,
    ROUND(SUM(unit_price * transaction_qty), 1) AS Total_Sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5
GROUP BY product_category
ORDER BY SUM(unit_price * transaction_qty) DESC;
```
| Category | Total sales (May) | Share |
|---|---|---|
| Coffee | $60,362.8 | 38.5% |
| Tea | $44,539.8 | 28.4% |
| Bakery | $18,565.5 | 11.8% |
| Drinking Chocolate | $16,319.8 | 10.4% |
| Coffee beans | $8,769.0 | 5.6% |
| Branded | $2,889.0 | 1.8% |
| Loose Tea | $2,395.2 | 1.5% |
| Flavours | $1,905.6 | 1.2% |
| Packaged Chocolate | $981.1 | 0.6% |

### 9. Top 10 products by sales
```sql
SELECT
    product_type,
    ROUND(SUM(unit_price * transaction_qty), 1) AS Total_Sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5
GROUP BY product_type
ORDER BY SUM(unit_price * transaction_qty) DESC
LIMIT 10;
```
| Rank | Product type | Total sales (May) |
|---|---|---|
| 1 | Barista Espresso | $20,423.8 |
| 2 | Brewed Chai tea | $17,427.4 |
| 3 | Hot chocolate | $16,319.8 |
| 4 | Gourmet brewed coffee | $15,559.2 |
| 5 | Brewed herbal tea | $10,930.0 |
| 6 | Brewed Black tea | $10,778.0 |
| 7 | Premium brewed coffee | $8,739.2 |
| 8 | Organic brewed coffee | $8,350.2 |
| 9 | Scone | $8,305.3 |
| 10 | Drip coffee | $7,290.5 |

### 10. Sales by day and hour
**One specific day and hour (Tuesday, 8 AM, May)**
```sql
SELECT
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales,
    SUM(transaction_qty)                     AS Total_Quantity,
    COUNT(*)                                 AS Total_Orders
FROM coffee_shop_sales
WHERE DAYOFWEEK(transaction_date) = 3   -- Tuesday (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
  AND HOUR(transaction_time) = 8        -- 8 AM
  AND MONTH(transaction_date) = 5;      -- May
```
**Result: $2,969 sales, 874 units, 612 orders**

**Sales for each day of the week (May)**
```sql
SELECT
    CASE
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        ELSE 'Sunday'
    END AS Day_of_Week,
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5
GROUP BY CASE
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        ELSE 'Sunday'
    END;
```
| Day | Total sales (May) | Days in May | Average per day |
|---|---|---|---|
| Monday | $25,221 | 5 | $5,044 |
| Tuesday | $25,347 | 5 | $5,069 |
| Wednesday | $25,465 | 5 | $5,093 |
| Thursday | $20,254 | 4 | $5,064 |
| Friday | $20,341 | 4 | $5,085 |
| Saturday | $20,795 | 4 | $5,199 |
| Sunday | $19,305 | 4 | $4,826 |

**Sales for every hour of the day (May)**
```sql
SELECT
    HOUR(transaction_time) AS Hour_of_Day,
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5
GROUP BY HOUR(transaction_time)
ORDER BY HOUR(transaction_time);
```
| Hour | Sales | Hour | Sales |
|---|---|---|---|
| 6 AM | $4,913 | 1 PM | $9,379 |
| 7 AM | $14,351 | 2 PM | $9,058 |
| 8 AM | $18,822 | 3 PM | $9,525 |
| 9 AM | $19,145 | 4 PM | $9,154 |
| 10 AM | $19,639 | 5 PM | $8,967 |
| 11 AM | $10,312 | 6 PM | $7,680 |
| 12 PM | $8,870 | 7 PM | $6,256 |
| | | 8 PM | $656 |

> All queries are in [`sql/coffee_shop_queries.sql`](sql/coffee_shop_queries.sql). Screenshots of each result grid are in [`screenshots/`](screenshots/).

---

## 💡 Key Insights
*(May 2023, compared with April 2023)*

| KPI | May 2023 | MoM growth |
|---|---|---|
| Total sales | **$156.7K** | +31.8% |
| Total orders | **33,527** | +32.3% |
| Total quantity sold | **48,233 units** | +32.3% |

1. **Strong, broad growth.** Sales, orders, and quantity all grew by about 32% from April to May. Orders grew slightly faster than sales, so the average order value held steady at about $4.70.
2. **Coffee and tea drive the business.** Coffee (38.5%) and Tea (28.4%) together make up about two-thirds of May sales. Bakery (11.8%) and Drinking Chocolate (10.4%) follow.
3. **Top products:** Barista Espresso ($20.4K), Brewed Chai tea ($17.4K), and Hot chocolate ($16.3K) lead the top 10.
4. **The three stores are close:** Hell's Kitchen leads with $52.6K, followed by Astoria ($52.4K) and Lower Manhattan ($51.7K), a gap of less than 2% between first and last.
5. **Weekdays vs weekends:** weekdays brought in 74.4% of sales and weekends 25.6%. This is in line with the number of days (weekends were 8 of May's 31 days), so average daily sales are similar on weekdays and weekends.
6. **Day-of-week totals need care.** Monday to Wednesday show about $25K each against about $20K for the other days, but May 2023 has five Mondays, Tuesdays, and Wednesdays and only four of each other day. Per day, sales are nearly flat ($4.8K to $5.2K), with Saturday the highest and Sunday the lowest.
7. **A strong morning rush.** 8 to 10 AM generates about 37% of May sales, and sales peak at 10 AM ($19.6K). There is a sharp drop at 11 AM (to $10.3K), sales stay at about $9K per hour through the afternoon, and trading falls away after 6 PM.
8. **Daily sales are fairly steady:** 17 of 31 days were above the $5,056 daily average. The weakest days were 28 and 29 May (about $4.3K and $4.0K).

---


---

## 👤 Author
**Abhay Sharma**
Data Analyst | SQL · Excel
[GitHub](https://github.com/sharmaabhay2181-rgb)
