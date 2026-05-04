-- ============================================================
-- SQL Sales Analytics Dashboard — Product & Regional Queries
-- Author: Harshitha S
-- ============================================================

USE sales_analytics;

-- ─── 1. Top 5 Products by Revenue per Region ──────────────────
SELECT region_name, product_name, category, total_sales, sales_rank
FROM (
    SELECT
        r.region_name,
        p.product_name,
        p.category,
        ROUND(SUM(o.amount), 2)                                          AS total_sales,
        RANK() OVER (PARTITION BY r.region_name ORDER BY SUM(o.amount) DESC) AS sales_rank
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    JOIN regions  r ON o.region_id  = r.region_id
    GROUP BY r.region_name, p.product_id, p.product_name, p.category
) ranked
WHERE sales_rank <= 5
ORDER BY region_name, sales_rank;


-- ─── 2. Overall Top Products by Revenue ──────────────────────
SELECT
    p.product_name,
    p.category,
    COUNT(o.order_id)       AS times_ordered,
    SUM(o.quantity)         AS total_units_sold,
    ROUND(SUM(o.amount), 2) AS total_revenue,
    ROUND(AVG(o.amount), 2) AS avg_order_value,
    DENSE_RANK() OVER (ORDER BY SUM(o.amount) DESC) AS revenue_rank
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC;


-- ─── 3. Revenue by Product Category ──────────────────────────
SELECT
    p.category,
    COUNT(o.order_id)       AS total_orders,
    SUM(o.quantity)         AS units_sold,
    ROUND(SUM(o.amount), 2) AS total_revenue,
    ROUND(AVG(o.amount), 2) AS avg_order_value,
    ROUND(SUM(o.amount) / (SELECT SUM(amount) FROM orders) * 100, 2) AS revenue_share_pct
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;


-- ─── 4. Products with Highest Return Rate ─────────────────────
SELECT
    p.product_name,
    p.category,
    COUNT(o.order_id)  AS total_orders,
    COUNT(r.return_id) AS total_returns,
    ROUND(COUNT(r.return_id) / COUNT(o.order_id) * 100, 2) AS return_rate_pct
FROM orders o
JOIN products p ON o.product_id = p.product_id
LEFT JOIN returns r ON o.order_id = r.order_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY return_rate_pct DESC;


-- ─── 5. Discount Impact on Revenue ───────────────────────────
SELECT
    p.product_name,
    p.category,
    d.discount_pct,
    COUNT(o.order_id)       AS orders_during_discount,
    ROUND(SUM(o.amount), 2) AS revenue_during_discount
FROM orders o
JOIN products p  ON o.product_id  = p.product_id
JOIN discounts d ON o.product_id  = d.product_id
    AND o.order_date BETWEEN d.valid_from AND d.valid_to
GROUP BY p.product_id, p.product_name, p.category, d.discount_pct
ORDER BY revenue_during_discount DESC;


-- ─── 6. Month-over-Month Product Sales Trend ─────────────────
WITH monthly_product AS (
    SELECT
        p.product_name,
        DATE_FORMAT(o.order_date, '%Y-%m')  AS month,
        ROUND(SUM(o.amount), 2)             AS revenue
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY p.product_name, DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
    product_name,
    month,
    revenue,
    LAG(revenue) OVER (PARTITION BY product_name ORDER BY month) AS prev_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (PARTITION BY product_name ORDER BY month))
        / NULLIF(LAG(revenue) OVER (PARTITION BY product_name ORDER BY month), 0) * 100, 2
    ) AS mom_change_pct
FROM monthly_product
ORDER BY product_name, month;
