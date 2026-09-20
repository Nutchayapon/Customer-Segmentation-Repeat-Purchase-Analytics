-- Fixed retrospective snapshot. Ties receive equal scores; buckets can be unequal.
BEGIN;
CREATE OR REPLACE VIEW analytics.rfm_thresholds AS
SELECT (bounds)[1] AS monetary_p20, (bounds)[2] AS monetary_p40,
 (bounds)[3] AS monetary_p60, (bounds)[4] AS monetary_p80
FROM (SELECT percentile_disc(ARRAY[0.2,0.4,0.6,0.8])
 WITHIN GROUP (ORDER BY monetary_value) AS bounds FROM analytics.customer_metrics) t;
CREATE OR REPLACE VIEW analytics.rfm AS
WITH scores AS (
 SELECT c.*,
 CASE WHEN recency_days <= 30 THEN 5 WHEN recency_days <= 60 THEN 4
      WHEN recency_days <= 90 THEN 3 WHEN recency_days <= 180 THEN 2 ELSE 1 END AS r_score,
 least(order_count,5)::integer AS f_score,
 CASE WHEN monetary_value <= t.monetary_p20 THEN 1 WHEN monetary_value <= t.monetary_p40 THEN 2
      WHEN monetary_value <= t.monetary_p60 THEN 3 WHEN monetary_value <= t.monetary_p80 THEN 4 ELSE 5 END AS m_score
 FROM analytics.customer_metrics c CROSS JOIN analytics.rfm_thresholds t
)
SELECT *, concat(r_score,f_score,m_score) AS rfm_code,
 CASE WHEN order_count >= 2 AND recency_days <= 90 AND m_score >= 4 THEN 'Recent high-value repeat'
      WHEN order_count >= 2 AND recency_days <= 90 THEN 'Recent repeat'
      WHEN order_count >= 2 THEN 'Less-recent repeat'
      WHEN recency_days <= 90 THEN 'Recent one-time' ELSE 'Older one-time' END AS segment
FROM scores;
CREATE OR REPLACE VIEW analytics.segment_summary AS
SELECT segment, count(*) AS customers, sum(order_count) AS orders, sum(monetary_value) AS merchandise_value,
 avg(recency_days) AS average_recency_days, avg(order_count) AS average_frequency,
 percentile_cont(0.5) WITHIN GROUP (ORDER BY monetary_value) AS median_customer_value
FROM analytics.rfm GROUP BY segment;
COMMIT;
