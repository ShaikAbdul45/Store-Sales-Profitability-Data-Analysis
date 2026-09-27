/*
================================================================================
📊 STORE SALES & PROFITABILITY DATA ANALYSIS
🛠️ Tech Stack: MySQL 8.0+ | Data Modeling | Business Intelligence
📁 File: sql_scripts/sales_queries.sql
🎯 Purpose: Schema Definition, Data Auditing, KPI Generation, & Strategic Business Insights
================================================================================
TABLE OF CONTENTS:
  1. DATABASE & SCHEMA DEFINITION (DDL)
  2. DATA IMPORT LOGIC
  3. DATA AUDITING & INTEGRITY VALIDATION
  4. EXECUTIVE KPI CALCULATIONS
  5. CATEGORY & SUB-CATEGORY PERFORMANCE (PROFIT LEAKS & DISCOUNT IMPACT)
  6. GEOGRAPHIC & REGIONAL DISPARITY ANALYSIS (CENTRAL REGION DEFICIT DEEP-DIVE)
  7. CUSTOMER SEGMENTATION & BEHAVIOR
  8. TIME-SERIES INTELLIGENCE & SEASONAL TRENDS (Q4 SURGE ANALYSIS)
  9. ADVANCED BUSINESS LOGIC (WINDOW FUNCTIONS, CTES, & PARETO 80/20)
================================================================================
*/

-- ================================================================================
-- SECTION 1: DATABASE & SCHEMA DEFINITION (DDL)
-- ================================================================================

CREATE DATABASE IF NOT EXISTS store_sales_analytics;
USE store_sales_analytics;

-- Drop tables if re-running script to ensure clean state
DROP TABLE IF EXISTS returns;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS regional_managers;

