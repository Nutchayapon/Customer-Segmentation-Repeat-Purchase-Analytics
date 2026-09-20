-- Calendar-day windows, inclusive through the entire first purchase date + N.
BEGIN;
CREATE OR REPLACE VIEW analytics.repeat_windows AS
SELECT c.customer_unique_id, c.cohort_month, c.primary_cohort, w.window_days,
 c.observed_followup_days >= w.window_days AS is_eligible,
 CASE WHEN c.observed_followup_days >= w.window_days THEN c.second_purchase_timestamp IS NOT NULL
 AND c.second_purchase_timestamp::date <= c.first_purchase_date + w.window_days END AS repeated_within_window,
 c.observed_followup_days >= 90 AS common_90_day_population
FROM analytics.customer_metrics c CROSS JOIN (VALUES (30),(60),(90)) w(window_days);
CREATE OR REPLACE VIEW analytics.repeat_summary AS
SELECT window_days, count(*) FILTER (WHERE is_eligible) AS eligible_customers,
 count(*) FILTER (WHERE repeated_within_window) AS repeat_customers,
 count(*) FILTER (WHERE repeated_within_window)::numeric / nullif(count(*) FILTER (WHERE is_eligible),0) AS repeat_rate,
 count(*) FILTER (WHERE common_90_day_population) AS common_eligible_customers,
 count(*) FILTER (WHERE common_90_day_population AND repeated_within_window) AS common_repeat_customers,
 count(*) FILTER (WHERE common_90_day_population AND repeated_within_window)::numeric
 / nullif(count(*) FILTER (WHERE common_90_day_population),0) AS common_repeat_rate
FROM analytics.repeat_windows GROUP BY window_days;
CREATE OR REPLACE VIEW analytics.purchase_frequency AS
SELECT order_count, count(*) AS customers, sum(monetary_value) AS merchandise_value
FROM analytics.customer_metrics GROUP BY order_count;
-- Alternative definition: purchase on a later calendar day, preserving primary order counts.
CREATE OR REPLACE VIEW analytics.distinct_day_sensitivity AS
WITH days AS (
 SELECT customer_unique_id, count(DISTINCT purchase_date) AS purchase_days
 FROM analytics.orders GROUP BY customer_unique_id
)
SELECT count(*) AS customers, count(*) FILTER (WHERE purchase_days>=2) AS later_day_repeat_customers,
 count(*) FILTER (WHERE purchase_days>=2)::numeric / nullif(count(*),0) AS later_day_repeat_rate
FROM days;
COMMIT;
