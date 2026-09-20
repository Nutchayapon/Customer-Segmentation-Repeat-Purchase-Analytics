# Data Dictionary

Status: planned schema. Verify headers, types, keys, and relationships against the downloaded CSVs before implementation.

## Source tables

| Source | Expected grain | Planned columns |
|---|---|---|
| Customers | One order-linked customer record | customer_id, customer_unique_id, customer_city, customer_state |
| Orders | One order | order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_customer_date, order_estimated_delivery_date |
| Order items | One item within an order | order_id, order_item_id, product_id, price, freight_value |
| Order payments | One payment entry within an order | order_id, payment_sequential, payment_type, payment_installments, payment_value |

Import definitions must handle all actual CSV columns, even if analysis uses only a subset.

## Keys and relationships

- customer_unique_id links observed purchases for a customer.
- customer_id joins orders to order-linked customer records.
- order_id identifies the unit counted for purchase frequency.
- Expected item key: order_id + order_item_id; validate uniqueness.
- Expected payment key: order_id + payment_sequential; validate uniqueness.
- A customer can have multiple orders; an order can have multiple items/payments.
- Aggregate items/payments separately by order before joining them together.
- Measure missing matches before deciding whether affected records enter analysis.

The [publisher metadata](https://www.kaggle.com/olistbr/brazilian-ecommerce/metadata) explains that one customer's orders may have different customer_id values. Dataset identifiers do not guarantee complete identity across all channels.

## Proposed analytical fields

| Field | Meaning | Proposed type |
|---|---|---|
| merchandise_value | Sum of item prices in an eligible order | numeric |
| freight_value | Sum of order item freight values | numeric |
| payment_value | Sum of payment-entry amounts | numeric |
| first_purchase_at | Earliest observed eligible purchase | timestamp |
| last_purchase_at | Latest observed eligible purchase | timestamp |
| order_count | Distinct eligible orders | integer/bigint |
| observed_spend | Sum of eligible merchandise value | numeric |
| cohort_month | First observed eligible purchase month | date |
| month_index | Calendar months since cohort month | integer |
| is_observable | Full cohort activity month is covered | boolean |
| is_eligible | Follow-up covers the selected repeat window | boolean |
| repeated_within_window | Second order within window; NULL if ineligible | boolean |
| gap_days | Elapsed consecutive-purchase time in days | numeric |

Use text identifiers and numeric currency values. Preserve source timestamp semantics; do not assume an undocumented timezone. Validate precision and formats during setup.

## Pending additions

- Actual source types, nullability, and row counts.
- Confirmed key checks and exceptions.
- Final database object/column names and implemented ERD.
- RFM score/segment dictionary with threshold boundaries and version.
