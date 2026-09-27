# 🎨 Executive Dark Theme Design Guide: Power BI Dashboard

This guide documents the **Executive Dark Pro** design system applied to [`power_bi/Sales_Profitability_DB.pbix`](file:///a:/ANU%20PROJECTS/PROJECTS/Store%20Sales%20&%20Profitability%20Data%20Analysis%20%20MySQL,%20Power%20BI,%20Excel,%20DAX/power_bi/Sales_Profitability_DB.pbix) and the companion theme file [`power_bi/Executive_Dark_Theme.json`](file:///a:/ANU%20PROJECTS/PROJECTS/Store%20Sales%20&%20Profitability%20Data%20Analysis%20%20MySQL,%20Power%20BI,%20Excel,%20DAX/power_bi/Executive_Dark_Theme.json).

---

## 1. Executive Dark Theme Palette

| Design Token | Hex Code | Visual Application |
| :--- | :--- | :--- |
| **Canvas Canvas Backdrop** | `#0B1120` | Root background for all report pages (`outspace` & `background`) |
| **Card / Visual Container** | `#1E293B` | Elevated card backgrounds with high contrast |
| **Card Borders** | `#334155` | 1px clean structural perimeter with 8px rounded corners |
| **Primary Accent / Cyan** | `#00D2FF` | Total Revenue KPI callout, active slicers, table headers |
| **Profit Emerald Green** | `#10B981` | Net Profit, positive variances, top performing sub-categories |
| **Alert Crimson Red** | `#EF4444` | Negative margins, profit leaks (Tables & Bookcases), deficit states |
| **Warning Amber / Gold** | `#F59E0B` | Break-even thresholds, Q4 holiday peak indicators |
| **Electric Indigo / Purple**| `#818CF8` | Customer volume, distinct orders, secondary distributions |
| **Primary Typography** | `#F8FAFC` | Main headings, bold KPI callouts, high-emphasis text |
| **Secondary Typography** | `#CBD5E1` | Subtitles, matrix headers, chart titles |
| **Muted Axis / Labels** | `#94A3B8` | X/Y Axis category ticks, gridline legends |

---

## 2. Report Pages & Architecture

The report contains 3 core analytical report pages:

```
┌────────────────────────────────────────────────────────────────────────┐
│  SALES ANALYSIS REPORT - EXECUTIVE DARK PRO                            │
├────────────────────┬─────────────────────────────┬─────────────────────┤
│ 1. Sales           │ 2. Discounts & Profits      │ 3. Ranking          │
│ - Revenue KPIs     │ - Discount Elasticity Tiers │ - Top Customers     │
│ - Monthly Trend    │ - Profit Leaks by Sub-Cat   │ - Top Products      │
│ - Regional Split   │ - Loss States (TX, IL)      │ - Segment Share     │
└────────────────────┴─────────────────────────────┴─────────────────────┘
```

### Page 1: Sales Analysis
- **Header:** White bold title `SALES ANALYSIS REPORT` on dark slate background.
- **Top Metric Cards:** Total Sales, Quantity, Profit, and Orders formatted in glowing cyan (`#00D2FF`) and emerald (`#10B981`).
- **Trend Charts:** Monthly area chart and ribbon chart illustrating revenue progression and seasonal acceleration.
- **Slicers:** Dropdown / tile slicers for Region and Year with dark backgrounds (`#1E293B`) and white active states.

### Page 2: Discounts & Profits (Profit Leak Deep Dive)
- **Sub-Category Profitability:** Horizontal bar chart highlighting positive items in emerald and loss-makers (Tables: -$17.7K, Bookcases: -$3.5K) in crimson red.
- **State-Level Deficits:** Regional decomposition demonstrating the Central region loss caused by Texas (-$25.7K) and Illinois (-$12.6K).
- **Discount Tiers:** Visual proof of margin degradation beyond the 20% discount threshold.

### Page 3: Product & Customer Rankings
- **Top Products:** Clustered bar chart of top revenue-generating SKUs (Copiers, Machines, Phones).
- **Segment Split:** Donut chart of Consumer (50.5%), Corporate (30.7%), and Home Office (18.7%).
- **Customer Lifetime Value:** High-value accounts driving repeat sales.

---

## 3. How to Apply or Re-Apply the Dark Theme in Power BI Desktop

If you ever wish to apply this dark theme to another report or re-apply it:
1. Open your report in **Power BI Desktop**.
2. Go to the top ribbon and select the **View** tab.
3. In the **Themes** gallery, click the dropdown arrow and select **Browse for themes...**.
4. Browse to:
   ```
   power_bi/Executive_Dark_Theme.json
   ```
5. Click **Open**. Power BI Desktop will instantly restyle all visuals, page canvases, tables, cards, and charts into this dark theme.
