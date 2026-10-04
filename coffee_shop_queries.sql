/* =====================================================================
   COFFEE SHOP SALES ANALYSIS  |  MySQL
   Table   : coffee_shop_sales (149,116 rows, 1 Jan 2023 to 30 Jun 2023)
   Focus   : May 2023 (month 5), compared with April 2023 (month 4)
   Tip     : change MONTH(transaction_date) = 5 to analyse another month
   ===================================================================== */

CREATE DATABASE IF NOT EXISTS coffee_shop_db;
USE coffee_shop_db;
-- Import the CSV into a table named coffee_shop_sales first
-- (Workbench: right-click the table > Table Data Import Wizard).


/* =====================================================================
   PART 1: DATA CLEANING
   ===================================================================== */

-- 1.1 Convert the date column to a proper date format
UPDATE coffee_shop_sales
SET transaction_date = STR_TO_DATE(transaction_date, '%d-%m-%Y');

-- 1.2 Change the date column to the DATE data type
ALTER TABLE coffee_shop_sales
MODIFY COLUMN transaction_date DATE;

-- 1.3 Convert the time column to a proper time format
UPDATE coffee_shop_sales
SET transaction_time = STR_TO_DATE(transaction_time, '%H:%i:%s');

-- 1.4 Change the time column to the TIME data type
ALTER TABLE coffee_shop_sales
MODIFY COLUMN transaction_time TIME;

-- 1.5 Check the data types of all columns
DESCRIBE coffee_shop_sales;

-- 1.6 Fix the first column name (the import adds a hidden BOM character)
ALTER TABLE coffee_shop_sales
CHANGE COLUMN `ï»¿transaction_id` transaction_id INT;

-- 1.7 Validate: expect 149116 rows
SELECT COUNT(*) AS total_rows FROM coffee_shop_sales;


/* =====================================================================
   PART 2: KPIs
   ===================================================================== */

-- 2.1 TOTAL SALES (May)
SELECT ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5;                 -- May (current month)

-- 2.2 TOTAL SALES KPI: MoM difference and growth (April vs May)
SELECT
    MONTH(transaction_date) AS month,
    ROUND(SUM(unit_price * transaction_qty)) AS total_sales,
    (SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty), 1)
        OVER (ORDER BY MONTH(transaction_date)))
        / LAG(SUM(unit_price * transaction_qty), 1)
        OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage
FROM coffee_shop_sales
WHERE MONTH(transaction_date) IN (4, 5)            -- April and May
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date);

-- 2.3 TOTAL ORDERS (May)
SELECT COUNT(transaction_id) AS Total_Orders
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5;

-- 2.4 TOTAL ORDERS KPI: MoM difference and growth
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

-- 2.5 TOTAL QUANTITY SOLD (May)
SELECT SUM(transaction_qty) AS Total_Quantity_Sold
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5;

-- 2.6 TOTAL QUANTITY SOLD KPI: MoM difference and growth
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


/* =====================================================================
   PART 3: CALENDAR VIEW AND DAILY TRENDS
   ===================================================================== */

-- 3.1 CALENDAR TABLE: daily sales, quantity and total orders (18 May 2023)
SELECT
    SUM(unit_price * transaction_qty) AS total_sales,
    SUM(transaction_qty)              AS total_quantity_sold,
    COUNT(transaction_id)             AS total_orders
FROM coffee_shop_sales
WHERE transaction_date = '2023-05-18';

-- 3.2 Same day, shown as rounded "K" values
SELECT
    CONCAT(ROUND(SUM(unit_price * transaction_qty) / 1000, 1), 'K') AS total_sales,
    CONCAT(ROUND(COUNT(transaction_id) / 1000, 1), 'K')             AS total_orders,
    CONCAT(ROUND(SUM(transaction_qty) / 1000, 1), 'K')              AS total_quantity_sold
FROM coffee_shop_sales
WHERE transaction_date = '2023-05-18';

-- 3.3 SALES TREND OVER PERIOD: average daily sales in May
SELECT AVG(total_sales) AS average_sales
FROM (
    SELECT SUM(unit_price * transaction_qty) AS total_sales
    FROM coffee_shop_sales
    WHERE MONTH(transaction_date) = 5              -- May
    GROUP BY transaction_date
) AS internal_query;

-- 3.4 DAILY SALES for the month selected
SELECT
    DAY(transaction_date) AS day_of_month,
    ROUND(SUM(unit_price * transaction_qty), 1) AS total_sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5
GROUP BY DAY(transaction_date)
ORDER BY DAY(transaction_date);

-- 3.5 Compare daily sales with the average: Above Average / Below Average
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


/* =====================================================================
   PART 4: WEEKDAY / WEEKEND, STORES, PRODUCTS
   ===================================================================== */

-- 4.1 SALES BY WEEKDAY / WEEKEND
SELECT
    CASE WHEN DAYOFWEEK(transaction_date) IN (1, 7) THEN 'Weekends'
         ELSE 'Weekdays' END AS day_type,
    ROUND(SUM(unit_price * transaction_qty), 2) AS total_sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5
GROUP BY CASE WHEN DAYOFWEEK(transaction_date) IN (1, 7) THEN 'Weekends'
              ELSE 'Weekdays' END;

-- 4.2 SALES BY STORE LOCATION
SELECT
    store_location,
    SUM(unit_price * transaction_qty) AS Total_Sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5
GROUP BY store_location
ORDER BY SUM(unit_price * transaction_qty) DESC;

-- 4.3 SALES BY PRODUCT CATEGORY
SELECT
    product_category,
    ROUND(SUM(unit_price * transaction_qty), 1) AS Total_Sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5
GROUP BY product_category
ORDER BY SUM(unit_price * transaction_qty) DESC;

-- 4.4 SALES BY PRODUCTS (TOP 10)
SELECT
    product_type,
    ROUND(SUM(unit_price * transaction_qty), 1) AS Total_Sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5
GROUP BY product_type
ORDER BY SUM(unit_price * transaction_qty) DESC
LIMIT 10;


/* =====================================================================
   PART 5: SALES BY DAY AND HOUR
   ===================================================================== */

-- 5.1 One specific day and hour: Tuesday, 8 AM, May
SELECT
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales,
    SUM(transaction_qty)                     AS Total_Quantity,
    COUNT(*)                                 AS Total_Orders
FROM coffee_shop_sales
WHERE DAYOFWEEK(transaction_date) = 3   -- Tuesday (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
  AND HOUR(transaction_time) = 8        -- hour number 8
  AND MONTH(transaction_date) = 5;      -- May

-- 5.2 Sales from Monday to Sunday for the month of May
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

-- 5.3 Sales for all hours for the month of May
SELECT
    HOUR(transaction_time) AS Hour_of_Day,
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5
GROUP BY HOUR(transaction_time)
ORDER BY HOUR(transaction_time);
