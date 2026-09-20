# Runbook

Status: PostgreSQL setup, four-table import, and source profiling completed on September 20, 2026. Full-table comparisons matched the original CSV fields and record counts. Analytical SQL 02-09 and DAX remain placeholders.

## Installed local environment

| Item | Verified configuration |
|---|---|
| PostgreSQL | 18.6, Windows x64; EDB installer 18.6-4 |
| Program directory | `D:\PostgreSQL\18` |
| Database cluster | `D:\PostgreSQL\data\18` |
| pgAdmin | 9.17 at `D:\PostgreSQL\18\pgAdmin 4` |
| pgAdmin application data | `D:\PostgreSQL\private\pgadmin` |
| Windows service | `postgresql-x64-18`, running, automatic startup |
| Host / port | `127.0.0.1` / `5432`; localhost connections |
| Project database | `olist_customer_analytics`, UTF8 |
| Project login / owner | `olist_analyst`, not a superuser |
| pgAdmin registration | `Portfolio` > `Olist Customer Analytics (Local)` |

Open pgAdmin 4 from the Windows Start menu, expand the registered server, select the project database, and open Query Tool. The connection uses a local password file restricted to the Windows user and administrators. Credentials are outside the repository in `D:\PostgreSQL\private`; never copy them into Git. The PostgreSQL administrator and project login have separate generated credentials.

pgAdmin's `config_local.py` sets DATA_DIR on drive D. Windows shortcuts, installer caches, and some desktop runtime preferences can still use standard Windows locations. Record this override when upgrading pgAdmin.

## 1. Reproduce on another machine

Install PostgreSQL Server and pgAdmin using the installer linked by the [PostgreSQL project](https://www.postgresql.org/download/windows/). Choose the program and data directories explicitly. pgAdmin is the management interface; PostgreSQL Server stores and processes the data. StackBuilder packages are unnecessary for this project.

Create a dedicated UTF-8 database and a project login that owns it without superuser privileges. Record installed versions and connection details locally. The connection paths above describe the current workstation, not requirements for every contributor.

## 2. Review the source files

Download the same dataset version into `data/raw/`. Compare file hashes with [SOURCE_PROFILE.json](SOURCE_PROFILE.json), then read the [data instructions](../data/README.md), [dictionary](DATA_DICTIONARY.md), and [quality summary](DATA_QUALITY_SUMMARY.md). Raw CSVs are ignored by Git.

## 3. Create the landing tables

Connect to the project database as its owner and execute [00_setup.sql](../sql/00_setup.sql). It creates raw/analytics/bi schemas, four CSV-compatible landing tables, non-unique indexes, and an analysis configuration row.

Re-running setup preserves data but does not repair schema drift. Observation dates remain NULL until a defensible cutoff is documented.

## 4. Import once

| CSV in data/raw/ | Target | Verified rows |
|---|---|---:|
| olist_customers_dataset.csv | raw.customers | 99,441 |
| olist_orders_dataset.csv | raw.orders | 99,441 |
| olist_order_items_dataset.csv | raw.order_items | 112,650 |
| olist_order_payments_dataset.csv | raw.order_payments | 103,886 |

The completed import used [00_import.psql](../sql/00_import.psql). Run it with psql from the repository root; its relative paths resolve from that working directory. It uses client-side `\copy`, imports all four tables in one transaction, refuses nonempty tables, and verifies expected counts before committing. These are psql commands, so do not paste this file into pgAdmin Query Tool.

Example in PowerShell after configuring a protected local password file:

```powershell
$env:PGPASSFILE = 'D:/PostgreSQL/private/olist.pgpass'
$env:PGCLIENTENCODING = 'UTF8'
try {
    & 'D:/PostgreSQL/18/bin/psql.exe' -X -w -h 127.0.0.1 -p 5432 -U olist_analyst -d olist_customer_analytics -v ON_ERROR_STOP=1 -f sql/00_setup.sql
    if ($LASTEXITCODE -ne 0) { throw 'Setup failed.' }
    & 'D:/PostgreSQL/18/bin/psql.exe' -X -w -h 127.0.0.1 -p 5432 -U olist_analyst -d olist_customer_analytics -v ON_ERROR_STOP=1 -f sql/00_import.psql
    if ($LASTEXITCODE -ne 0) { throw 'Import failed.' }
} finally {
    $env:PGPASSFILE = $null
    $env:PGCLIENTENCODING = $null
}
```

The current workstation is already imported: do not run the import again. To reproduce elsewhere, use your own paths and credentials. A failed import exits and rolls back rather than partially committing data.

As an alternative for a fresh database, use pgAdmin Import/Export Data for each empty raw table: CSV, UTF8, header enabled, comma delimiter, double-quote quote/escape, all columns in verified header order, and empty CSV fields as SQL NULL. Manual imports append rows and do not provide the script's four-table transaction.

References: [pgAdmin Import/Export](https://www.pgadmin.org/docs/pgadmin4/latest/import_export_data.html), [PostgreSQL COPY](https://www.postgresql.org/docs/current/sql-copy.html), and [password files](https://www.postgresql.org/docs/current/libpq-pgpass.html).

## 5. Profile and verify

Run [01_data_overview_and_quality.sql](../sql/01_data_overview_and_quality.sql). The entire file uses a repeatable read-only transaction. In pgAdmin, select complete numbered statements when inspecting individual results. After an error inside an explicit transaction, issue ROLLBACK before retrying.

All profiling sections executed successfully. Local execution logs are in `outputs/tables/postgresql_setup.txt`, `postgresql_import.txt`, and `postgresql_profile.txt`; these are ignored by Git. [DATABASE_VALIDATION.json](DATABASE_VALIDATION.json) publishes aggregate verification evidence only.

Verification compared every source CSV field with PostgreSQL COPY output, in the same column order. Each row was represented as a compact UTF-8 JSON array plus LF; rows were sorted lexicographically and hashed. Matching counts and canonical hashes confirm the imported content. Original source-file hashes were checked before comparison.

The database reproduces the documented missing payments/dates and payment/item differences. These are source exceptions to resolve in the analytical policy, not import failures. See [VALIDATION.md](VALIDATION.md).

## 6. Select analytical boundaries

Review monthly/daily coverage and delivery lag before setting observation dates and writing a cutoff rationale. Do not use October 2018 merely because it contains the last all-status purchase.

Document sparse early history, incomplete late periods, missing dates/payments, and monetary differences. Preserve available earlier history for first-observed/returning classification even when reporting starts later.

## 7. Continue implementation

Prepare and reconcile the order-level dataset, then build customer metrics, RFM, cohorts, repeat windows, and purchase intervals. Add analytical validation checks as outputs appear. Produce reviewed tables and written findings before Power BI views and measures.

## Development and publication

Use main as the reviewed baseline and dev_v1 for implementation. Inspect diffs and staged files before focused commits; review before merging. Never commit raw CSVs, archives, customer-level exports, credentials, or report caches. User-provided chat screenshots must not be uploaded.
