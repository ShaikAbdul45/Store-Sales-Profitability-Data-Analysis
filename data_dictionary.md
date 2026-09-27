# 📖 Data Dictionary: Store Sales & Profitability Dataset

This data dictionary outlines the schema, data types, business definitions, integrity constraints, and domain values for the tables in this project.

---

## 1. Table: `orders` (Cleaned Transaction Logs)
- **Primary Source File:** `dataset/cleaned_orders.csv`
- **Total Records:** 9,994 transactions
- **Time Coverage:** January 2014 – December 2017
- **Primary Granularity:** One row per product line item within an order

| Column Name | SQL Data Type | Power BI Type | Nullable? | Description & Domain Rules |
| :--- | :--- | :--- | :--- | :--- |
| `Row_ID` | `INT` | Integer | No (PK candidate) | Unique sequential transaction row identifier (1 to 9,994). |
| `Order_ID` | `VARCHAR(25)` | Text | No | Unique business identifier for an order event (e.g., `CA-2016-152156`). Multiple rows can share the same Order ID if multiple items were purchased. |
| `Order_Date` | `DATE` | Date | No | Transaction date when customer placed the order (`YYYY-MM-DD`). |
| `Ship_Date` | `DATE` | Date | No | Fulfillment / shipping date when order was dispatched (`YYYY-MM-DD`). Rule: `Ship_Date >= Order_Date`. |
| `Ship_Mode` | `VARCHAR(25)` | Text | No | Shipping method selected: `Standard Class`, `Second Class`, `First Class`, `Same Day`. |
| `Customer_ID` | `VARCHAR(20)` | Text | No | Unique alphanumeric customer identifier (e.g., `CG-12520`). |
| `Customer_Name` | `VARCHAR(100)` | Text | No | Full legal name of the retail customer. |
| `Segment` | `VARCHAR(25)` | Text | No | Market customer segment: `Consumer`, `Corporate`, `Home Office`. |
| `Country` | `VARCHAR(50)` | Text | No | Operating country: `United States`. |
| `City` | `VARCHAR(50)` | Text | No | Destination delivery city (e.g., `Los Angeles`, `New York City`, `Seattle`). |
| `State` | `VARCHAR(50)` | Text | No | Delivery state / province (e.g., `California`, `Texas`, `New York`, `Illinois`). |
| `Postal_Code` | `VARCHAR(10)` | Text | Yes | 5-digit US Postal ZIP code (formatted as text to preserve leading zeros). |
| `Region` | `VARCHAR(25)` | Text | No | Operating business sales region: `West`, `East`, `Central`, `South`. |
| `Product_ID` | `VARCHAR(25)` | Text | No | Alphanumeric product SKU identifier (e.g., `FUR-BO-10001798`). |
| `Category` | `VARCHAR(30)` | Text | No | High-level product group: `Furniture`, `Office Supplies`, `Technology`. |
| `Sub_Category` | `VARCHAR(30)` | Text | No | Granular product sub-division (17 total, e.g., `Tables`, `Chairs`, `Phones`, `Binders`, `Copiers`). |
| `Product_Name` | `VARCHAR(255)` | Text | No | Full descriptive item title. |
| `Sales` | `DECIMAL(10,4)` | Decimal Number | No | Gross transaction revenue generated after discount applied (\$ USD). |
| `Quantity` | `INT` | Integer | No | Count of product units sold (1 to 14 units per line). |
| `Discount` | `DECIMAL(4,2)` | Decimal / % | No | Promotional discount percentage applied (Range: `0.00` to `0.80`). |
| `Profit` | `DECIMAL(10,4)` | Decimal Number | No | Net profit or loss realized (\$ USD). Can be negative when discounts or logistics exceed margins. |

---

## 2. Table: `returns` (Order Returns Log)
- **Primary Source File:** `dataset/cleaned_returns.csv`
- **Total Records:** 296 distinct returned orders

| Column Name | SQL Data Type | Power BI Type | Nullable? | Description |
| :--- | :--- | :--- | :--- | :--- |
| `Returned` | `VARCHAR(5)` | Text | No | Confirmation flag (`Yes`). |
| `Order_ID` | `VARCHAR(25)` | Text | No | Foreign key linking to `orders.Order_ID`. |

---

## 3. Table: `regional_managers` (Territory Personnel)
- **Primary Source File:** `dataset/cleaned_people.csv`
- **Total Records:** 4 regional assignments

| Column Name | SQL Data Type | Power BI Type | Nullable? | Description |
| :--- | :--- | :--- | :--- | :--- |
| `Regional_Manager` | `VARCHAR(50)` | Text | No | Lead executive accountable for territory operations (`Anna Andreadi`, `Chuck Magee`, `Kelly Williams`, `Cassandra Brandow`). |
| `Region` | `VARCHAR(25)` | Text | No | Sales region assigned (`West`, `East`, `Central`, `South`). |

---

## 4. Key Metric Calculations & Business Definitions

| Metric Name | Formula | Unit / Format | Interpretation |
| :--- | :--- | :--- | :--- |
| **Gross Revenue** | `SUM(Sales)` | Currency (\$) | Total top-line sales realized across all orders. |
| **Net Profit** | `SUM(Profit)` | Currency (\$) | Bottom-line earnings after deducting cost of goods sold and applied discounts. |
| **Profit Margin %** | `(SUM(Profit) / SUM(Sales)) * 100` | Percentage (%) | Efficiency of converting revenue to profit. Normal benchmark: 10%–15%. |
| **Average Order Value (AOV)** | `SUM(Sales) / COUNT(DISTINCT Order_ID)` | Currency (\$) | Average revenue generated per unique purchasing event. |
| **Discount Rate** | `AVG(Discount)` | Percentage (%) | Average price reduction given across transactions. |
| **Return Rate %** | `(COUNT(DISTINCT Returns.Order_ID) / COUNT(DISTINCT Orders.Order_ID)) * 100` | Percentage (%) | Percentage of customer orders that resulted in product return. |
