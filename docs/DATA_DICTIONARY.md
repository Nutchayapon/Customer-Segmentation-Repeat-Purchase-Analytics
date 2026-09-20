# Data Dictionary

Status: original headers and CSV records verified for all nine files. Core SQL types are based on inspected values. Tables have been authored but have not been created/imported in PostgreSQL.

## Core source columns

Column order below matches the CSV headers and raw-table definitions. Blank counts count empty or whitespace-only CSV fields; typed imports should map empty timestamp fields to SQL NULL.

### raw.customers

Source: olist_customers_dataset.csv. Verified records: 99,441.

| Column | Proposed PostgreSQL type | Blank records |
|---|---|---:|
| customer_id | text | 0 |
| customer_unique_id | text | 0 |
| customer_zip_code_prefix | text | 0 |
| customer_city | text | 0 |
| customer_state | text | 0 |

### raw.orders

Source: olist_orders_dataset.csv. Verified records: 99,441.

| Column | Proposed PostgreSQL type | Blank records |
|---|---|---:|
| order_id | text | 0 |
| customer_id | text | 0 |
| order_status | text | 0 |
| order_purchase_timestamp | timestamp without time zone | 0 |
| order_approved_at | timestamp without time zone | 160 |
| order_delivered_carrier_date | timestamp without time zone | 1,783 |
| order_delivered_customer_date | timestamp without time zone | 2,965 |
| order_estimated_delivery_date | timestamp without time zone | 0 |

### raw.order_items

Source: olist_order_items_dataset.csv. Verified records: 112,650.

| Column | Proposed PostgreSQL type | Blank records |
|---|---|---:|
| order_id | text | 0 |
| order_item_id | integer | 0 |
| product_id | text | 0 |
| seller_id | text | 0 |
| shipping_limit_date | timestamp without time zone | 0 |
| price | numeric | 0 |
| freight_value | numeric | 0 |

### raw.order_payments

Source: olist_order_payments_dataset.csv. Verified records: 103,886.

| Column | Proposed PostgreSQL type | Blank records |
|---|---|---:|
| order_id | text | 0 |
| payment_sequential | integer | 0 |
| payment_type | text | 0 |
| payment_installments | integer | 0 |
| payment_value | numeric | 0 |

## Keys and relationships

- customer_id is the order-linked customer record key; it joins orders to customers.
- customer_unique_id links repeat orders. The source has 99,441 customer records and 96,096 distinct customer_unique_id values; this is not a delivered-only customer count.
- order_id is the order key and the unit counted for purchase frequency.
- Item key: order_id + order_item_id.
- Payment-entry key: order_id + payment_sequential.
- All four expected keys have zero blank key rows and zero duplicate groups in the inspected CSVs.
- Items and payment entries are separate one-to-many children of orders. Aggregate each before joining both.
- Landing tables deliberately have no primary/foreign-key or NOT NULL constraints so profiling can expose source defects. Their types still enforce parseability.
- Text identifiers and ZIP prefixes preserve original source representations. Currency uses unconstrained numeric to avoid silently rounding future values.
- Source timestamps have no offset; no additional timezone is assumed.

See the [quality summary](DATA_QUALITY_SUMMARY.md) for missing children and date exceptions. Missing payment records must not be silently converted to zero or used to drop otherwise eligible merchandise orders.

## Other downloaded files

The files below have inventory/header/missingness checks only. Their keys and relationships have not received the deeper checks applied to the four core files.

### olist_geolocation_dataset.csv

Verified records: 1,000,163.

| Original column | Blank records |
|---|---:|
| geolocation_zip_code_prefix | 0 |
| geolocation_lat | 0 |
| geolocation_lng | 0 |
| geolocation_city | 0 |
| geolocation_state | 0 |

### olist_order_reviews_dataset.csv

Verified records: 99,224.

| Original column | Blank records |
|---|---:|
| review_id | 0 |
| order_id | 0 |
| review_score | 0 |
| review_comment_title | 87,658 |
| review_comment_message | 58,274 |
| review_creation_date | 0 |
| review_answer_timestamp | 0 |

### olist_products_dataset.csv

Verified records: 32,951.

| Original column | Blank records |
|---|---:|
| product_id | 0 |
| product_category_name | 610 |
| product_name_lenght | 610 |
| product_description_lenght | 610 |
| product_photos_qty | 610 |
| product_weight_g | 2 |
| product_length_cm | 2 |
| product_height_cm | 2 |
| product_width_cm | 2 |

### olist_sellers_dataset.csv

Verified records: 3,095.

| Original column | Blank records |
|---|---:|
| seller_id | 0 |
| seller_zip_code_prefix | 0 |
| seller_city | 0 |
| seller_state | 0 |

### product_category_name_translation.csv

Verified records: 71.

| Original column | Blank records |
|---|---:|
| product_category_name | 0 |
| product_category_name_english | 0 |

The source spellings product_name_lenght and product_description_lenght are intentionally preserved here. Product/category enrichment and review/geolocation joins need a separate grain and quality review before use.

## Planned analytical fields

| Field | Meaning |
|---|---|
| merchandise_value | Sum of item prices per eligible order |
| first_purchase_at / last_purchase_at | First/last observed eligible purchase timestamps |
| order_count | Count of distinct eligible orders |
| observed_spend | Sum of eligible merchandise value |
| cohort_month | Month of first observed eligible purchase |
| month_index | Calendar months since cohort_month |
| is_observable | Full cohort activity period is covered |
| is_eligible | Follow-up covers the selected repeat window |
| repeated_within_window | Repeat indicator; NULL for insufficient follow-up |
| gap_days | Elapsed days between consecutive purchases |

Analytical names, RFM thresholds, and the Power BI model remain subject to implementation.
