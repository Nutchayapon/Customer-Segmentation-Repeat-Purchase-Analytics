# Project Plan and Delivery Status

## Objective

A reproducible SQL and Power BI portfolio analyzing customer segmentation and observed repeat purchasing. Source data, customer histories and screenshots supplied in chat stay outside Git.

## Delivered work

| Stage | Output | Status |
|---|---|---|
| Source acquisition and inspection | Nine local CSVs, source profile, dictionary | Complete |
| Database setup/import | PostgreSQL 18.6, four raw tables, verified field fingerprints | Complete |
| Methodology | Cutoff, eligibility, monetary, RFM, cohort and repeat definitions | Complete with documented limitations |
| Order/customer preparation | Diagnostic, order, customer and sequence views | Executed |
| RFM | Raw metrics, tied-value-safe scores, five descriptive groups | Executed |
| Cohorts | Customer-month activity and explicit observable grid | Executed |
| Repeat behavior | Order counts, 30/60/90-day rates, common population, distinct-day sensitivity | Executed |
| Purchase intervals | Consecutive/first-to-second gaps and distribution summaries | Executed |
| Validation | 28 SQL invariants and full-population independent CSV comparisons | Passed |
| Findings | Evidence-backed English narrative and testable recommendations | Complete |
| Power BI | Seven-table semantic model, DAX, four PBIR report pages | Authored; Desktop refresh/render acceptance pending |
| Portfolio | English README, reproduction scripts, documentation, aggregate evidence | Prepared on dev_v1 |

The remaining acceptance step is Power BI Desktop refresh with local database credentials, followed by checking the rendered visuals and representative filters against SQL. Do not label this as completed visual validation.

## Sequence and maintenance

Run SQL 02-09 after the existing setup/import; run 10_export_results.psql to refresh aggregate evidence and ignored local CSV exports. The PowerShell runner performs this sequence with stop-on-error behavior. Refresh Power BI separately.

The configuration row stores observation boundaries. SQL 02 seeds the documented dates only when they are unset. Changing the period requires reviewing cohort policy, RFM thresholds, sensitivity candidates, findings and evidence; do not retain the published narrative unchanged.

Review dev_v1 before merging into main. No automatic merge or public deployment is included.
