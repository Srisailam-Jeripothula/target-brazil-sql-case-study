-- 📊 Target Brazil Operations - SQL Case Study
-- Author: Srisailam Jeripothula
-- Dataset Period: 2016–2018
-- Objective: Analyze orders, payments, freight, and delivery performance across Brazilian states

-- -------------------------------
-- 1. Basic EDA & Structure Checks
-- -------------------------------

-- 1.1 Data types in the customers table
SELECT
  column_name,
  data_type
FROM
  `ace-charter-438705-d0.target.INFORMATION_SCHEMA.COLUMNS`
WHERE
  table_name = 'customers';

-- 1.2 Order date range
SELECT
  MIN(order_purchase_timestamp) AS first_order,
  MAX(order_purchase_timestamp) AS last_order
FROM
  `ace-charter-438705-d0.target.orders`;

-- 1.3 Count of unique cities and states
SELECT
  COUNT(DISTINCT customer_city) AS num_cities,
  COUNT(DISTINCT customer_state) AS num_states
FROM
  `ace-charter-438705-d0.target.orders` AS o
JOIN
  `ace-charter-438705-d0.target.customers` AS c
ON
  o.customer_id = c.customer_id;

-- ---------------------------------
-- 2. Order Trends & Seasonality
-- ---------------------------------

-- 2.1 Monthly trend in orders
SELECT
  EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
  EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
  COUNT(*) AS num_orders
FROM
  `ace-charter-438705-d0.target.orders`
GROUP BY year, month
ORDER BY year, month;

-- 2.2 Monthly seasonality
SELECT
  EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
  COUNT(*) AS num_orders
FROM
  `ace-charter-438705-d0.target.orders`
GROUP BY month
ORDER BY num_orders DESC;

-- 2.3 Orders by time of day
SELECT
  CASE
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 0 AND 6 THEN 'Dawn'
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 7 AND 12 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 13 AND 18 THEN 'Afternoon'
    ELSE 'Night'
  END AS time_of_day,
  COUNT(*) AS num_orders
FROM
  `ace-charter-438705-d0.target.orders`
GROUP BY time_of_day
ORDER BY num_orders DESC;

-- ---------------------------------
-- 3. Regional Order Distribution
-- ---------------------------------

-- 3.1 Monthly orders per state
SELECT
  EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
  EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
  customer_state,
  COUNT(*) AS num_orders
FROM
  `ace-charter-438705-d0.target.orders` AS o
JOIN
  `ace-charter-438705-d0.target.customers` AS c
ON
  o.customer_id = c.customer_id
GROUP BY year, month, customer_state
ORDER BY num_orders DESC;

-- 3.2 Number of customers per state
SELECT
  customer_state,
  COUNT(DISTINCT customer_unique_id) AS num_customers
FROM
  `ace-charter-438705-d0.target.customers`
GROUP BY customer_state
ORDER BY num_customers DESC;

-- -------------------------------
-- 4. Economic Impact & Payments
-- -------------------------------

-- 4.1 % increase in payment_value from Jan–Aug 2017 to Jan–Aug 2018
SELECT
  (
    (lag_sales - sum_of_sales) / sum_of_sales
  ) * 100 AS percent_increase
FROM (
  SELECT
    SUM(payment_value) OVER (PARTITION BY EXTRACT(YEAR FROM order_purchase_timestamp)) AS sum_of_sales,
    LAG(SUM(payment_value) OVER (PARTITION BY EXTRACT(YEAR FROM order_purchase_timestamp)))
      OVER (ORDER BY EXTRACT(YEAR FROM order_purchase_timestamp)) AS lag_sales
  FROM
    `ace-charter-438705-d0.target.payments` AS p
  JOIN
    `ace-charter-438705-d0.target.orders` AS o
  ON
    p.order_id = o.order_id
  WHERE
    EXTRACT(MONTH FROM order_purchase_timestamp) BETWEEN 1 AND 8
    AND EXTRACT(YEAR FROM order_purchase_timestamp) IN (2017, 2018)
) AS t;

-- 4.2 Total & Avg payment per state
SELECT
  DISTINCT customer_state,
  AVG(payment_value) OVER (PARTITION BY customer_state) AS avg_payment,
  SUM(payment_value) OVER (PARTITION BY customer_state) AS total_payment
FROM
  `ace-charter-438705-d0.target.orders` AS o
JOIN
  `ace-charter-438705-d0.target.customers` AS c ON o.customer_id = c.customer_id
JOIN
  `ace-charter-438705-d0.target.payments` AS p ON o.order_id = p.order_id
ORDER BY total_payment DESC;

-- 4.3 Total & Avg freight per state
SELECT
  DISTINCT customer_state,
  AVG(freight_value) OVER (PARTITION BY customer_state) AS avg_freight,
  SUM(freight_value) OVER (PARTITION BY customer_state) AS total_freight
FROM
  `ace-charter-438705-d0.target.orders` AS o
JOIN
  `ace-charter-438705-d0.target.customers` AS c ON o.customer_id = c.customer_id
JOIN
  `ace-charter-438705-d0.target.order_items` AS oi ON o.order_id = oi.order_id
ORDER BY avg_freight DESC;

-- -------------------------------
-- 5. Delivery Performance
-- -------------------------------

-- 5.1 Delivery time and delay vs. estimated delivery
SELECT
  order_id,
  DATETIME_DIFF(order_delivered_customer_date, order_purchase_timestamp, DAY) AS time_to_deliver,
  DATETIME_DIFF(order_estimated_delivery_date, order_delivered_customer_date, DAY) AS delay_vs_estimate
FROM
  `ace-charter-438705-d0.target.orders`
ORDER BY delay_vs_estimate DESC;

-- 5.2 Top 5 states by highest and lowest avg freight
-- (CTEs can be applied here in advanced use)

-- 5.3 Top 5 states by fastest delivery vs. estimated date
SELECT
  customer_state,
  ROUND(AVG(DATETIME_DIFF(order_delivered_customer_date, order_purchase_timestamp, DAY))) AS avg_delivery_time,
  ROUND(AVG(DATETIME_DIFF(order_estimated_delivery_date, order_delivered_customer_date, DAY))) AS avg_diff_estimated,
  ROUND(AVG(DATETIME_DIFF(order_delivered_customer_date, order_purchase_timestamp, DAY)) -
         AVG(DATETIME_DIFF(order_estimated_delivery_date, order_delivered_customer_date, DAY))) AS performance_score
FROM
  `ace-charter-438705-d0.target.orders` AS o
JOIN
  `ace-charter-438705-d0.target.customers` AS c ON o.customer_id = c.customer_id
GROUP BY customer_state
ORDER BY performance_score DESC
LIMIT 5;

-- -------------------------------
-- 6. Payment Types & Installments
-- -------------------------------

-- 6.1 Orders by payment type (monthly trend)
SELECT
  EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
  EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
  COUNT(*) AS num_orders
FROM
  `ace-charter-438705-d0.target.payments` AS p
JOIN
  `ace-charter-438705-d0.target.orders` AS o ON p.order_id = o.order_id
GROUP BY year, month
ORDER BY year, month;

-- 6.2 Orders with at least one paid installment
SELECT
  COUNT(*) AS num_paid_orders
FROM
  `ace-charter-438705-d0.target.payments`
WHERE
  payment_value != 0 AND payment_installments != 0;


