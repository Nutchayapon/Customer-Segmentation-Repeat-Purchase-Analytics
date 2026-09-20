-- Preserve prior history before applying presentation filters.
BEGIN;
CREATE OR REPLACE VIEW analytics.customer_order_history AS
SELECT o.*, row_number() OVER customer_history AS purchase_number,
 lag(order_purchase_timestamp) OVER customer_history AS previous_purchase_timestamp,
 lag(order_id) OVER customer_history AS previous_order_id,
 first_value(customer_state) OVER customer_history AS first_purchase_state
FROM analytics.orders o
WINDOW customer_history AS (PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp, order_id);
CREATE OR REPLACE VIEW analytics.customer_metrics AS
WITH grouped AS (
 SELECT customer_unique_id, min(order_purchase_timestamp) AS first_purchase_timestamp,
 max(order_purchase_timestamp) AS last_purchase_timestamp,
 min(order_purchase_timestamp) FILTER (WHERE purchase_number = 2) AS second_purchase_timestamp,
 count(*) AS order_count, sum(merchandise_value) AS monetary_value, sum(item_count) AS item_count,
 min(first_purchase_state) AS first_purchase_state,
 count(*) FILTER (WHERE missing_payment) AS missing_payment_orders,
 count(*) FILTER (WHERE payment_mismatch) AS payment_mismatch_orders,
 min(observation_start) AS observation_start, min(observation_end) AS observation_end
 FROM analytics.customer_order_history GROUP BY customer_unique_id
)
SELECT *, first_purchase_timestamp::date AS first_purchase_date,
 last_purchase_timestamp::date AS last_purchase_date,
 date_trunc('month', first_purchase_timestamp)::date AS cohort_month,
 first_purchase_timestamp >= TIMESTAMP '2017-01-01' AS primary_cohort,
 observation_end + 1 AS reference_date,
 observation_end + 1 - last_purchase_timestamp::date AS recency_days,
 observation_end - first_purchase_timestamp::date AS observed_followup_days,
 last_purchase_timestamp::date - first_purchase_timestamp::date AS purchase_span_days,
 monetary_value / nullif(order_count, 0) AS average_order_value,
 order_count >= 2 AS is_repeat_customer FROM grouped;
COMMIT;
