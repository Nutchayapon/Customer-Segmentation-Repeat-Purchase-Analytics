-- Purpose: read-only quality and coverage checks on imported raw Olist tables.
-- Status: authored and statically reviewed; NOT executed in PostgreSQL yet.
-- Prerequisite: run 00_setup.sql and import each of the four CSVs exactly once.
-- In pgAdmin, run individual numbered SELECT blocks to inspect/export results.
-- Running the entire file uses a repeatable read-only transaction.
-- Empty or mismatched tables must be resolved before interpreting later checks.
-- Counts in section 1 describe the downloaded version, not every future version.
-- No observation cutoff or analytical eligibility filter is applied globally.

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY;

-- 1. Import counts: compare with the verified CSV record counts (not line counts).
WITH expected(source_table, expected_rows) AS (
    VALUES ('customers', 99441::bigint),
           ('orders', 99441::bigint),
           ('order_items', 112650::bigint),
           ('order_payments', 103886::bigint)
),
actual AS (
    SELECT 'customers' AS source_table, count(*) AS actual_rows FROM raw.customers
    UNION ALL SELECT 'orders', count(*) FROM raw.orders
    UNION ALL SELECT 'order_items', count(*) FROM raw.order_items
    UNION ALL SELECT 'order_payments', count(*) FROM raw.order_payments
)
SELECT e.source_table, e.expected_rows, a.actual_rows,
       a.actual_rows - e.expected_rows AS difference,
       a.actual_rows = e.expected_rows AS matches_downloaded_version
FROM expected AS e
JOIN actual AS a USING (source_table)
ORDER BY e.source_table;

-- 2. Key uniqueness. Report groups and excess rows separately.
WITH key_counts AS (
    SELECT 'customers' AS source_table, count(*) AS rows_per_key
    FROM raw.customers GROUP BY customer_id
    UNION ALL
    SELECT 'orders', count(*) FROM raw.orders GROUP BY order_id
    UNION ALL
    SELECT 'order_items', count(*) FROM raw.order_items
    GROUP BY order_id, order_item_id
    UNION ALL
    SELECT 'order_payments', count(*) FROM raw.order_payments
    GROUP BY order_id, payment_sequential
)
SELECT source_table, count(*) AS distinct_key_groups,
       count(*) FILTER (WHERE rows_per_key > 1) AS duplicate_key_groups,
       coalesce(sum(rows_per_key - 1) FILTER (WHERE rows_per_key > 1), 0)
           AS duplicate_key_excess_rows
FROM key_counts
GROUP BY source_table ORDER BY source_table;

-- 3. Exact duplicate rows, without assuming uniqueness from a chosen key.
SELECT 'customers' AS source_table, count(*) - count(DISTINCT to_jsonb(c))
       AS exact_duplicate_excess_rows FROM raw.customers AS c
UNION ALL
SELECT 'orders', count(*) - count(DISTINCT to_jsonb(o)) FROM raw.orders AS o
UNION ALL
SELECT 'order_items', count(*) - count(DISTINCT to_jsonb(i)) FROM raw.order_items AS i
UNION ALL
SELECT 'order_payments', count(*) - count(DISTINCT to_jsonb(p)) FROM raw.order_payments AS p;

