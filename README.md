# SQL Sales Analytics Dashboard

> Sales analytics using MySQL, Python & Power BI — window functions, CTEs, KPI dashboards

---

## Overview

A SQL-heavy analytics project built on a 6-table relational sales database. Covers advanced querying, KPI derivation, and interactive Power BI reporting. Designed to demonstrate real-world data analysis skills including schema design, query optimisation, and business intelligence reporting.

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| MySQL | Database & querying |
| Python | Data processing & automation |
| Power BI | Interactive dashboard |
| Excel | Stakeholder reporting |

---

## Features

- 20+ advanced SQL queries using window functions (`ROW_NUMBER`, `RANK`, `LAG/LEAD`), CTEs, and correlated subqueries
- KPIs: month-over-month revenue growth, cohort retention rates, top-product rankings
- Interactive 4-page Power BI dashboard with slicers for region, product category, and date range
- Cleaned datasets exported to Excel with pivot tables and conditional formatting for stakeholder-ready reporting
- Full data dictionary and query logic documented for reproducibility

---

## Database Schema

6 interconnected tables:

```
orders      → order_id, customer_id, product_id, region_id, order_date, quantity, amount
products    → product_id, product_name, category, unit_price
customers   → customer_id, customer_name, segment, join_date
regions     → region_id, region_name, country
returns     → return_id, order_id, return_date, reason
discounts   → discount_id, product_id, discount_pct, valid_from, valid_to
```

---

## Project Structure

```
sql-sales-analytics/
│
├── sql/
│   ├── schema.sql           # Table definitions
│   ├── seed_data.sql        # Sample data
│   └── queries/
│       ├── revenue.sql      # Monthly & MoM revenue
│       ├── retention.sql    # Cohort retention analysis
│       ├── top_products.sql # Regional top-sellers
│       └── kpis.sql         # All KPI queries
│
├── powerbi/
│   └── dashboard.pbix       # Power BI dashboard file
│
├── excel/
│   └── reports/             # Exported stakeholder reports
│
├── python/
│   └── data_export.py       # Python script to export MySQL → Excel/CSV
│
└── README.md
```

---

## How to Run

### 1. Set up the Database
```sql
-- In MySQL Workbench or terminal
source sql/schema.sql;
source sql/seed_data.sql;
```

### 2. Run the Queries
Open any file from `sql/queries/` in MySQL Workbench and execute.

### 3. Open the Dashboard
Open `powerbi/dashboard.pbix` in Power BI Desktop and refresh the data source connection to point to your local MySQL instance.

### 4. Export Reports (optional)
```bash
python python/data_export.py
```

---

## Key Queries

### Month-over-Month Revenue Growth
```sql
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    SUM(amount) AS revenue,
    LAG(SUM(amount)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m')) AS prev_revenue,
    ROUND(
        (SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m')))
        / LAG(SUM(amount)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m')) * 100, 2
    ) AS mom_growth_pct
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m');
```

### Customer Retention Cohort
```sql
WITH first_order AS (
    SELECT customer_id, MIN(DATE_FORMAT(order_date, '%Y-%m')) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
activity AS (
    SELECT o.customer_id, f.cohort_month, DATE_FORMAT(o.order_date, '%Y-%m') AS order_month
    FROM orders o
    JOIN first_order f ON o.customer_id = f.customer_id
)
SELECT cohort_month, order_month, COUNT(DISTINCT customer_id) AS retained_customers
FROM activity
GROUP BY cohort_month, order_month
ORDER BY cohort_month, order_month;
```

### Regional Top-Sellers
```sql
SELECT region_name, product_name, total_sales,
    RANK() OVER (PARTITION BY region_name ORDER BY total_sales DESC) AS sales_rank
FROM (
    SELECT r.region_name, p.product_name, SUM(o.amount) AS total_sales
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    JOIN regions r ON o.region_id = r.region_id
    GROUP BY r.region_name, p.product_name
) ranked
WHERE sales_rank <= 5;
```

---

## Power BI Dashboard Pages

| Page | Contents |
|------|----------|
| Overview | Total revenue, orders, customers — summary KPIs |
| Revenue Trends | MoM growth chart, year comparison |
| Product Analysis | Top products by category and region |
| Customer Retention | Cohort retention heatmap, segment breakdown |

---

## Author

**Harshitha S** — Python Developer & SQL Analyst  
[LinkedIn](https://linkedin.com/in/harshitha-swamy) · [GitHub](https://github.com/harshitha-swamy)
