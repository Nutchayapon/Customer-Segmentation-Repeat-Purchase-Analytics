# SQL Execution Guide

All analytical SQL is implemented and executed on PostgreSQL 18.6. Raw imports and analysis are separate steps.

| File | Purpose |
|---|---|
| 00_setup.sql | Schemas, typed landing tables, configuration |
| 00_import.psql | Four-table atomic client-side CSV import; empty-table/count guards |
| 01_data_overview_and_quality.sql | Raw quality, coverage and reconciliation |
| 02_data_preparation.sql | Separate item/payment aggregation, diagnostics, eligible orders, cutoff sensitivity |
| 03_customer_purchase_metrics.sql | Deterministic purchase sequence and customer history |
| 04_rfm_analysis.sql | Raw RFM, thresholds, tied-value-safe scores and segments |
| 05_cohort_analysis.sql | Customer-month activity and observable cohort grid |
| 06_repeat_purchase_analysis.sql | Observed/windowed repeat, common population and distinct-day sensitivity |
| 07_purchase_intervals.sql | Consecutive/first-to-second elapsed gaps and distributions |
| 08_powerbi_views.sql | BI-facing facts, dimensions and aggregate outputs |
| 09_validation.sql | 28 invariant checks; transaction fails if a check fails |
| 10_export_results.psql | Aggregate JSON evidence and ignored local CSV exports |

Files ending in .psql require psql, not pgAdmin Query Tool. Run them from the repository root. All other files run through psql or pgAdmin.

After initial import, run 02 through 10 in order. Use scripts/run_analysis.ps1 for the same sequence. Views are replaced transactionally; raw data is preserved. Configuration dates are seeded only if unset. Re-running is supported for the same schema; CREATE OR REPLACE does not provide arbitrary schema migration.

Inspect analytics.validation_results after validation. Empty datasets, incompatible dates, or new source defects should be investigated rather than bypassing checks. Version-specific source assumptions are documented in Methodology.

Power BI refresh is separate from SQL execution. Aggregate cohort data is intentionally disconnected from customer filters; see the model guide.