-- 4. Completeness for every imported column, including blank text.
WITH source_rows AS (
    SELECT 'customers' AS source_table, to_jsonb(c) AS row_data FROM raw.customers AS c
    UNION ALL SELECT 'orders', to_jsonb(o) FROM raw.orders AS o
    UNION ALL SELECT 'order_items', to_jsonb(i) FROM raw.order_items AS i
    UNION ALL SELECT 'order_payments', to_jsonb(p) FROM raw.order_payments AS p
),
columns_unpivoted AS (
    SELECT s.source_table, f.key AS column_name,
           (f.value = 'null'::jsonb
            OR (jsonb_typeof(f.value) = 'string' AND btrim(f.value #>> '{}') = ''))
               AS is_missing
    FROM source_rows AS s
    CROSS JOIN LATERAL jsonb_each(s.row_data) AS f
)
SELECT source_table, column_name, count(*) AS population_rows,
       count(*) FILTER (WHERE is_missing) AS missing_rows,
       round(100.0 * count(*) FILTER (WHERE is_missing) / nullif(count(*), 0), 4)
           AS missing_pct
FROM columns_unpivoted
GROUP BY source_table, column_name ORDER BY source_table, column_name;

-- 5. Key validity against this source's observed 32-character lowercase hex IDs.
WITH identifiers AS (
    SELECT 'customers' AS source_table, v.column_name, v.id_value
    FROM raw.customers AS c
    CROSS JOIN LATERAL (VALUES ('customer_id', c.customer_id),
                              ('customer_unique_id', c.customer_unique_id)) AS v(column_name, id_value)
    UNION ALL
    SELECT 'orders', v.column_name, v.id_value FROM raw.orders AS o
    CROSS JOIN LATERAL (VALUES ('order_id', o.order_id),
                              ('customer_id', o.customer_id)) AS v(column_name, id_value)
    UNION ALL
    SELECT 'order_items', v.column_name, v.id_value FROM raw.order_items AS i
    CROSS JOIN LATERAL (VALUES ('order_id', i.order_id), ('product_id', i.product_id),
                              ('seller_id', i.seller_id)) AS v(column_name, id_value)
    UNION ALL
    SELECT 'order_payments', 'order_id', order_id FROM raw.order_payments
)
SELECT source_table, column_name, count(*) AS population_rows,
       count(*) FILTER (WHERE id_value IS NULL OR id_value !~ '^[0-9a-f]{32}$')
           AS invalid_or_missing_rows
FROM identifiers
GROUP BY source_table, column_name ORDER BY source_table, column_name;

-- 6. Join coverage. EXISTS avoids multiplication when a source key is duplicated.
WITH checks AS (
    SELECT 'orders_without_customer' AS check_name, count(*) AS population_rows,
           count(*) FILTER (WHERE NOT EXISTS (
               SELECT 1 FROM raw.customers AS c WHERE c.customer_id = o.customer_id
           )) AS affected_rows FROM raw.orders AS o
    UNION ALL
    SELECT 'item_rows_without_order', count(*), count(*) FILTER (WHERE NOT EXISTS (
        SELECT 1 FROM raw.orders AS o WHERE o.order_id = i.order_id
    )) FROM raw.order_items AS i
    UNION ALL
    SELECT 'payment_rows_without_order', count(*), count(*) FILTER (WHERE NOT EXISTS (
        SELECT 1 FROM raw.orders AS o WHERE o.order_id = p.order_id
    )) FROM raw.order_payments AS p
    UNION ALL
    SELECT 'orders_without_items', count(*), count(*) FILTER (WHERE NOT EXISTS (
        SELECT 1 FROM raw.order_items AS i WHERE i.order_id = o.order_id
    )) FROM raw.orders AS o
    UNION ALL
    SELECT 'orders_without_payments', count(*), count(*) FILTER (WHERE NOT EXISTS (
        SELECT 1 FROM raw.order_payments AS p WHERE p.order_id = o.order_id
    )) FROM raw.orders AS o
    UNION ALL
    SELECT 'delivered_orders_without_items', count(*), count(*) FILTER (WHERE NOT EXISTS (
        SELECT 1 FROM raw.order_items AS i WHERE i.order_id = o.order_id
    )) FROM raw.orders AS o WHERE o.order_status = 'delivered'
    UNION ALL
    SELECT 'delivered_orders_without_payments', count(*), count(*) FILTER (WHERE NOT EXISTS (
        SELECT 1 FROM raw.order_payments AS p WHERE p.order_id = o.order_id
    )) FROM raw.orders AS o WHERE o.order_status = 'delivered'
)
SELECT check_name, population_rows, affected_rows,
       round(100.0 * affected_rows / nullif(population_rows, 0), 4) AS affected_pct
FROM checks ORDER BY check_name;

-- 7. Source customer mapping and order status distribution.
SELECT count(*) AS customer_records,
       count(DISTINCT customer_id) AS distinct_customer_ids,
       count(DISTINCT customer_unique_id) AS distinct_customer_unique_ids
FROM raw.customers;

SELECT order_status, count(*) AS orders,
       round(100.0 * count(*) / nullif(sum(count(*)) OVER (), 0), 4) AS order_pct,
       min(order_purchase_timestamp) AS first_purchase,
       max(order_purchase_timestamp) AS last_purchase
FROM raw.orders
GROUP BY order_status ORDER BY orders DESC, order_status;

-- 8. Timestamp ranges. NULLs are counted; estimated dates are not actual coverage.
SELECT v.column_name, count(*) AS population_rows,
       count(v.event_at) AS nonnull_rows,
       min(v.event_at) AS earliest_timestamp, max(v.event_at) AS latest_timestamp
FROM raw.orders AS o
CROSS JOIN LATERAL (
    VALUES ('order_purchase_timestamp', o.order_purchase_timestamp),
           ('order_approved_at', o.order_approved_at),
           ('order_delivered_carrier_date', o.order_delivered_carrier_date),
           ('order_delivered_customer_date', o.order_delivered_customer_date),
           ('order_estimated_delivery_date', o.order_estimated_delivery_date)
) AS v(column_name, event_at)
GROUP BY v.column_name ORDER BY v.column_name;

-- 9. Monthly coverage includes calendar months with no orders.
-- A zero in this raw coverage profile means no source rows, not zero retention.
WITH bounds AS (
    SELECT date_trunc('month', min(order_purchase_timestamp)) AS first_month,
           date_trunc('month', max(order_purchase_timestamp)) AS last_month
    FROM raw.orders
),
calendar AS (
    SELECT m.month_start::date AS purchase_month
    FROM bounds AS b
    CROSS JOIN LATERAL generate_series(b.first_month, b.last_month, interval '1 month')
        AS m(month_start)
),
monthly AS (
    SELECT date_trunc('month', order_purchase_timestamp)::date AS purchase_month,
           count(*) AS all_orders,
           count(*) FILTER (WHERE order_status = 'delivered') AS delivered_orders,
           count(*) FILTER (WHERE order_status = 'canceled') AS canceled_orders,
           count(*) FILTER (WHERE order_status = 'unavailable') AS unavailable_orders,
           min(order_purchase_timestamp)::date AS first_observed_date,
           max(order_purchase_timestamp)::date AS last_observed_date
    FROM raw.orders WHERE order_purchase_timestamp IS NOT NULL
    GROUP BY 1
)
SELECT c.purchase_month, coalesce(m.all_orders, 0) AS all_orders,
       coalesce(m.delivered_orders, 0) AS delivered_orders,
       coalesce(m.canceled_orders, 0) AS canceled_orders,
       coalesce(m.unavailable_orders, 0) AS unavailable_orders,
       m.first_observed_date, m.last_observed_date
FROM calendar AS c LEFT JOIN monthly AS m USING (purchase_month)
ORDER BY c.purchase_month;

-- 10. Daily activity near the end, to inform a defensible cutoff.
WITH bounds AS (
    SELECT max(order_purchase_timestamp)::date AS last_source_date FROM raw.orders
),
calendar AS (
    SELECT d.day_start::date AS purchase_date
    FROM bounds AS b
    CROSS JOIN LATERAL generate_series(
        (b.last_source_date - 89)::timestamp, b.last_source_date::timestamp, interval '1 day'
    ) AS d(day_start)
),
daily AS (
    SELECT order_purchase_timestamp::date AS purchase_date,
           count(*) AS all_orders,
           count(*) FILTER (WHERE order_status = 'delivered') AS delivered_orders
    FROM raw.orders
    WHERE order_purchase_timestamp::date >= (SELECT last_source_date - 89 FROM bounds)
    GROUP BY 1
)
SELECT c.purchase_date, coalesce(d.all_orders, 0) AS all_orders,
       coalesce(d.delivered_orders, 0) AS delivered_orders
FROM calendar AS c LEFT JOIN daily AS d USING (purchase_date)
ORDER BY c.purchase_date;

-- 11. Numeric domain checks. Zero freight can be valid; report without deleting.
WITH measures AS (
    SELECT v.metric, v.value FROM raw.order_items AS i
    CROSS JOIN LATERAL (VALUES ('order_items.price', i.price),
                              ('order_items.freight_value', i.freight_value),
                              ('order_items.order_item_id', i.order_item_id::numeric)) AS v(metric, value)
    UNION ALL
    SELECT v.metric, v.value FROM raw.order_payments AS p
    CROSS JOIN LATERAL (VALUES ('order_payments.payment_value', p.payment_value),
                              ('order_payments.payment_installments', p.payment_installments::numeric),
                              ('order_payments.payment_sequential', p.payment_sequential::numeric)) AS v(metric, value)
)
SELECT metric, count(*) AS population_rows, count(value) AS nonnull_rows,
       count(*) FILTER (WHERE value < 0) AS negative_rows,
       count(*) FILTER (WHERE value = 0) AS zero_rows,
       min(value) AS minimum, max(value) AS maximum, sum(value) AS total
FROM measures GROUP BY metric ORDER BY metric;

-- 12. Status/date consistency. Missing delivery dates do not change source status.
SELECT count(*) FILTER (WHERE order_status = 'delivered') AS delivered_orders,
       count(*) FILTER (WHERE order_status = 'delivered'
                         AND order_delivered_customer_date IS NULL) AS delivered_missing_delivery,
       count(*) FILTER (WHERE order_status = 'delivered'
                         AND order_approved_at IS NULL) AS delivered_missing_approval,
       count(*) FILTER (WHERE order_delivered_customer_date < order_purchase_timestamp)
           AS delivery_before_purchase,
       count(*) FILTER (WHERE order_approved_at < order_purchase_timestamp)
           AS approval_before_purchase
FROM raw.orders;

-- 13. Observed delivery lag, conditional on delivered status and known dates.
WITH lags AS (
    SELECT (extract(epoch FROM (order_delivered_customer_date - order_purchase_timestamp))
            / 86400.0)::double precision AS days
    FROM raw.orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_purchase_timestamp IS NOT NULL
)
SELECT count(*) AS known_lag_orders, min(days) AS minimum_days,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY days) AS median_days,
       percentile_cont(0.95) WITHIN GROUP (ORDER BY days) AS p95_days,
       max(days) AS maximum_days
FROM lags;

-- 14. Monetary reconciliation: compare only orders with both source aggregates.
-- 0.01 BRL is a diagnostic threshold, not an automatic cleansing rule.
-- Missing/NULL component values must be investigated via section 4 first.
WITH item_totals AS (
    SELECT order_id, sum(price) AS merchandise_value, sum(freight_value) AS freight_value
    FROM raw.order_items GROUP BY order_id
),
payment_totals AS (
    SELECT order_id, sum(payment_value) AS payment_value
    FROM raw.order_payments GROUP BY order_id
),
matched AS (
    SELECT o.order_id, o.order_status,
           p.payment_value - i.merchandise_value - i.freight_value AS difference
    FROM raw.orders AS o
    JOIN item_totals AS i USING (order_id)
    JOIN payment_totals AS p USING (order_id)
),
scoped AS (
    SELECT 'all_orders' AS population, difference FROM matched
    UNION ALL
    SELECT 'delivered_orders', difference FROM matched WHERE order_status = 'delivered'
)
SELECT population, count(*) AS matched_orders,
       count(difference) AS calculable_differences,
       count(*) FILTER (WHERE difference = 0) AS exact_matches,
       count(*) FILTER (WHERE abs(difference) > 0.01) AS absolute_difference_over_0_01,
       sum(difference) AS net_difference,
       max(abs(difference)) AS largest_absolute_difference
FROM scoped GROUP BY population ORDER BY population;

COMMIT;
