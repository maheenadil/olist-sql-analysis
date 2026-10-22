-- Olist e-commerce SQL analysis (PostgreSQL)
-- Tables: customers, orders, order_items, products, sellers, payments, reviews, category_translation


-- Query 1: Revenue by product category
-- Business question: Which product categories generate the most revenue?

SELECT
    t.category_english AS category,
    ROUND(SUM(i.price)::numeric, 2) AS revenue
FROM order_items AS i
JOIN products AS p
    ON i.product_id = p.product_id
JOIN category_translation AS t
    ON p.category = t.category
GROUP BY t.category_english
ORDER BY revenue DESC
LIMIT 10;


-- Query 2: Order volume by customer state
-- Business question: Which customer states place the most orders?

SELECT
    c.state AS customer_state,
    COUNT(o.order_id) AS order_count
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
GROUP BY c.state
ORDER BY order_count DESC
LIMIT 10;


-- Query 3: Late delivery rate (delivered orders only)
-- Business question: What share of delivered orders arrived after the estimated date?

SELECT
    COUNT(*) AS delivered_orders,
    SUM(CASE WHEN delivered_to_customer_at > estimated_delivery_at THEN 1 ELSE 0 END) AS late_orders,
    ROUND(
        100.0 * SUM(CASE WHEN delivered_to_customer_at > estimated_delivery_at THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS late_rate_pct
FROM orders
WHERE order_status = 'delivered'
  AND delivered_to_customer_at IS NOT NULL
  AND estimated_delivery_at IS NOT NULL;


-- Query 4: Review scores for late vs on-time deliveries
-- Business question: Do late deliveries lead to lower review scores?

SELECT
    CASE
        WHEN o.delivered_to_customer_at > o.estimated_delivery_at THEN 'Late'
        ELSE 'On time'
    END AS delivery_status,
    COUNT(*) AS reviewed_orders,
    ROUND(AVG(r.review_score)::numeric, 2) AS avg_review_score
FROM orders AS o
JOIN reviews AS r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.delivered_to_customer_at IS NOT NULL
  AND o.estimated_delivery_at IS NOT NULL
GROUP BY delivery_status;


-- Query 5: Repeat customer rate
-- Business question: What share of customers place more than one order?

WITH orders_per_customer AS (
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS order_count
    FROM orders AS o
    JOIN customers AS c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(
        100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS repeat_rate_pct
FROM orders_per_customer;
