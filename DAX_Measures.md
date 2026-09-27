# 📐 Power BI DAX Measures & Modeling Catalog

This document details the Data Analysis Expressions (DAX) used to power the **Store Sales & Profitability Power BI Dashboard**. It explains the rationale, business logic, syntax, and model relationships.

---

## 1. Relational Data Model Architecture

The data model follows an optimized **Star / Snowflake Schema**:

```
           +-----------------------+
           | regional_managers     |
           |-----------------------|
           | Regional_Manager      |
           | Region (PK)           |
           +-----------+-----------+
                       | 1
                       |
                       | *
+-----------------+    +-----------------+    +-----------------+
| DimDate         |    | Orders          |    | Returns         |
|-----------------|    |-----------------|    |-----------------|
| Date (PK)   <---+----+ Order_Date (FK) |    | Returned        |
| Year            | 1  | Order_ID (Deg)  +----+ Order_ID (FK)   |
| Month Number    |  * | Customer_ID     | *  |                 |
| Month Name      |    | Region (FK)     |    +-----------------+
| Quarter         |    | Category        | 1 (inactive/active)
| Is Weekend      |    | Sub_Category    |
+-----------------+    | Sales           |
                       | Profit          |
                       | Discount        |
                       | Quantity        |
                       +-----------------+
```

---

## 2. Calculated Date Table (`DimDate`)

A dedicated calendar dimension is required in Power BI to ensure continuous date intervals for standard time-intelligence functions (`TOTALYTD`, `SAMEPERIODLASTYEAR`).

```dax
DimDate = 
ADDCOLUMNS(
    CALENDAR(MIN(Orders[Order_Date]), MAX(Orders[Order_Date])),
    "Year", YEAR([Date]),
    "Year Month Number", YEAR([Date]) * 100 + MONTH([Date]),
    "Month Number", MONTH([Date]),
    "Month Name", FORMAT([Date], "mmmm"),
    "Month Short", FORMAT([Date], "mmm"),
    "Quarter", "Q" & FORMAT([Date], "q"),
    "Year Quarter", FORMAT([Date], "yyyy") & "-Q" & FORMAT([Date], "q"),
    "Day of Week Number", WEEKDAY([Date], 2),
    "Day of Week", FORMAT([Date], "dddd"),
    "Day of Week Short", FORMAT([Date], "ddd"),
    "Is Weekend", IF(WEEKDAY([Date], 2) IN {6, 7}, "Weekend", "Weekday")
)
```

> [!TIP]
> In Power BI Desktop, mark this table as a **Date Table** (`Table Tools > Mark as Date Table > Select [Date] column`) to enable automatic time-intelligence optimizations.

---

## 3. Executive KPI Measures

### 3.1 Total Revenue
```dax
Total Sales = SUM(Orders[Sales])
```
*Format: Currency (`$#,##0`)*

### 3.2 Total Profit
```dax
Total Profit = SUM(Orders[Profit])
```
*Format: Currency (`$#,##0`)*

### 3.3 Total Cost of Goods Sold (COGS)
```dax
Total Cost = [Total Sales] - [Total Profit]
```
*Format: Currency (`$#,##0`)*

### 3.4 Floating Profit Margin Percentage
```dax
Profit Margin % = DIVIDE([Total Profit], [Total Sales], 0)
```
*Format: Percentage (`0.0%`)*  
*Note: Uses `DIVIDE()` to safely avoid division-by-zero errors when filtered items have zero revenue.*

### 3.5 Average Order Value (AOV)
```dax
Average Order Value = DIVIDE([Total Sales], [Total Orders], 0)
```
*Format: Currency (`$#,##0.00`)*

### 3.6 Average Applied Discount
```dax
Average Discount % = AVERAGE(Orders[Discount])
```
*Format: Percentage (`0.0%`)*

---

## 4. Time Intelligence & Growth Measures

### 4.1 Prior Year Sales (Same Period Last Year)
```dax
Sales SPLY = 
CALCULATE(
    [Total Sales],
    SAMEPERIODLASTYEAR(DimDate[Date])
)
```

### 4.2 Year-over-Year (YoY) Sales Growth Rate
```dax
YoY Sales Growth % = 
DIVIDE([Total Sales] - [Sales SPLY], [Sales SPLY], 0)
```

### 4.3 Year-to-Date (YTD) Sales
```dax
Sales YTD = TOTALYTD([Total Sales], DimDate[Date])
```

### 4.4 Year-to-Date (YTD) Profit
```dax
Profit YTD = TOTALYTD([Total Profit], DimDate[Date])
```

---

## 5. Conditional Formatting & Dynamic KPI Flags

### 5.1 Dynamic Status Color Hex
Use this measure in visual conditional formatting (Format Style: Field Value):
```dax
Profit Status Color = 
IF(
    [Total Profit] < 0,
    "#E53E3E", // High-visibility Alert Red
    IF([Profit Margin %] >= 0.15, "#38A169", "#DD6B20") // Green for healthy, Orange for thin margin
)
```
