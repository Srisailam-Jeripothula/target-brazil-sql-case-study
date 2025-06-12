-- Business Case Study: Target Brazil Operations
-- Author: Srisailam Jeripothula
-- Date: 03/12/2024
-- Scaler DSML Program | SQL Analysis

-- 1. Dataset Exploration

-- 1.1 Data types in the "customers" table
-- (Manual observation: All strings except customer_zip_code_prefix = INT)

-- 1.2 Order time range
SELECT
  MIN(order_purchase_timestamp) AS first_order,
  MAX(order_purchase_timestamp) AS last_order
FROM `ace-charter-438705-d0.target.orders`;

-- 1.3 Unique cities and states
SELECT
  COUNT(DISTINCT customer_city) AS no_of_cities,
  COUNT(DISTINCT customer_state) AS no_of_states
FROM `ace-charter-438705-d0.target.orders` AS o
JOIN `ace-charter-438705-d0.target.customers` AS c
ON o.customer_id = c.customer_id;

-- 2. In-depth Exploration

-- 2.1 Monthly trend of orders
SELECT
  EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
  EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
  COUNT(*) AS no_of_orders
FROM `ace-charter-438705-d0.target.orders`
GROUP BY year, month
ORDER BY year, month;

-- 2.2 Seasonality: Orders by Month
SELECT
  EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
  COUNT(*) AS no_of_orders
FROM `ace-charter-438705-d0.target.orders`
GROUP BY month
ORDER BY no_of_orders DESC;

-- 2.3 Orders by Time of Day
SELECT
  CASE
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 0 AND 6 THEN "Dawn"
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 7 AND 12 THEN "Morning"
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 13 AND 18 THEN "Afternoon"
    ELSE "Night"
  END AS time_of_the_day,
  COUNT(*) AS no_of_orders
FROM `ace-charter-438705-d0.target.orders`
GROUP BY time_of_the_day
ORDER BY no_of_orders DESC;

-- 3. Regional Performance

-- 3.1 Orders per state (month-wise)
SELECT
  EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
  EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
  customer_state,
  COUNT(*) AS no_of_orders
FROM `ace-charter-438705-d0.target.orders` AS o
JOIN `ace-charter-438705-d0.target.customers` AS c
ON o.customer_id = c.customer_id
GROUP BY year, month, customer_state
ORDER BY no_of_orders DESC;

-- States with <500 orders/month
SELECT
  year, month, COUNT(DISTINCT customer_state)
FROM (
  SELECT
    EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
    EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
    customer_state,
    COUNT(*) AS no_of_orders
  FROM `ace-charter-438705-d0.target.orders` AS o
  JOIN `ace-charter-438705-d0.target.customers` AS c
  ON o.customer_id = c.customer_id
  GROUP BY year, month, customer_state
  HAVING COUNT(*) < 500
) t
GROUP BY year, month;

-- 3.2 Customers per state
SELECT
  customer_state,
  COUNT(DISTINCT customer_unique_id) AS no_of_customers
FROM `ace-charter-438705-d0.target.customers`
GROUP BY customer_state
ORDER BY no_of_customers DESC;

-- 4. Economy & Revenue Insights

-- 4.1 % Increase in order cost (Jan–Aug 2017 vs 2018)
SELECT
  ((lags - sum_of_sales) / sum_of_sales) * 100 AS perincrease
FROM (
  SELECT
    sum_of_sales,
    LAG(sum_of_sales) OVER (ORDER BY sum_of_sales DESC) AS lags
  FROM (
    SELECT DISTINCT
      EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
      SUM(payment_value) OVER (PARTITION BY EXTRACT(YEAR FROM order_purchase_timestamp)) AS sum_of_sales
    FROM `ace-charter-438705-d0.target.payments` AS p
    JOIN `ace-charter-438705-d0.target.orders` AS o
    ON p.order_id = o.order_id
    WHERE EXTRACT(YEAR FROM order_purchase_timestamp) IN (2017, 2018)
      AND EXTRACT(MONTH FROM order_purchase_timestamp) BETWEEN 1 AND 8
  ) t
) s;

-- 4.2 Total & Avg order price per state
SELECT DISTINCT
  customer_state,
  AVG(payment_value) OVER (PARTITION BY customer_state) AS avg_value,
  SUM(payment_value) OVER (PARTITION BY customer_state) AS sum_of_sales
FROM `ace-charter-438705-d0.target.orders` AS o
JOIN `ace-charter-438705-d0.target.customers` AS c
ON o.customer_id = c.customer_id
JOIN `ace-charter-438705-d0.target.payments` AS p
ON p.order_id = o.order_id
ORDER BY sum_of_sales DESC, avg_value DESC;

-- 4.3 Total & Avg freight per state
SELECT DISTINCT
  customer_state,
  AVG(freight_value) OVER (PARTITION BY customer_state) AS avg_freight_value,
  SUM(freight_value) OVER (PARTITION BY customer_state) AS freight_value
FROM `ace-charter-438705-d0.target.orders` AS o
JOIN `ace-charter-438705-d0.target.customers` AS c
ON o.customer_id = c.customer_id
JOIN `ace-charter-438705-d0.target.order_items` AS p
ON p.order_id = o.order_id
ORDER BY avg_freight_value DESC, freight_value DESC;

