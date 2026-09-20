# Source Data

Status: source CSVs have not been acquired or inspected in this workspace.

## Required files

Download the original [Olist dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) and place these unmodified files in data/raw/:

| File | Planned use |
|---|---|
| olist_customers_dataset.csv | Order-to-customer mapping and location |
| olist_orders_dataset.csv | Order identifiers, timestamps, and status |
| olist_order_items_dataset.csv | Merchandise and freight amounts |
| olist_order_payments_dataset.csv | Payment totals and reconciliation |

Access may depend on Kaggle account permissions. Do not store authentication details in the repository. Products and category translation are optional future additions.

## Source inventory

| Field | Recorded value |
|---|---|
| Publisher | Olist |
| Dataset version | Pending download |
| Download date | Pending download |
| Filenames and sizes | Pending inspection |
| Header and encoding checks | Pending inspection |
| CSV record counts | Pending inspection |
| Purchase timestamp coverage | Pending profiling |
| License for downloaded version | Pending confirmation; publisher metadata lists CC BY-NC-SA 4.0 |

Retain dataset attribution. Verify CSV record counts using a CSV-aware method or checked import, not plain text line counts when fields can contain embedded newlines.

## Storage conventions

- data/raw/: original source CSVs, ignored by Git.
- outputs/tables/: future analytical exports for local verification, ignored by Git.
- data/exports/: preserved legacy export directory; use outputs/tables/ for new exports.
- outputs/figures/: reviewed charts suitable for the portfolio.

Only documentation and placeholders are tracked here. No dataset is redistributed.
