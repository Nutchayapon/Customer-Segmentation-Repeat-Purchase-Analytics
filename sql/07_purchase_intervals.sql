BEGIN;
CREATE OR REPLACE VIEW analytics.purchase_intervals AS
SELECT customer_unique_id, order_id, previous_order_id, purchase_number,
 order_purchase_timestamp, previous_purchase_timestamp,
 extract(epoch FROM (order_purchase_timestamp-previous_purchase_timestamp))/86400.0 AS gap_days,
 purchase_number=2 AS is_first_to_second,
 order_purchase_timestamp::date=previous_purchase_timestamp::date AS same_day,
 order_purchase_timestamp=previous_purchase_timestamp AS same_timestamp
FROM analytics.customer_order_history WHERE purchase_number>1;
CREATE OR REPLACE VIEW analytics.interval_summary AS
WITH populations AS (
 SELECT 'All consecutive intervals'::text AS population,gap_days FROM analytics.purchase_intervals
 UNION ALL SELECT 'First-to-second intervals',gap_days FROM analytics.purchase_intervals WHERE is_first_to_second
)
SELECT population,count(*) AS intervals,count(*) FILTER (WHERE gap_days=0) AS zero_duration_intervals,
 percentile_cont(0.25) WITHIN GROUP (ORDER BY gap_days) AS p25_days,
 percentile_cont(0.5) WITHIN GROUP (ORDER BY gap_days) AS median_days,
 percentile_cont(0.75) WITHIN GROUP (ORDER BY gap_days) AS p75_days,
 percentile_cont(0.9) WITHIN GROUP (ORDER BY gap_days) AS p90_days,avg(gap_days) AS mean_days
FROM populations GROUP BY population;
CREATE OR REPLACE VIEW analytics.interval_distribution AS
WITH buckets AS (
 SELECT CASE WHEN gap_days=0 THEN 0 WHEN gap_days<=1 THEN 1 WHEN gap_days<=7 THEN 2
 WHEN gap_days<=30 THEN 3 WHEN gap_days<=60 THEN 4 WHEN gap_days<=90 THEN 5
 WHEN gap_days<=180 THEN 6 ELSE 7 END AS bucket_order,is_first_to_second
 FROM analytics.purchase_intervals
)
SELECT bucket_order,
 (ARRAY['Exactly 0 days','(0, 1] days','(1, 7] days','(7, 30] days',
 '(30, 60] days','(60, 90] days','(90, 180] days','Over 180 days'])[bucket_order+1] AS gap_bucket,
 count(*) AS all_intervals,count(*) FILTER (WHERE is_first_to_second) AS first_to_second_intervals
FROM buckets GROUP BY bucket_order;
COMMIT;