-- 5. Delivery Performance

-- 5.1 Delivery time and delay
SELECT
  order_id,
  DATETIME_DIFF(order_delivered_customer_date, order_purchase_timestamp, DAY) AS time_to_deliver,
  DATETIME_DIFF(order_estimated_delivery_date, order_delivered_customer_date, DAY) AS diff_estimated_delivery
FROM `ace-charter-438705-d0.target.orders`
ORDER BY diff_estimated_delivery DESC;

-- 5.2 Top 5 states: highest & lowest avg freight
WITH cte1 AS (
  SELECT DISTINCT
    customer_state AS customer_state_h,
    AVG(freight_value) OVER (PARTITION BY customer_state) AS avg_value_h
  FROM `ace-charter-438705-d0.target.orders` AS o
  JOIN `ace-charter-438705-d0.target.customers` AS c
  ON c.customer_id = o.customer_id
  JOIN `ace-charter-438705-d0.target.order_items` AS p
  ON p.order_id = o.order_id
  ORDER BY avg_value_h DESC
  LIMIT 5
),
cte2 AS (
  SELECT DISTINCT
    customer_state AS customer_state_l,
    AVG(freight_value) OVER (PARTITION BY customer_state) AS avg_value_l
  FROM `ace-charter-438705-d0.target.orders` AS o
  JOIN `ace-charter-438705-d0.target.customers` AS c
  ON c.customer_id = o.customer_id
  JOIN `ace-charter-438705-d0.target.order_items` AS p
  ON p.order_id = o.order_id
  ORDER BY avg_value_l
  LIMIT 5
),
cte3 AS (
  SELECT ROW_NUMBER() OVER (ORDER BY avg_value_h DESC) AS rh,
  customer_state_h, avg_value_h FROM cte1
),
cte4 AS (
  SELECT ROW_NUMBER() OVER (ORDER BY avg_value_l) AS rl,
  customer_state_l, avg_value_l FROM cte2
)
SELECT customer_state_h, avg_value_h, customer_state_l, avg_value_l
FROM cte3 AS c3
JOIN cte4 AS c4 ON rh = rl;

-- 5.3 Top 5 states: highest & lowest avg delivery time
WITH cte1 AS (
  SELECT customer_state AS customer_state_h,
    ROUND(AVG(DATETIME_DIFF(order_delivered_customer_date, order_purchase_timestamp, DAY))) AS avg_time_to_deliver_h
  FROM `ace-charter-438705-d0.target.orders` AS o
  JOIN `ace-charter-438705-d0.target.customers` AS c ON c.customer_id = o.customer_id
  GROUP BY customer_state
  ORDER BY avg_time_to_deliver_h DESC
  LIMIT 5
),
cte2 AS (
  SELECT customer_state AS customer_state_l,
    ROUND(AVG(DATETIME_DIFF(order_delivered_customer_date, order_purchase_timestamp, DAY))) AS avg_time_to_deliver_l
  FROM `ace-charter-438705-d0.target.orders` AS o
  JOIN `ace-charter-438705-d0.target.customers` AS c ON c.customer_id = o.customer_id
  GROUP BY customer_state
  ORDER BY avg_time_to_deliver_l
  LIMIT 5
),
cte3 AS (
  SELECT ROW_NUMBER() OVER (ORDER BY avg_time_to_deliver_h DESC) AS rh,
    customer_state_h, avg_time_to_deliver_h FROM cte1
),
cte4 AS (
  SELECT ROW_NUMBER() OVER (ORDER BY avg_time_to_deliver_l) AS rl,
    customer_state_l, avg_time_to_deliver_l FROM cte2
)
SELECT customer_state_h, avg_time_to_deliver_h, customer_state_l, avg_time_to_deliver_l
FROM cte3 AS c3
JOIN cte4 AS c4 ON rh = rl;

-- 5.4 Top 5 fastest delivery states (vs. estimated)
SELECT customer_state,
  ROUND(t.avg_time_to_deliver - t.avg_diff_estimated_delivery) AS diff
FROM (
  SELECT customer_state,
    AVG(DATETIME_DIFF(order_delivered_customer_date, order_purchase_timestamp, DAY)) AS avg_time_to_deliver,
    AVG(DATETIME_DIFF(order_estimated_delivery_date, order_delivered_customer_date, DAY)) AS avg_diff_estimated_delivery
  FROM `ace-charter-438705-d0.target.orders` AS o
  JOIN `ace-charter-438705-d0.target.customers` AS c ON c.customer_id = o.customer_id
  GROUP BY customer_state
) t
ORDER BY diff DESC
LIMIT 5;

-- 6. Payment Behavior

-- 6.1 Monthly orders by payment type
SELECT
  EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
  EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
  COUNT(*) AS no_of_orders
FROM `ace-charter-438705-d0.target.payments` AS p
JOIN `ace-charter-438705-d0.target.orders` AS o ON p.order_id = o.order_id
GROUP BY year, month
ORDER BY no_of_orders DESC;

-- 6.2 Orders with at least one installment paid
SELECT COUNT(payment_value) AS at_least_1_paid
FROM `ace-charter-438705-d0.target.payments`
WHERE payment_value != 0 AND payment_installments != 0;