-- 1.1 Regional Managers (Territory Dimension)
CREATE TABLE regional_managers (
    regional_manager VARCHAR(50) NOT NULL,
    region           VARCHAR(25) NOT NULL,
    PRIMARY KEY (region)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 1.2 Orders Fact / Transaction Table
CREATE TABLE orders (
    row_id         INT NOT NULL,
    order_id       VARCHAR(25) NOT NULL,
    order_date     DATE NOT NULL,
    ship_date      DATE NOT NULL,
    ship_mode      VARCHAR(25) NOT NULL,
    customer_id    VARCHAR(20) NOT NULL,
    customer_name  VARCHAR(100) NOT NULL,
    segment        VARCHAR(25) NOT NULL,
    country        VARCHAR(50) NOT NULL,
    city           VARCHAR(50) NOT NULL,
    state          VARCHAR(50) NOT NULL,
    postal_code    VARCHAR(10),
    region         VARCHAR(25) NOT NULL,
    product_id     VARCHAR(25) NOT NULL,
    category       VARCHAR(30) NOT NULL,
    sub_category   VARCHAR(30) NOT NULL,
    product_name   VARCHAR(255) NOT NULL,
    sales          DECIMAL(10, 4) NOT NULL,
    quantity       INT NOT NULL,
    discount       DECIMAL(4, 2) NOT NULL,
    profit         DECIMAL(10, 4) NOT NULL,
    PRIMARY KEY (row_id),
    INDEX idx_order_id (order_id),
    INDEX idx_order_date (order_date),
    INDEX idx_region (region),
    INDEX idx_category (category),
    INDEX idx_sub_category (sub_category),
    INDEX idx_customer_id (customer_id),
    CONSTRAINT fk_orders_region FOREIGN KEY (region) REFERENCES regional_managers(region)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 1.3 Returns Table
CREATE TABLE returns (
    returned VARCHAR(5) NOT NULL,
    order_id VARCHAR(25) NOT NULL,
    PRIMARY KEY (order_id),
    INDEX idx_returns_order_id (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ================================================================================
-- SECTION 2: DATA IMPORT LOGIC
-- ================================================================================
/*
NOTE: Replace file paths with your absolute local path or use MySQL Workbench Table Data Import Wizard:
  - orders:            dataset/cleaned_orders.csv
  - returns:           dataset/cleaned_returns.csv
  - regional_managers: dataset/cleaned_people.csv

Sample Infile Syntax (requires local_infile enabled):
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'dataset/cleaned_people.csv'
INTO TABLE regional_managers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(regional_manager, region);

LOAD DATA LOCAL INFILE 'dataset/cleaned_orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(row_id, order_id, order_date, ship_date, ship_mode, customer_id, customer_name,
 segment, country, city, state, postal_code, region, product_id, category,
 sub_category, product_name, sales, quantity, discount, profit);

LOAD DATA LOCAL INFILE 'dataset/cleaned_returns.csv'
INTO TABLE returns
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(returned, order_id);
*/

-- Seed Regional Managers directly for immediate execution capability
INSERT INTO regional_managers (regional_manager, region) VALUES
('Anna Andreadi', 'West'),
('Chuck Magee', 'East'),
('Kelly Williams', 'Central'),
('Cassandra Brandow', 'South')
ON DUPLICATE KEY UPDATE regional_manager = VALUES(regional_manager);


-- ================================================================================
-- SECTION 3: DATA AUDITING & INTEGRITY VALIDATION
-- ================================================================================

-- 3.1 Verify total row count matches expected 9,994 transactions
SELECT 'Orders Count' AS audit_metric, COUNT(*) AS record_count,
       CASE WHEN COUNT(*) = 9994 THEN 'PASS (Exact match)' ELSE 'FAIL (Investigate)' END AS status
FROM orders;

-- 3.2 Audit for critical NULL values or missing keys
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN row_id IS NULL THEN 1 ELSE 0 END) AS null_row_ids,
    SUM(CASE WHEN order_id IS NULL OR TRIM(order_id) = '' THEN 1 ELSE 0 END) AS null_order_ids,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS null_order_dates,
    SUM(CASE WHEN ship_date IS NULL THEN 1 ELSE 0 END) AS null_ship_dates,
    SUM(CASE WHEN sales IS NULL THEN 1 ELSE 0 END) AS null_sales,
    SUM(CASE WHEN profit IS NULL THEN 1 ELSE 0 END) AS null_profits,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_ids
FROM orders;

-- 3.3 Check for Primary Key uniqueness (Row ID)
SELECT row_id, COUNT(*) AS occurrences
FROM orders
GROUP BY row_id
HAVING COUNT(*) > 1;

-- 3.4 Logic Validation: Fulfillment dates must be on or after order placement
SELECT COUNT(*) AS date_logic_violations
FROM orders
WHERE ship_date < order_date;

-- 3.5 Discount Range Sanity Check (Discounts must be between 0% and 100%)
SELECT COUNT(*) AS invalid_discount_records
FROM orders
WHERE discount < 0.00 OR discount > 1.00;

-- 3.6 Check for Orphaned Returns (Returns without corresponding order records)
SELECT r.order_id AS orphaned_return_order_id
FROM returns r
LEFT JOIN orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ================================================================================
-- SECTION 4: CORE EXECUTIVE KPI CALCULATIONS
-- Answers Business Question 1: Total Revenue, Profit, and Profit Margin %
-- ================================================================================

SELECT 
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_pct,
    SUM(quantity) AS total_units_sold,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT product_id) AS distinct_products_sold,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS average_order_value_aov,
    ROUND(AVG(discount) * 100, 2) AS average_discount_rate_pct
FROM orders;

-- 4.1 Order Return Rate %
SELECT 
    COUNT(DISTINCT o.order_id) AS total_orders_placed,
    COUNT(DISTINCT r.order_id) AS total_orders_returned,
    ROUND((COUNT(DISTINCT r.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) AS order_return_rate_pct
FROM orders o
LEFT JOIN returns r ON o.order_id = r.order_id;


-- ================================================================================
-- SECTION 5: CATEGORY & SUB-CATEGORY PROFITABILITY & PROFIT LEAKS
-- Answers Business Question 2: High volume vs high profit margin drivers
-- ================================================================================

-- 5.1 Category High-Level Benchmark
SELECT 
    category,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(discount) * 100, 2) AS avg_discount_pct
FROM orders
GROUP BY category
ORDER BY total_profit DESC;

-- 5.2 Sub-Category Detailed Profitability & Identification of "Profit Leaks"
SELECT 
    category,
    sub_category,
    SUM(quantity) AS total_units,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(discount) * 100, 2) AS avg_discount_pct,
    CASE 
        WHEN SUM(profit) < 0 THEN 'PROFIT LEAK (Net Loss)'
        WHEN (SUM(profit) / SUM(sales)) >= 0.20 THEN 'HIGH MARGIN (Star Performer)'
        ELSE 'MODERATE MARGIN'
    END AS operational_health
FROM orders
GROUP BY category, sub_category
ORDER BY total_profit ASC;

-- 5.3 Discount Impact Analysis: Proving How Excessive Discounting Causes Net Losses
-- Segments transactions into 5 discount tiers to observe margin decay
SELECT 
    CASE 
        WHEN discount = 0.00 THEN '0% (No Discount)'
        WHEN discount > 0.00 AND discount <= 0.10 THEN '1% - 10%'
        WHEN discount > 0.10 AND discount <= 0.20 THEN '11% - 20%'
        WHEN discount > 0.20 AND discount <= 0.40 THEN '21% - 40%'
        ELSE 'Over 40% (Heavy Discount)'
    END AS discount_tier,
    COUNT(*) AS total_transactions,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY discount_tier
ORDER BY MIN(discount) ASC;

-- 5.4 Top 10 Most Profitable Products
SELECT 
    product_name,
    category,
    sub_category,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY product_name, category, sub_category
ORDER BY total_profit DESC
LIMIT 10;

-- 5.5 Top 10 Biggest Loss-Making Products (Severe Profit Bleeders)
SELECT 
    product_name,
    category,
    sub_category,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_loss,
    ROUND(AVG(discount) * 100, 2) AS avg_discount_applied
FROM orders
GROUP BY product_name, category, sub_category
HAVING total_loss < 0
ORDER BY total_loss ASC
LIMIT 10;


-- ================================================================================
-- SECTION 6: GEOGRAPHIC & REGIONAL DISPARITY ANALYSIS
-- Answers Business Question 3: Regions/States operating at a net loss
-- ================================================================================

-- 6.1 Performance by Territory & Regional Leadership
SELECT 
    o.region,
    rm.regional_manager,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.sales), 2) AS total_sales,
    ROUND(SUM(o.profit), 2) AS total_profit,
    ROUND((SUM(o.profit) / SUM(o.sales)) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(o.discount) * 100, 2) AS avg_discount_pct
