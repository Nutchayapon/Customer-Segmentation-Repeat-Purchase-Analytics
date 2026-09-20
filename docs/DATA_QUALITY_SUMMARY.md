# Data Quality Summary

Status: source inspection, PostgreSQL import, and database profiling completed. Analytical cutoff and exception policies remain open.

## Evidence and scope

Source: [Olist dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), API version 2. All nine CSVs were checked for record counts, original headers, byte sizes, hashes, and blanks. Four core files received key, relationship, format, timestamp, numeric, and reconciliation checks.

Inspection completed (UTC): 2026-09-20T11:53:48.892515+00:00. A one-off local inspection used the already bundled Python standard library; it did not add a project dependency or substitute another SQL engine. The helper and full local output are in outputs/tables/ and are ignored by Git. [SOURCE_PROFILE.json](SOURCE_PROFILE.json) publishes aggregate evidence and hashes only, without customer/order records. Database-side counterparts are in [01_data_overview_and_quality.sql](../sql/01_data_overview_and_quality.sql), which executed successfully on PostgreSQL 18.6 on September 20, 2026. [DATABASE_VALIDATION.json](DATABASE_VALIDATION.json) records matching full-table source/database fingerprints and counts. The source JSON retains its original pre-installation status as a historical snapshot.

## Source inventory

| File | CSV records | Columns |
|---|---:|---:|
| olist_customers_dataset.csv | 99,441 | 5 |
| olist_geolocation_dataset.csv | 1,000,163 | 5 |
| olist_order_items_dataset.csv | 112,650 | 7 |
| olist_order_payments_dataset.csv | 103,886 | 5 |
| olist_order_reviews_dataset.csv | 99,224 | 7 |
| olist_orders_dataset.csv | 99,441 | 8 |
| olist_products_dataset.csv | 32,951 | 9 |
| olist_sellers_dataset.csv | 3,095 | 4 |
| product_category_name_translation.csv | 71 | 2 |

## Findings and analytical implications

| Finding | Evidence | Severity for planned analysis | Proposed response |
|---|---|---|---|
| Core keys are complete and unique | 0 blank keys, duplicate key groups, and exact duplicate excess rows in each of the 4 core files | No issue detected within checked scope | Reproduced after import; these results do not imply optional-file keys were verified |
| Parent joins are complete | 0 orders without customer; 0 item/payment rows without order | No issue detected within checked scope | Reproduced in PostgreSQL |
| Some orders have no items | 775 / 99,441 orders (0.7794%); 0 delivered orders without items | Medium for all-status spending | Preserve diagnostics; status-based eligibility must be explicit |
| One delivered order has no payment row | 1 / 96,478 delivered orders (0.0010%) | Medium for payment-based measures | Keep merchandise and payment definitions separate; retain missing-payment flag |
| Delivered status can lack dates | 8 / 96,478 lack delivery date (0.0083%); 14 lack approval date (0.0145%) | Medium for delivery/approval analysis | Do not infer a date; expose missingness and state the population for lag measures |
| Payment and item totals are not identical for every matched order | 299 / 96,477 delivered matched orders differ by more than BRL 0.01 (0.3099%); largest absolute difference BRL 182.81 | Medium for reconciliation | Investigate before asserting an accounting identity; do not overwrite amounts or label the cause without evidence |
| Zero payment values/installments occur | 9 zero payment-value rows and 2 zero installment-count rows out of 103,886 payment entries | Low for merchandise RFM; needs review for payment analysis | Preserve values and investigate context; do not multiply payment_value by installments |
| Numeric values are nonnegative in inspected core fields | No negative price, freight, payment, item sequence, payment sequence, or installment values | No issue detected within checked scope | Preserve numeric precision and rerun range checks after import |
| Coverage is uneven at the boundaries | Sparse 2016 activity, no November 2016 orders, and no delivered orders purchased in September–October 2018 | High for cohorts and repeat windows | Do not treat the maximum source timestamp as proof of complete follow-up |

These are measured source-file findings reproduced in PostgreSQL. Root causes for missing payments, timestamp gaps, and monetary differences remain unconfirmed.

## Observation-period decision remains open

- All-status purchase range: 2016-09-04 21:15:19 through 2018-10-17 17:30:18.
- Delivered-order purchase range: 2016-09-15 12:16:38 through 2018-08-29 15:00:37.
- September 2018 has 16 orders (15 canceled, 1 shipped); October has 4 canceled orders.
- The early months are sparse: September 2016 has 4 orders, October 324, November 0, and December 1.
- Among 96,470 delivered orders with known delivery dates, median elapsed delivery time is 10.22 days and p95 is 29.27 days. These conditional statistics do not establish coverage completeness.

The analysis configuration deliberately keeps observation dates NULL. Before preparation, compare candidate cutoffs and document a full-month cohort policy plus delivery-maturity limitations. Do not interpret September–October as two extra months of complete delivered-purchase follow-up. Do not silently discard early history when defining first observed purchase; if a later reporting window is selected, preserve any available prior history for cohort/returning classification.

## Monthly source coverage

This table describes the downloaded extract, not customer retention. A zero records count establishes only that no source orders were present in that month.

| Purchase month | All statuses | Delivered |
|---|---:|---:|
| 2016-09 | 4 | 1 |
| 2016-10 | 324 | 265 |
| 2016-11 | 0 | 0 |
| 2016-12 | 1 | 1 |
| 2017-01 | 800 | 750 |
| 2017-02 | 1,780 | 1,653 |
| 2017-03 | 2,682 | 2,546 |
| 2017-04 | 2,404 | 2,303 |
| 2017-05 | 3,700 | 3,546 |
| 2017-06 | 3,245 | 3,135 |
| 2017-07 | 4,026 | 3,872 |
| 2017-08 | 4,331 | 4,193 |
| 2017-09 | 4,285 | 4,150 |
| 2017-10 | 4,631 | 4,478 |
| 2017-11 | 7,544 | 7,289 |
| 2017-12 | 5,673 | 5,513 |
| 2018-01 | 7,269 | 7,069 |
| 2018-02 | 6,728 | 6,555 |
| 2018-03 | 7,211 | 7,003 |
| 2018-04 | 6,939 | 6,798 |
| 2018-05 | 6,873 | 6,749 |
| 2018-06 | 6,167 | 6,099 |
| 2018-07 | 6,292 | 6,159 |
| 2018-08 | 6,512 | 6,351 |
| 2018-09 | 16 | 0 |
| 2018-10 | 4 | 0 |

## Current readiness

PostgreSQL import and profiling are complete. Core keys and joins show no observed defects under the inspected definitions, and full-table comparisons matched the CSV inputs. Analytical preparation remains conditional on a documented cutoff and exception policy. Transformed datasets, RFM, cohorts, repeat metrics, and Power BI validation are not complete.

## Next actions

1. Finalize the observation cutoff and eligible population.
2. Document treatment of missing payments/dates and monetary differences.
3. Implement preparation with separate item/payment aggregation and reconciliation.
