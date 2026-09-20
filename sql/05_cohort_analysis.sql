-- Monthly purchasing activity, not continuous retention.
-- Main cohorts start January 2017; sparse 2016 history still defines first purchase.
BEGIN;
CREATE OR REPLACE VIEW analytics.customer_month_activity AS
SELECT DISTINCT o.customer_unique_id, c.cohort_month,
 date_trunc('month',o.order_purchase_timestamp)::date AS activity_month
FROM analytics.orders o JOIN analytics.customer_metrics c USING (customer_unique_id);
CREATE OR REPLACE VIEW analytics.cohort_activity AS
WITH sizes AS (
 SELECT cohort_month, count(*) AS cohort_size FROM analytics.customer_metrics
 WHERE primary_cohort GROUP BY cohort_month
), active AS (
 SELECT cohort_month, activity_month, count(*) AS active_customers
 FROM analytics.customer_month_activity GROUP BY cohort_month, activity_month
), grid AS (
 SELECT s.*, g.month_index,
 (s.cohort_month + make_interval(months => g.month_index))::date AS activity_month, cfg.observation_end
 FROM sizes s CROSS JOIN analytics.analysis_config cfg
 CROSS JOIN LATERAL generate_series(0,
 (extract(year FROM age(date_trunc('month',cfg.observation_end),TIMESTAMP '2017-01-01'))*12
 + extract(month FROM age(date_trunc('month',cfg.observation_end),TIMESTAMP '2017-01-01')))::integer
 ) g(month_index)
), observed AS (
 SELECT g.*, (g.activity_month + INTERVAL '1 month' - INTERVAL '1 day')::date
 <= g.observation_end AS is_observable, a.active_customers AS recorded_customers
 FROM grid g LEFT JOIN active a USING (cohort_month,activity_month)
)
SELECT cohort_month, month_index, activity_month, cohort_size, is_observable,
 CASE WHEN is_observable THEN coalesce(recorded_customers,0) END AS active_customers,
 CASE WHEN is_observable THEN coalesce(recorded_customers,0)::numeric / cohort_size END AS activity_rate
FROM observed;
COMMIT;
