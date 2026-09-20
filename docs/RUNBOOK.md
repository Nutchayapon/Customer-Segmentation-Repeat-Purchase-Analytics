# Runbook

Status: all nine CSVs are available locally and source-file inspection is complete. Setup and profiling SQL are authored but have not been executed. PostgreSQL/pgAdmin are not installed in this workflow; no installation was performed. Later SQL/DAX files remain placeholders.

## 1. Install the database tools when ready

For Windows, use the installer linked by the [PostgreSQL project](https://www.postgresql.org/download/windows/). It includes PostgreSQL Server and pgAdmin. The server stores/processes data; pgAdmin is the management interface. Installing pgAdmin alone does not provide a database server.

Record the stable PostgreSQL version, pgAdmin version, local port, and installation date. Keep credentials outside Git. No additional StackBuilder packages are required at this stage. Installation is a separate, pending step.

## 2. Review the source files

A fresh checkout needs its own local download because raw data is ignored by Git. Read [data instructions](../data/README.md), [data dictionary](DATA_DICTIONARY.md), and [quality summary](DATA_QUALITY_SUMMARY.md). Compare file hashes with [SOURCE_PROFILE.json](SOURCE_PROFILE.json).

## 3. Create an empty project database

In pgAdmin, connect to the local server and create a dedicated UTF-8 database, for example olist_customer_analytics. This is a proposed name, not an existing database.

Open Query Tool for that database and execute [00_setup.sql](../sql/00_setup.sql). It creates raw/analytics/bi schemas, four landing tables, non-unique indexes, and a configuration row with NULL observation dates.

Inspect the returned columns before importing. Re-running setup preserves rows but does not repair incompatible schemas. Do not use an unrelated database.

## 4. Import the four core CSVs

For each target table, open pgAdmin's Import/Export Data dialog and select Import.

| CSV in data/raw/ | Target table | Expected records |
|---|---|---:|
| olist_customers_dataset.csv | raw.customers | 99,441 |
| olist_orders_dataset.csv | raw.orders | 99,441 |
| olist_order_items_dataset.csv | raw.order_items | 112,650 |
| olist_order_payments_dataset.csv | raw.order_payments | 103,886 |

Settings:

- Format: CSV; encoding: UTF8; header: enabled.
- Delimiter: comma; quote and escape: double quote.
- Keep all columns in the verified source-header order.
- Use the CSV empty-field NULL representation; empty timestamps must become SQL NULL.
- Keep error handling at stop when available; do not silently discard malformed rows.
- Inspect completion/process output and the imported count.

The four CSV headers match the landing-table column order. UTF-8 decoding and inspected value types passed local checks; still verify import counts.

Import once into an empty target table. Imports append rows. If an attempt fails, inspect its transaction/process result and table counts before retrying. Do not clear existing tables without an explicit reload plan.

If a file is inaccessible, check the path used by the import process. Server-side COPY uses server filesystem permissions; server and client paths are not interchangeable.

References: [pgAdmin Import/Export Data](https://www.pgadmin.org/docs/pgadmin4/latest/import_export_data.html) and [PostgreSQL COPY](https://www.postgresql.org/docs/current/sql-copy.html).

## 5. Reproduce source checks in PostgreSQL

Run the numbered queries in [01_data_overview_and_quality.sql](../sql/01_data_overview_and_quality.sql). Select one complete numbered statement at a time to inspect/export results in pgAdmin. The full file uses a repeatable read-only transaction.

Compare with this CSV baseline:

- 0 duplicate groups or blank expected keys in each core file.
- 0 orders without customer and 0 item/payment entries without order.
- 775 orders without items; none are delivered.
- 1 delivered order without a payment entry.
- 8 delivered orders without delivery timestamp; 14 without approval timestamp.
- 299 delivered matched orders with payment versus merchandise-plus-freight difference greater than BRL 0.01.

These are source-file findings, not completed database tests. Record execution outcomes in [VALIDATION.md](VALIDATION.md). Resolve import differences before interpreting subsequent results.

If a statement fails inside the explicit transaction, use ROLLBACK to end that failed transaction, investigate, then rerun the corrected check.

## 6. Select analytical boundaries

Review monthly/daily coverage and delivery lag before choosing observation dates and writing a cutoff rationale. Dates intentionally remain NULL. Do not use October 2018 simply because it contains the last all-status purchase.

Decide how to handle sparse early history, incomplete late periods, missing dates/payments, and monetary differences. Preserve available earlier history for first-observed/returning classification even when reporting starts later.

## 7. Continue implementation

Implement preparation and customer history, followed by RFM/cohorts/repeat windows/intervals. Add checks in 09_validation.sql as outputs appear. Produce reviewed tables and written findings before Power BI views/measures.

## Development and publication

Use main as the reviewed baseline and dev_v1 for implementation. Inspect diffs and staged files before focused commits. Review before merging.

Do not commit raw CSVs, archives, customer-level exports, credentials, or report caches. User-provided chat screenshots must not be uploaded; reviewed project-generated charts are a separate future deliverable.

## Pending runtime record

| Item | Status |
|---|---|
| PostgreSQL and pgAdmin versions | Not installed/recorded |
| Database name and connection | Proposed only |
| Setup execution | Not executed |
| CSV import | Not executed |
| Profiling SQL execution | Not executed |
| Observation dates/rationale | Not selected |
