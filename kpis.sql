-- ============================================================
-- SQL Sales Analytics Dashboard — KPI Summary Queries
-- Author: Harshitha S
-- ============================================================

USE sales_analytics;

-- ─── 1. Overall Business KPIs ────────────────────────────────
SELECT
    COUNT(DISTINCT order_id)    AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(SUM(amount), 2)       AS total_revenue,
    ROUND(AVG(amount), 2)       AS avg_order_value,
    SUM(quantity)               AS total_units_sold
FROM orders;


-- ─── 2. Return Rate KPI ───────────────────────────────────────
SELECT
    COUNT(DISTINCT o.order_id)  AS total_orders,
    COUNT(r.return_id)          AS total_returns,
    ROUND(COUNT(r.return_id) / COUNT(DISTINCT o.order_id) * 100, 2) AS overall_return_rate_pct
FROM orders o
LEFT JOIN returns r ON o.order_id = r.order_id;


-- ─── 3. Average Revenue Per Customer ─────────────────────────
SELECT
    ROUND(SUM(amount) / COUNT(DISTINCT customer_id), 2) AS avg_revenue_per_customer
FROM orders;


-- ─── 4. Best Performing Month ────────────────────────────────
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    ROUND(SUM(amount), 2)            AS revenue
FROM orders
GROUP BY month
ORDER BY revenue DESC
LIMIT 1;


-- ─── 5. Revenue Percentile by Customer ───────────────────────
SELECT
    c.customer_name,
    ROUND(SUM(o.amount), 2) AS total_spent,
    ROUND(
        PERCENT_RANK() OVER (ORDER BY SUM(o.amount)) * 100, 2
    )                       AS percentile_rank
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.customer_name
ORDER BY total_spent DESC;


-- ─── 6. Returns by Reason ─────────────────────────────────────
SELECT
    reason,
    COUNT(*) AS return_count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM returns) * 100, 2) AS pct_of_returns
FROM returns
GROUP BY reason
ORDER BY return_count DESC;


-- ─── 7. Revenue Contribution — Top 20% Products (Pareto) ─────
WITH product_revenue AS (
    SELECT
        p.product_name,
        ROUND(SUM(o.amount), 2) AS revenue
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY p.product_id, p.product_name
),
ranked AS (
    SELECT *,
        ROUND(SUM(revenue) OVER (ORDER BY revenue DESC) /
              SUM(revenue) OVER () * 100, 2) AS cumulative_pct
    FROM product_revenue
)
SELECT product_name, revenue, cumulative_pct
FROM ranked
WHERE cumulative_pct <= 80
ORDER BY revenue DESC;


-- ─── 8. High-Value Orders (Above Average) ────────────────────
SELECT
    o.order_id,
    c.customer_name,
    p.product_name,
    r.region_name,
    o.order_date,
    o.amount,
    ROUND(o.amount - AVG(o.amount) OVER (), 2) AS above_avg_by
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products  p ON o.product_id  = p.product_id
JOIN regions   r ON o.region_id   = r.region_id
WHERE o.amount > (SELECT AVG(amount) FROM orders)
ORDER BY o.amount DESC;


-- ─── 9. Week-over-Week Order Volume ──────────────────────────
SELECT
    YEARWEEK(order_date, 1)                                           AS year_week,
    COUNT(order_id)                                                   AS orders_this_week,
    LAG(COUNT(order_id)) OVER (ORDER BY YEARWEEK(order_date, 1))     AS orders_prev_week,
    COUNT(order_id) - LAG(COUNT(order_id)) OVER (ORDER BY YEARWEEK(order_date, 1)) AS wow_change
FROM orders
GROUP BY YEARWEEK(order_date, 1)
ORDER BY year_week;


-- ─── 10. Segment Revenue with Row Number ─────────────────────
SELECT
    c.segment,
    c.customer_name,
    ROUND(SUM(o.amount), 2) AS total_spent,
    ROW_NUMBER() OVER (PARTITION BY c.segment ORDER BY SUM(o.amount) DESC) AS rank_in_segment
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.segment, c.customer_id, c.customer_name
ORDER BY c.segment, rank_in_segment;
