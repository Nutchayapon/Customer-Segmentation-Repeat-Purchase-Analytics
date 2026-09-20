# Validation Checklist

Status: all data and analytical checks are pending. No execution results are implied.

Record the date, SQL/output reference, expected condition, actual result, and exceptions when each check is performed.

## Source and preparation

- [ ] Dataset version, filenames, attribution, and coverage are recorded.
- [ ] Imported record counts reconcile with source CSVs.
- [ ] Headers, encoding, and numeric/timestamp formats are verified.
- [ ] Key nulls, duplicates, and missing join matches are measured.
- [ ] Status distribution, boundary months, and delivery maturity are reviewed.
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
| Data and analytical validation | Pending implementation | See checklist | Not executed | Pending |
