-- Import-mode model. Date filters must not redefine the fixed customer snapshot.
BEGIN;
CREATE OR REPLACE VIEW bi.customers AS SELECT * FROM analytics.rfm;
CREATE OR REPLACE VIEW bi.orders AS
SELECT *,purchase_number>1 AS is_returning_order FROM analytics.customer_order_history;
CREATE OR REPLACE VIEW bi.repeat_windows AS SELECT * FROM analytics.repeat_windows;
CREATE OR REPLACE VIEW bi.purchase_intervals AS SELECT * FROM analytics.purchase_intervals;
-- Disconnected aggregate: supports cohort and month-index filters only.
CREATE OR REPLACE VIEW bi.cohort_activity AS SELECT * FROM analytics.cohort_activity;
CREATE OR REPLACE VIEW bi.dates AS
SELECT d::date AS date,extract(year FROM d)::integer AS year,
 extract(month FROM d)::integer AS month_number,to_char(d,'YYYY-MM') AS year_month
FROM analytics.analysis_config c CROSS JOIN LATERAL
generate_series(c.observation_start::timestamp,c.observation_end::timestamp,INTERVAL '1 day') d;
CREATE OR REPLACE VIEW bi.segment_summary AS SELECT * FROM analytics.segment_summary;
CREATE OR REPLACE VIEW bi.repeat_summary AS SELECT * FROM analytics.repeat_summary;
CREATE OR REPLACE VIEW bi.purchase_frequency AS SELECT * FROM analytics.purchase_frequency;
CREATE OR REPLACE VIEW bi.interval_distribution AS SELECT * FROM analytics.interval_distribution;
CREATE OR REPLACE VIEW bi.monthly_orders AS
SELECT date_trunc('month',order_purchase_timestamp)::date AS purchase_month,count(*) AS orders,
 count(*) FILTER (WHERE purchase_number>1) AS returning_orders,sum(merchandise_value) AS merchandise_value
FROM analytics.customer_order_history GROUP BY 1;
COMMIT;
