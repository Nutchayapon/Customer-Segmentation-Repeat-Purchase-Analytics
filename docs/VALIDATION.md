# Validation

## Scope and result

**SQL and findings: ready within the documented retrospective scope. Power BI visual acceptance remains pending.**

| Check family | Evidence | Result |
|---|---|---|
| Original CSV inventory and quality | SOURCE_PROFILE.json | Recorded source exceptions |
| PostgreSQL ingestion | DATABASE_VALIDATION.json | Four full-table field comparisons matched |
| SQL analytical invariants | 09_validation.sql; ANALYSIS_RESULTS.json / validation | All 28 passed |
| Independent CSV recomputation | INDEPENDENT_VALIDATION.json | All customer metrics/scores, cohort cells, window rows and interval durations matched |
| Power BI model metadata | Installed Power BI Tabular Object Model deserializer | Model parsed |
| PBIR structure | Microsoft public JSON schemas | All authored schema-bearing files validated |
| Desktop refresh, DAX execution and rendered interactions | Native report session | Not yet verified; see powerbi/README.md |

## Analytical coverage

SQL checks cover order/customer grains, raw item-to-order and customer-to-order reconciliation, valid RFM scores and consistent ties, dates, cohort month 0, unobservable NULL cells, cohort bounds/month indexes, window grain/eligibility, population partition, sequence continuity, interval counts and nonnegative durations.

Independent checks read original CSVs using a separate implementation. They compared every customer's count, spend, first/last/second timestamp and R/F/M scores, all cohort active counts and sizes, each customer's window eligibility/success, and every interval duration. This is a verification helper, not another production analysis pipeline.

The source exceptions are preserved rather than declared resolved. Payment mismatch causes, true acquisition dates, complete follow-up, permanent churn, and campaign effectiveness are not validated by this project.

## Power BI acceptance checklist

- [ ] Enable PBIP/PBIR preview support if required by the installed Desktop version.
- [ ] Connect with local database credentials and refresh all seven model tables.
- [ ] Confirm 87,214 customers, 90,127 orders and BRL 12,382,921.47 in the unfiltered snapshot.
- [ ] Check segment filtering affects snapshot counts/spend and customer-related facts.
- [ ] Check acquisition-month filtering keeps earlier customer identity/history semantics.
- [ ] Check cohort future cells are blank and month-0 omission is intentional.
- [ ] Check the common repeat denominator is 69,406 at 30/60/90 days.
- [ ] Check no-denominator contexts return blank and cohort totals do not sum repeated sizes.
- [ ] Inspect labels, clipping, sorting and every report page at normal zoom.
- [ ] Save reviewed project-generated screenshots; never upload user-provided chat screenshots.

No screenshot or file-format validation is evidence that native DAX queries and rendering have executed successfully.
