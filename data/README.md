# Source Data

Status: all nine original CSVs downloaded and inspected locally. The four core files have additional quality checks. The four core CSVs were imported into PostgreSQL and verified; see [DATABASE_VALIDATION.json](../docs/DATABASE_VALIDATION.json).

## Source and retrieval

- Publisher: Olist.
- Dataset: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).
- Kaggle API version reported: 2.
- Download completed (UTC): 2026-09-20T11:50:23.129726+00:00.
- Publisher metadata last updated: 2021-10-01T19:08:27.97Z. This is publication metadata, not transaction freshness.
- Dataset license: CC BY-NC-SA 4.0.
- Archive size: 44,717,580 bytes.
- SHA-256 hashes, original headers, and aggregate evidence: [Source profile](../docs/SOURCE_PROFILE.json).
- Inspection findings: [Data quality summary](../docs/DATA_QUALITY_SUMMARY.md).

All files were obtained from the original publisher. No source values were changed. The expanded CSV byte total matches the publisher metadata (126,186,995 bytes).

## Full inventory

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

These are CSV-aware record counts, not text line counts. Review text may contain embedded newlines.

## First PostgreSQL import

| CSV | Target table | Expected records |
|---|---|---:|
| olist_customers_dataset.csv | raw.customers | 99,441 |
| olist_orders_dataset.csv | raw.orders | 99,441 |
| olist_order_items_dataset.csv | raw.order_items | 112,650 |
| olist_order_payments_dataset.csv | raw.order_payments | 103,886 |

The other five source files are retained locally for understanding and possible later enrichment. They are not required for the initial RFM, cohort, repeat-purchase, and purchase-interval calculations. Payments support reconciliation; item prices define the proposed merchandise-based Monetary metric.

## Storage and reproduction

- data/raw/: original CSVs, archive, and retrieved metadata; ignored by Git.
- outputs/tables/: local inspection helper and aggregate inspection output, plus future SQL exports; ignored by Git.
- data/exports/: preserved legacy export folder; use outputs/tables/ for new exports.
- outputs/figures/: reviewed charts generated for this project.
- User-provided chat screenshots are not repository assets and must not be uploaded.

For a fresh checkout, download the same version from the source page, extract the files into data/raw/, compare SHA-256 hashes with the source profile, then follow the [runbook](../docs/RUNBOOK.md). Import only once into empty landing tables.
