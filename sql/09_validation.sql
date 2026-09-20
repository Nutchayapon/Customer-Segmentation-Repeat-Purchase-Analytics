-- Reproducible invariants. Snapshot derived views once for efficient checks.
BEGIN ISOLATION LEVEL REPEATABLE READ;
CREATE TEMP TABLE v_orders ON COMMIT DROP AS SELECT * FROM analytics.orders;
CREATE TEMP TABLE v_customers ON COMMIT DROP AS SELECT * FROM analytics.rfm;
CREATE TEMP TABLE v_history ON COMMIT DROP AS SELECT * FROM analytics.customer_order_history;
CREATE TEMP TABLE v_cohort ON COMMIT DROP AS SELECT * FROM analytics.cohort_activity;
CREATE TEMP TABLE v_windows ON COMMIT DROP AS SELECT * FROM analytics.repeat_windows;
CREATE TEMP TABLE v_intervals ON COMMIT DROP AS SELECT * FROM analytics.purchase_intervals;
CREATE TABLE IF NOT EXISTS analytics.validation_results (
 check_name text PRIMARY KEY, expected numeric, actual numeric, passed boolean, checked_at timestamptz
);
TRUNCATE analytics.validation_results;
INSERT INTO analytics.validation_results
SELECT name, expected, actual, expected IS NOT DISTINCT FROM actual, current_timestamp
FROM (VALUES
 ('order_grain',0::numeric,(SELECT count(*)-count(DISTINCT order_id) FROM v_orders)),
 ('customer_grain',0,(SELECT count(*)-count(DISTINCT customer_unique_id) FROM v_customers)),
 ('eligible_order_count',(SELECT count(*) FROM raw.orders o CROSS JOIN analytics.analysis_config c
    WHERE o.order_status='delivered' AND o.order_purchase_timestamp::date BETWEEN c.observation_start AND c.observation_end),
    (SELECT count(*) FROM v_orders)),
 ('merchandise_reconciliation',(SELECT sum(i.price) FROM raw.order_items i JOIN v_orders o USING(order_id)),
    (SELECT sum(merchandise_value) FROM v_orders)),
 ('customer_order_reconciliation',(SELECT count(*) FROM v_orders),(SELECT sum(order_count) FROM v_customers)),
 ('customer_spend_reconciliation',(SELECT sum(merchandise_value) FROM v_orders),(SELECT sum(monetary_value) FROM v_customers)),
 ('history_grain',(SELECT count(*) FROM v_orders),(SELECT count(*) FROM v_history)),
 ('customer_count',(SELECT count(DISTINCT customer_unique_id) FROM v_orders),(SELECT count(*) FROM v_customers)),
 ('invalid_scores',0,(SELECT count(*) FROM v_customers WHERE r_score NOT BETWEEN 1 AND 5 OR f_score NOT BETWEEN 1 AND 5 OR m_score NOT BETWEEN 1 AND 5)),
 ('recency_ties',0,(SELECT count(*) FROM (SELECT recency_days FROM v_customers GROUP BY 1 HAVING min(r_score)<>max(r_score)) x)),
 ('frequency_ties',0,(SELECT count(*) FROM (SELECT order_count FROM v_customers GROUP BY 1 HAVING min(f_score)<>max(f_score)) x)),
 ('monetary_ties',0,(SELECT count(*) FROM (SELECT monetary_value FROM v_customers GROUP BY 1 HAVING min(m_score)<>max(m_score)) x)),
 ('invalid_customer_dates',0,(SELECT count(*) FROM v_customers WHERE recency_days<1 OR purchase_span_days<0 OR observed_followup_days<0)),
 ('missing_segments',0,(SELECT count(*) FROM v_customers WHERE segment IS NULL)),
 ('cohort_grain',0,(SELECT count(*) FROM (SELECT cohort_month,month_index FROM v_cohort GROUP BY 1,2 HAVING count(*)>1) x)),
 ('cohort_month_zero',0,(SELECT count(*) FROM v_cohort WHERE month_index=0 AND active_customers IS DISTINCT FROM cohort_size)),
 ('unobservable_cohort_cells',0,(SELECT count(*) FROM v_cohort WHERE NOT is_observable AND (active_customers IS NOT NULL OR activity_rate IS NOT NULL))),
 ('cohort_bounds',0,(SELECT count(*) FROM v_cohort WHERE is_observable AND (active_customers IS NULL OR active_customers<0 OR active_customers>cohort_size))),
 ('repeat_window_grain',0,(SELECT count(*) FROM (SELECT customer_unique_id,window_days FROM v_windows GROUP BY 1,2 HAVING count(*)>1) x)),
 ('repeat_window_count',(SELECT count(*)*3 FROM v_customers),(SELECT count(*) FROM v_windows)),
 ('ineligible_windows_are_null',0,(SELECT count(*) FROM v_windows WHERE NOT is_eligible AND repeated_within_window IS NOT NULL)),
 ('eligible_windows_are_known',0,(SELECT count(*) FROM v_windows WHERE is_eligible AND repeated_within_window IS NULL)),
 ('repeat_population_partition',(SELECT count(*) FROM v_customers),
    (SELECT count(*) FILTER (WHERE order_count=1)+count(*) FILTER (WHERE order_count>=2) FROM v_customers)),
 ('interval_count',(SELECT sum(order_count-1) FROM v_customers),(SELECT count(*) FROM v_intervals)),
 ('first_to_second_count',(SELECT count(*) FROM v_customers WHERE order_count>=2),
    (SELECT count(*) FROM v_intervals WHERE is_first_to_second)),
 ('nonnegative_intervals',0,(SELECT count(*) FROM v_intervals WHERE gap_days<0 OR gap_days IS NULL)),
 ('sequence_per_customer',0,(SELECT count(*) FROM (
    SELECT customer_unique_id FROM v_history GROUP BY 1
    HAVING min(purchase_number)<>1 OR max(purchase_number)<>count(*) OR count(DISTINCT purchase_number)<>count(*)
 ) x)),
 ('cohort_month_index',0,(SELECT count(*) FROM v_cohort WHERE activity_month <>
    (cohort_month+make_interval(months=>month_index))::date))
) checks(name,expected,actual);
DO $$
BEGIN
 IF EXISTS (SELECT 1 FROM analytics.validation_results WHERE NOT passed) THEN
  RAISE EXCEPTION 'Analytical validation failed. Inspect check definitions and source population.';
 END IF;
END;
$$;
SELECT * FROM analytics.validation_results ORDER BY check_name;
COMMIT;