FROM orders o
JOIN regional_managers rm ON o.region = rm.region
GROUP BY o.region, rm.regional_manager
ORDER BY total_sales DESC;

-- 6.2 Deep Dive: Central Region State Profitability (Validating Texas & Illinois Deficit)
SELECT 
    state,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(discount) * 100, 2) AS avg_discount_pct,
    CASE 
        WHEN SUM(profit) < 0 THEN 'CRITICAL LOSS'
        ELSE 'PROFITABLE'
    END AS regional_status
FROM orders
WHERE region = 'Central'
GROUP BY state
ORDER BY total_profit ASC;

-- 6.3 Bottom 10 Loss-Making States Nationally
SELECT 
    region,
    state,
    COUNT(DISTINCT order_id) AS order_volume,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS net_profit,
    ROUND(AVG(discount) * 100, 2) AS avg_discount_pct
FROM orders
GROUP BY region, state
HAVING net_profit < 0
ORDER BY net_profit ASC
LIMIT 10;

-- 6.4 Top 10 Loss-Making Cities Nationally
SELECT 
    state,
    city,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS net_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(discount) * 100, 2) AS avg_discount_pct
FROM orders
GROUP BY state, city
HAVING net_profit < 0
ORDER BY net_profit ASC
LIMIT 10;


-- ================================================================================
-- SECTION 7: CUSTOMER SEGMENTATION & BEHAVIOR
-- ================================================================================

-- 7.1 Performance by Customer Segment
SELECT 
    segment,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(sales) / (SELECT SUM(sales) FROM orders) * 100, 2) AS revenue_share_pct,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_pct,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS average_order_value_aov
FROM orders
GROUP BY segment
ORDER BY total_sales DESC;

-- 7.2 Top 10 High-Value Customers (Customer Lifetime Value)
SELECT 
    customer_id,
    customer_name,
    segment,
    COUNT(DISTINCT order_id) AS total_orders_placed,
    SUM(quantity) AS total_units_bought,
    ROUND(SUM(sales), 2) AS lifetime_sales,
    ROUND(SUM(profit), 2) AS lifetime_profit_generated,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS customer_margin_pct
FROM orders
GROUP BY customer_id, customer_name, segment
ORDER BY lifetime_sales DESC
LIMIT 10;


-- ================================================================================
-- SECTION 8: TIME-SERIES INTELLIGENCE & SEASONAL TRENDS
-- Answers Business Question 4: Monthly trends & Q4 seasonal spike validation
-- ================================================================================

-- 8.1 Annual Performance Trends & Year-over-Year (YoY) Growth
SELECT 
    YEAR(order_date) AS order_year,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY YEAR(order_date)
ORDER BY order_year ASC;

-- 8.2 Monthly Aggregation: Historical Surge in Q4 (November & December)
SELECT 
    MONTH(order_date) AS month_number,
    MONTHNAME(order_date) AS month_name,
    COUNT(DISTINCT order_id) AS order_volume,
    SUM(quantity) AS units_sold,
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_pct,
    CASE 
        WHEN MONTH(order_date) IN (11, 12) THEN 'Q4 HOLIDAY PEAK'
        WHEN MONTH(order_date) IN (9, 10)  THEN 'FALL RAMP-UP'
        ELSE 'STANDARD CYCLE'
    END AS seasonal_cycle
