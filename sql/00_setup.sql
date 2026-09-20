-- Purpose: create non-destructive landing tables for the four core Olist CSVs.
-- Source: Olist version 2, headers verified against the downloaded files.
-- Status: authored and statically reviewed; NOT executed in PostgreSQL yet.
-- Run in a dedicated empty project database, then import through pgAdmin.
-- Raw tables deliberately have no PK/FK/NOT NULL constraints: profile defects
-- rather than hiding them through rejected imports. Types enforce parseability.
-- Re-running preserves data. IF NOT EXISTS does not repair schema drift.
-- Never import the same CSV twice without an explicit reload plan.

BEGIN;

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS bi;

-- Header order exactly matches olist_customers_dataset.csv.
CREATE TABLE IF NOT EXISTS raw.customers (
    customer_id text,
    customer_unique_id text,
    customer_zip_code_prefix text,
    customer_city text,
    customer_state text
);

-- Header order exactly matches olist_orders_dataset.csv.
-- Source timestamps have no timezone offset; do not invent one.
CREATE TABLE IF NOT EXISTS raw.orders (
    order_id text,
    customer_id text,
    order_status text,
    order_purchase_timestamp timestamp without time zone,
    order_approved_at timestamp without time zone,
    order_delivered_carrier_date timestamp without time zone,
    order_delivered_customer_date timestamp without time zone,
    order_estimated_delivery_date timestamp without time zone
);

-- Header order exactly matches olist_order_items_dataset.csv.
-- Unconstrained numeric preserves source precision without implicit rounding.
CREATE TABLE IF NOT EXISTS raw.order_items (
    order_id text,
    order_item_id integer,
    product_id text,
    seller_id text,
    shipping_limit_date timestamp without time zone,
    price numeric,
    freight_value numeric
);

-- Header order exactly matches olist_order_payments_dataset.csv.
-- Zero installments/payment values are retained for profiling.
CREATE TABLE IF NOT EXISTS raw.order_payments (
    order_id text,
    payment_sequential integer,
    payment_type text,
    payment_installments integer,
    payment_value numeric
);

-- Non-unique indexes support joins without concealing duplicate source keys.
CREATE INDEX IF NOT EXISTS customers_customer_id_idx ON raw.customers (customer_id);
CREATE INDEX IF NOT EXISTS customers_unique_id_idx ON raw.customers (customer_unique_id);
CREATE INDEX IF NOT EXISTS orders_order_id_idx ON raw.orders (order_id);
CREATE INDEX IF NOT EXISTS orders_customer_id_idx ON raw.orders (customer_id);
CREATE INDEX IF NOT EXISTS order_items_order_id_idx ON raw.order_items (order_id);
CREATE INDEX IF NOT EXISTS order_payments_order_id_idx ON raw.order_payments (order_id);

-- No dates are selected automatically. Review source coverage before filling in.
CREATE TABLE IF NOT EXISTS analytics.analysis_config (
    singleton boolean PRIMARY KEY DEFAULT true CHECK (singleton),
    observation_start date,
    observation_end date,
    cutoff_rationale text,
    CONSTRAINT observation_dates_valid CHECK (
        (observation_start IS NULL AND observation_end IS NULL)
        OR
        (observation_start IS NOT NULL AND observation_end IS NOT NULL
         AND observation_start <= observation_end)
    ),
    CONSTRAINT chosen_dates_have_rationale CHECK (
        observation_end IS NULL
        OR (cutoff_rationale IS NOT NULL AND btrim(cutoff_rationale) <> '')
    )
);

INSERT INTO analytics.analysis_config (singleton)
VALUES (true)
ON CONFLICT (singleton) DO NOTHING;

COMMIT;

-- Inspect this result before importing into an existing database.
SELECT table_name, ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'raw'
  AND table_name IN ('customers', 'orders', 'order_items', 'order_payments')
ORDER BY table_name, ordinal_position;

-- NULL dates are intentional until the coverage review is complete.
SELECT observation_start, observation_end,
       observation_end + 1 AS proposed_rfm_reference_date,
       cutoff_rationale
FROM analytics.analysis_config;
