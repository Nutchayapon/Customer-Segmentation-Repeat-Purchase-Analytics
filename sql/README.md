# SQL Execution Plan

Status: all SQL files are comment-only placeholders. No tables, views, metrics, or results have been implemented.

| File | Planned purpose |
|---|---|
| [00_setup.sql](00_setup.sql) | Prepare CSV-compatible raw tables and analysis configuration. |
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

Implement setup first, import the CSVs, then implement profiling. Finalize observation dates and eligibility before preparing analytical datasets. Customer metrics depend on the validated order base; RFM, cohorts, repeat behavior, and intervals use that shared history.

Run relevant validation checks after each implemented stage, even though the validation file has the highest number. Create Power BI views from reviewed outputs after the analysis is ready. Database object names and the final dependency graph remain pending implementation.

## Conventions

- Use PostgreSQL-compatible SQL and explicit, documented grains.
- Prefer readable CTEs and window functions where appropriate.
- Use one shared population, cutoff, and metric definition.
- Aggregate items/payments before joining; retain exception diagnostics.
- Record parameters and output provenance.
- Do not report a placeholder execution as completed analysis.
