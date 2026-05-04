-- ============================================================
-- SQL Sales Analytics Dashboard — Revenue Queries
-- Author: Harshitha S
-- ============================================================

USE sales_analytics;

-- ─── 1. Monthly Revenue ───────────────────────────────────────
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    COUNT(order_id)                  AS total_orders,
    SUM(quantity)                    AS units_sold,
    ROUND(SUM(amount), 2)            AS total_revenue
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;


-- ─── 2. Month-over-Month Revenue Growth ───────────────────────
WITH monthly AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        ROUND(SUM(amount), 2)            AS revenue
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month)                         AS prev_month_revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY month), 2)     AS revenue_change,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100, 2
    )                                                          AS mom_growth_pct
FROM monthly
ORDER BY month;


-- ─── 3. Yearly Revenue Summary ────────────────────────────────
SELECT
    YEAR(order_date)      AS year,
    COUNT(order_id)       AS total_orders,
    ROUND(SUM(amount), 2) AS total_revenue,
    ROUND(AVG(amount), 2) AS avg_order_value
FROM orders
GROUP BY YEAR(order_date)
ORDER BY year;


-- ─── 4. Revenue by Quarter ────────────────────────────────────
SELECT
    YEAR(order_date)    AS year,
    QUARTER(order_date) AS quarter,
    ROUND(SUM(amount), 2) AS quarterly_revenue,
    COUNT(order_id)       AS total_orders
FROM orders
GROUP BY YEAR(order_date), QUARTER(order_date)
ORDER BY year, quarter;


-- ─── 5. Running Total Revenue (Cumulative) ────────────────────
WITH monthly AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        ROUND(SUM(amount), 2)            AS revenue
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    month,
    revenue,
    ROUND(SUM(revenue) OVER (ORDER BY month ROWS UNBOUNDED PRECEDING), 2) AS cumulative_revenue
FROM monthly
ORDER BY month;


-- ─── 6. Revenue by Region ────────────────────────────────────
SELECT
    r.region_name,
    COUNT(o.order_id)       AS total_orders,
    ROUND(SUM(o.amount), 2) AS total_revenue,
    ROUND(
        SUM(o.amount) / (SELECT SUM(amount) FROM orders) * 100, 2
    )                       AS revenue_share_pct
FROM orders o
JOIN regions r ON o.region_id = r.region_id
GROUP BY r.region_name
ORDER BY total_revenue DESC;


-- ─── 7. Revenue by Customer Segment ──────────────────────────
SELECT
    c.segment,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    COUNT(o.order_id)             AS total_orders,
    ROUND(SUM(o.amount), 2)       AS total_revenue,
    ROUND(AVG(o.amount), 2)       AS avg_order_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.segment
ORDER BY total_revenue DESC;