FROM orders
GROUP BY MONTH(order_date), MONTHNAME(order_date)
ORDER BY month_number ASC;

-- 8.3 Quarterly Revenue & Profit Progression
SELECT 
    YEAR(order_date) AS order_year,
    QUARTER(order_date) AS order_quarter,
    CONCAT(YEAR(order_date), '-Q', QUARTER(order_date)) AS year_quarter,
    ROUND(SUM(sales), 2) AS quarterly_sales,
    ROUND(SUM(profit), 2) AS quarterly_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS margin_pct
FROM orders
GROUP BY YEAR(order_date), QUARTER(order_date), year_quarter
ORDER BY order_year, order_quarter;

-- 8.4 Month-over-Month (MoM) Growth using LAG() Window Function
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS year_month,
        ROUND(SUM(sales), 2) AS current_month_sales,
        ROUND(SUM(profit), 2) AS current_month_profit
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT 
    year_month,
    current_month_sales,
    LAG(current_month_sales, 1) OVER (ORDER BY year_month) AS previous_month_sales,
    ROUND(
        ((current_month_sales - LAG(current_month_sales, 1) OVER (ORDER BY year_month)) / 
        LAG(current_month_sales, 1) OVER (ORDER BY year_month)) * 100, 2
    ) AS mom_sales_growth_pct,
    current_month_profit
FROM monthly_sales
ORDER BY year_month;


-- ================================================================================
-- SECTION 9: ADVANCED BUSINESS LOGIC (WINDOW FUNCTIONS & CTES)
-- ================================================================================

-- 9.1 Top 3 Selling Products Per Category Using DENSE_RANK()
WITH ranked_products AS (
    SELECT 
        category,
        sub_category,
        product_name,
        ROUND(SUM(sales), 2) AS total_sales,
        ROUND(SUM(profit), 2) AS total_profit,
        DENSE_RANK() OVER (
            PARTITION BY category 
            ORDER BY SUM(sales) DESC
        ) AS sales_rank_in_category
    FROM orders
    GROUP BY category, sub_category, product_name
)
SELECT 
    category,
    sales_rank_in_category,
    sub_category,
    product_name,
    total_sales,
    total_profit
FROM ranked_products
WHERE sales_rank_in_category <= 3
ORDER BY category, sales_rank_in_category;

-- 9.2 Running Cumulative Total of Sales by Month
WITH monthly_summary AS (
    SELECT 
        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,
        DATE_FORMAT(order_date, '%Y-%m') AS period,
        ROUND(SUM(sales), 2) AS monthly_sales
    FROM orders
    GROUP BY YEAR(order_date), MONTH(order_date), DATE_FORMAT(order_date, '%Y-%m')
)
SELECT 
    period,
    monthly_sales,
    ROUND(
        SUM(monthly_sales) OVER (
            PARTITION BY order_year 
            ORDER BY order_month
        ), 2
    ) AS ytd_cumulative_sales
FROM monthly_summary
ORDER BY period;

-- 9.3 Pareto 80/20 Analysis: What percentage of product revenue is generated by top SKUs?
WITH product_sales AS (
    SELECT 
        product_id,
        product_name,
        category,
        ROUND(SUM(sales), 2) AS sku_sales
    FROM orders
    GROUP BY product_id, product_name, category
),
pareto_calc AS (
    SELECT 
        product_id,
        product_name,
        category,
        sku_sales,
        ROUND(
            SUM(sku_sales) OVER (ORDER BY sku_sales DESC) / 
            SUM(sku_sales) OVER () * 100, 2
        ) AS cumulative_sales_pct
    FROM product_sales
)
SELECT 
    product_id,
    product_name,
    category,
    sku_sales,
    cumulative_sales_pct,
    CASE 
        WHEN cumulative_sales_pct <= 80.00 THEN 'Top 80% Revenue Driver'
        ELSE 'Long Tail SKU'
    END AS pareto_classification
FROM pareto_calc
LIMIT 25;

-- 9.4 Return Impact by Product Category
SELECT 
    o.category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT r.order_id) AS returned_orders,
    ROUND((COUNT(DISTINCT r.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) AS category_return_rate_pct,
    ROUND(SUM(CASE WHEN r.order_id IS NOT NULL THEN o.sales ELSE 0 END), 2) AS revenue_lost_to_returns
FROM orders o
LEFT JOIN returns r ON o.order_id = r.order_id
GROUP BY o.category
ORDER BY category_return_rate_pct DESC;

-- ================================================================================
-- END OF SCRIPT
-- ================================================================================
