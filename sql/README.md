# SQL Execution Plan

Status: setup, import, and profiling executed successfully on PostgreSQL 18.6. Raw tables exist and match their CSV sources. Files 02-09 remain comment-only placeholders; customer analytics have not run.

| File | Planned purpose |
|---|---|
| [00_setup.sql](00_setup.sql) | Prepare CSV-compatible raw tables and analysis configuration. |
| [00_import.psql](00_import.psql) | Import four local CSVs atomically with empty-table and row-count guards (psql only). |
| [01_data_overview_and_quality.sql](01_data_overview_and_quality.sql) | Profile source structure, quality, and observation coverage. |
| [02_data_preparation.sql](02_data_preparation.sql) | Build a validated order-level analytical base. |
| [03_customer_purchase_metrics.sql](03_customer_purchase_metrics.sql) | Summarize customer history and establish purchase sequence. |
| [04_rfm_analysis.sql](04_rfm_analysis.sql) | Calculate raw RFM metrics, scores, and descriptive segments. |
| [05_cohort_analysis.sql](05_cohort_analysis.sql) | Measure monthly purchasing activity by first-observed cohort. |
| [06_repeat_purchase_analysis.sql](06_repeat_purchase_analysis.sql) | Measure observed and fixed-window repeat behavior. |
| [07_purchase_intervals.sql](07_purchase_intervals.sql) | Calculate elapsed time between observed consecutive purchases. |
| [08_powerbi_views.sql](08_powerbi_views.sql) | Expose reviewed analytical outputs for Power BI. |
| [09_validation.sql](09_validation.sql) | Validate analytical invariants and reconciliation throughout implementation. |

## Dependencies

After installing PostgreSQL, run the authored setup script in a dedicated database, import each core CSV once, then run profiling. Finalize observation dates and eligibility before preparing analytical datasets. Customer metrics depend on the validated order base; RFM, cohorts, repeat behavior, and intervals use that shared history.

Run relevant validation checks after each implemented stage, even though the validation file has the highest number. Create Power BI views from reviewed outputs after the analysis is ready. Analytical object names and the final dependency graph remain pending implementation.

## Source baseline and execution

The downloaded version has 99,441 customer records, 99,441 orders, 112,650 item rows, and 103,886 payment entries. See the [quality summary](../docs/DATA_QUALITY_SUMMARY.md) for source exceptions and coverage. These CSV counts also match the imported PostgreSQL tables; see [DATABASE_VALIDATION.json](../docs/DATABASE_VALIDATION.json).

Setup preserves existing rows and does not repair schema drift. Landing tables have non-unique indexes and no PK/FK/NOT NULL constraints so defects can be profiled. The psql import script refuses nonempty tables and rolls back on errors. Manual pgAdmin imports append rows; check empty tables first.

Profiling is read-only. Select complete numbered statements in pgAdmin to inspect/export results. Running the entire file uses one repeatable read-only transaction.

## Conventions

- Use PostgreSQL-compatible SQL and explicit, documented grains.
- Prefer readable CTEs and window functions where appropriate.
- Use one shared population, cutoff, and metric definition.
- Aggregate items/payments before joining; retain exception diagnostics.
- Record parameters and output provenance.
- Do not report a placeholder execution as completed analysis.
