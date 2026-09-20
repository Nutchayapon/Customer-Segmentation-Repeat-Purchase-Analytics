# Validation Checklist

Status: source inspection, PostgreSQL setup/import, and database profiling completed on September 20, 2026. Analytical transformation and customer-analysis checks remain pending.

Record the date, SQL/output reference, expected condition, actual result, and exceptions when each check is performed.

## Completed source-file inspection

- [x] Nine CSVs inventoried with version, headers, counts, sizes, and hashes.
- [x] Four core files checked for keys, relationships, dates, and numeric fields.
- [x] Coverage and source exceptions documented in [DATA_QUALITY_SUMMARY.md](DATA_QUALITY_SUMMARY.md).
- [x] Aggregate evidence preserved in [SOURCE_PROFILE.json](SOURCE_PROFILE.json).
- [x] Execute profiling in PostgreSQL and compare imported data with source files.

The original source snapshot used local standard-library CSV inspection. Subsequent PostgreSQL execution is recorded separately in [DATABASE_VALIDATION.json](DATABASE_VALIDATION.json). Four full-table comparisons verified every imported field, including textual identifiers, accents, timestamp NULLs, and numeric values. This verifies ingestion, not customer-analysis correctness.

## Database source and preparation checks

- [x] Dataset version, filenames, attribution, and coverage are recorded.
- [x] Imported record counts and full-table field fingerprints reconcile with source CSVs.
- [x] Headers, UTF-8 encoding, and numeric/timestamp formats are verified.
- [x] Key nulls, duplicates, and missing join matches are measured.
- [x] Status distribution, boundary months, and delivery lag are profiled; cutoff remains unset.
- [ ] Items/payments are separately aggregated before joining.
- [ ] Each eligible order has one row in the prepared dataset.
- [ ] Counts match the documented eligible population.
- [ ] Merchandise totals reconcile to eligible source items.
- [ ] Payment/freight differences and exclusions are explained.
- [ ] Customer order counts and spend sum to eligible order totals.

## RFM and cohorts

- [ ] Reference date and observed history are fixed and recorded.
- [ ] Equal metric values receive equal scores under documented boundaries.
- [ ] Each customer has one segment per snapshot and one cohort.
- [ ] Customers appear at most once per activity month.
- [ ] Active customers never exceed cohort size.
- [ ] Month 0 has the expected baseline for included cohorts.
- [ ] Observable empty cells are zero; unobservable cells are NULL.
- [ ] Partial acquisition months follow the agreed policy.

## Repeat behavior and intervals

- [ ] One-time plus repeat customers equals all customers in the same scope.
- [ ] Repeat successes never exceed eligible customers.
- [ ] Insufficient follow-up yields NULL, not a failed repeat.
- [ ] Exact day-window boundaries and empty denominators are checked.
- [ ] A customer with k orders has k - 1 consecutive intervals.
- [ ] Intervals are nonnegative under the documented ordering.
- [ ] First-to-second and all-pair summaries state their populations.

## Sample customer histories

- [ ] One-order customer and customer with multiple orders.
- [ ] Orders on the same day or timestamp.
- [ ] Customer near the cutoff or without sufficient follow-up.
- [ ] Order with missing/unmatched/exceptional source values.

## Power BI and publication

- [ ] Keys support intended fact/dimension relationships.
- [ ] Totals and representative filtered slices match SQL.
- [ ] Cohort size is not summed repeatedly across month indexes.
- [ ] Date filters preserve prior history and eligibility semantics.
- [ ] RFM displays its fixed snapshot date.
- [ ] Findings have supporting reviewed evidence.
- [ ] Recommendations are distinguished from causal claims.
- [ ] Staged files exclude raw/customer exports and credentials.

## Execution record

| Check | Evidence | Expected result | Actual result | Status |
|---|---|---|---|---|
| CSV inventory and core profiling | SOURCE_PROFILE.json and DATA_QUALITY_SUMMARY.md | Inspect scope and quantify exceptions | Completed with documented issues | Source inspection complete |
| PostgreSQL setup/import/profiling | SQL 00, 00_import.psql, SQL 01; DATABASE_VALIDATION.json | Match source baseline | Four table counts and all field fingerprints match; profiling completed | Passed on PostgreSQL 18.6 |
| Duplicate import guard | 00_import.psql; DATABASE_VALIDATION.json | Reject without adding rows | Expected exception; all counts unchanged | Passed |
| Transformed/customer analysis | Later SQL placeholders | See checklist | Not executed | Pending |
