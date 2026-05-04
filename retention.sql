-- ============================================================
-- SQL Sales Analytics Dashboard — Customer Retention Queries
-- Author: Harshitha S
-- ============================================================

USE sales_analytics;

-- ─── 1. Customer Cohort Retention ─────────────────────────────
WITH first_order AS (
    SELECT
        customer_id,
        MIN(DATE_FORMAT(order_date, '%Y-%m')) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
activity AS (
    SELECT
        o.customer_id,
        f.cohort_month,
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month
    FROM orders o
    JOIN first_order f ON o.customer_id = f.customer_id
)
SELECT
    cohort_month,
    order_month,
    COUNT(DISTINCT customer_id) AS retained_customers
FROM activity
GROUP BY cohort_month, order_month
ORDER BY cohort_month, order_month;


-- ─── 2. Repeat vs One-Time Customers ─────────────────────────
SELECT
    CASE WHEN order_count = 1 THEN 'One-Time' ELSE 'Repeat' END AS customer_type,
    COUNT(*)                                                      AS customer_count,
    ROUND(COUNT(*) / (SELECT COUNT(DISTINCT customer_id) FROM orders) * 100, 2) AS pct
FROM (
    SELECT customer_id, COUNT(order_id) AS order_count
    FROM orders
    GROUP BY customer_id
) t
GROUP BY customer_type;


-- ─── 3. Top 10 Customers by Revenue ──────────────────────────
SELECT
    c.customer_name,
    c.segment,
    COUNT(o.order_id)       AS total_orders,
    ROUND(SUM(o.amount), 2) AS total_spent,
    ROUND(AVG(o.amount), 2) AS avg_order_value,
    RANK() OVER (ORDER BY SUM(o.amount) DESC) AS revenue_rank
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.segment
ORDER BY total_spent DESC
LIMIT 10;


-- ─── 4. Customer Purchase Frequency ──────────────────────────
SELECT
    frequency_bucket,
    COUNT(*) AS customer_count
FROM (
    SELECT
        customer_id,
        COUNT(order_id) AS orders_placed,
        CASE
            WHEN COUNT(order_id) = 1        THEN '1 order'
            WHEN COUNT(order_id) BETWEEN 2 AND 4 THEN '2–4 orders'
            WHEN COUNT(order_id) BETWEEN 5 AND 9 THEN '5–9 orders'
            ELSE '10+ orders'
        END AS frequency_bucket
    FROM orders
    GROUP BY customer_id
) t
GROUP BY frequency_bucket
ORDER BY FIELD(frequency_bucket, '1 order','2–4 orders','5–9 orders','10+ orders');


-- ─── 5. Average Days Between Orders (Repeat Customers) ────────
WITH ordered AS (
    SELECT
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date
    FROM orders
)
SELECT
    customer_id,
    ROUND(AVG(DATEDIFF(order_date, prev_order_date)), 1) AS avg_days_between_orders
FROM ordered
WHERE prev_order_date IS NOT NULL
GROUP BY customer_id
ORDER BY avg_days_between_orders;


-- ─── 6. Monthly New vs Returning Customers ────────────────────
WITH first_order AS (
    SELECT customer_id, MIN(order_date) AS first_date
    FROM orders GROUP BY customer_id
)
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    COUNT(DISTINCT CASE WHEN o.order_date = f.first_date THEN o.customer_id END) AS new_customers,
    COUNT(DISTINCT CASE WHEN o.order_date > f.first_date  THEN o.customer_id END) AS returning_customers
FROM orders o
JOIN first_order f ON o.customer_id = f.customer_id
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY month;
