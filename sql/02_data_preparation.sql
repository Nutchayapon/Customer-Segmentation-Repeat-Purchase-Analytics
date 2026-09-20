-- One row per source order, then one row per eligible delivered order.
-- Retrospective final status; see docs/METHODOLOGY.md for boundary caveats.
BEGIN;
UPDATE analytics.analysis_config
SET observation_start = DATE '2016-09-04', observation_end = DATE '2018-07-31',
    cutoff_rationale = 'Retain all available earlier history. End on July 31, 2018 to exclude August near the extract boundary. Later delivered purchases extend to August 29; this buffer does not prove complete follow-up. Final status is retrospective, not a historical backtest.'
WHERE singleton AND observation_start IS NULL AND observation_end IS NULL;
DO $$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM analytics.analysis_config WHERE observation_end IS NOT NULL) THEN
  RAISE EXCEPTION 'Set one valid observation period before preparation.';
 END IF;
 IF EXISTS (SELECT order_id FROM raw.orders GROUP BY order_id HAVING count(*) > 1)
 OR EXISTS (SELECT customer_id FROM raw.customers GROUP BY customer_id HAVING count(*) > 1)
 OR EXISTS (SELECT order_id, order_item_id FROM raw.order_items GROUP BY 1,2 HAVING count(*) > 1)
 OR EXISTS (SELECT order_id, payment_sequential FROM raw.order_payments GROUP BY 1,2 HAVING count(*) > 1) THEN
  RAISE EXCEPTION 'Resolve duplicate source keys before preparation.';
 END IF;
END;
$$;
CREATE OR REPLACE VIEW analytics.order_quality AS
WITH items AS (
 SELECT order_id, count(*) AS item_count,
        CASE WHEN count(price) = count(*) AND min(price) >= 0 THEN sum(price) END AS merchandise_value,
        CASE WHEN count(freight_value) = count(*) AND min(freight_value) >= 0 THEN sum(freight_value) END AS freight_value
 FROM raw.order_items GROUP BY order_id
), payments AS (
 SELECT order_id, count(*) AS payment_entry_count,
        CASE WHEN count(payment_value) = count(*) AND min(payment_value) >= 0 THEN sum(payment_value) END AS payment_value
 FROM raw.order_payments GROUP BY order_id
), joined AS (
 SELECT o.order_id, o.customer_id, c.customer_unique_id, o.order_status,
        o.order_purchase_timestamp, o.order_purchase_timestamp::date AS purchase_date,
        o.order_delivered_customer_date, o.order_approved_at, c.customer_state,
        coalesce(i.item_count, 0) AS item_count, i.merchandise_value, i.freight_value,
        coalesce(p.payment_entry_count, 0) AS payment_entry_count, p.payment_value,
        p.payment_value - i.merchandise_value - i.freight_value AS payment_difference,
        p.order_id IS NULL AS missing_payment,
        o.order_delivered_customer_date IS NULL AS missing_delivery_date,
        o.order_approved_at IS NULL AS missing_approval_date,
        cfg.observation_start, cfg.observation_end
 FROM raw.orders o LEFT JOIN raw.customers c ON c.customer_id = o.customer_id
 LEFT JOIN items i ON i.order_id = o.order_id LEFT JOIN payments p ON p.order_id = o.order_id
 CROSS JOIN analytics.analysis_config cfg
)
SELECT *, abs(payment_difference) > 0.01 AS payment_mismatch,
 CASE WHEN order_id IS NULL OR btrim(order_id) = '' THEN 'invalid_order_id'
      WHEN customer_unique_id IS NULL OR btrim(customer_unique_id) = '' THEN 'missing_customer'
      WHEN order_purchase_timestamp IS NULL THEN 'missing_purchase_timestamp'
      WHEN order_status IS DISTINCT FROM 'delivered' THEN 'not_delivered'
      WHEN purchase_date < observation_start THEN 'before_observation_start'
      WHEN purchase_date > observation_end THEN 'after_observation_end'
      WHEN item_count = 0 THEN 'missing_items'
      WHEN merchandise_value IS NULL THEN 'invalid_merchandise_value'
      ELSE 'eligible' END AS eligibility_reason
FROM joined;
CREATE OR REPLACE VIEW analytics.orders AS
SELECT order_id, customer_id, customer_unique_id, order_purchase_timestamp, purchase_date,
       customer_state, item_count, merchandise_value, freight_value, payment_entry_count,
       payment_value, payment_difference, missing_payment, missing_delivery_date,
       missing_approval_date, payment_mismatch, observation_start, observation_end
FROM analytics.order_quality WHERE eligibility_reason = 'eligible';
CREATE OR REPLACE VIEW analytics.exclusion_summary AS
SELECT eligibility_reason, count(*) AS order_count FROM analytics.order_quality GROUP BY eligibility_reason;
CREATE OR REPLACE VIEW analytics.cutoff_sensitivity AS
WITH candidates(cutoff) AS (
 VALUES (DATE '2018-06-30'), (DATE '2018-07-31'), (DATE '2018-08-31')
), customers AS (
 SELECT x.cutoff, q.customer_unique_id, count(*) AS order_count, sum(q.merchandise_value) AS merchandise_value
 FROM candidates x JOIN analytics.order_quality q
 ON q.purchase_date BETWEEN q.observation_start AND x.cutoff
 WHERE q.order_status = 'delivered' AND q.customer_unique_id IS NOT NULL
 AND btrim(q.customer_unique_id) <> '' AND q.item_count > 0 AND q.merchandise_value IS NOT NULL
 GROUP BY x.cutoff, q.customer_unique_id
)
SELECT cutoff, count(*) AS customers, sum(order_count) AS orders,
 count(*) FILTER (WHERE order_count >= 2) AS repeat_customers,
 count(*) FILTER (WHERE order_count >= 2)::numeric / nullif(count(*), 0) AS observed_repeat_rate,
 sum(merchandise_value) AS merchandise_value FROM customers GROUP BY cutoff;
COMMIT;
