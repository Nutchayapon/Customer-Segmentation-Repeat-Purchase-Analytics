# Methodology and Assumptions

Status: proposed design informed by the completed [CSV quality review](DATA_QUALITY_SUMMARY.md). Customer analytics and PostgreSQL execution are pending. Observation dates and scoring thresholds remain unset.

## Population and period

| Topic | Proposed choice | Pending review |
|---|---|---|
| Customer key | customer_unique_id | Missing IDs and mapping consistency |
| Purchase unit | Distinct order_id | Duplicates and same-day orders |
| Eligible status | Delivered | Status mix and excluded counts |
| Purchase time | order_purchase_timestamp | Parsing, missing values, coverage |
| Monetary | Item prices excluding freight, in BRL | Missing values and reconciliation |
| RFM history | All eligible observed orders through cutoff | Actual coverage and boundary policy |
| RFM reference date | Observation end date + one day | Fixed date after profiling |

Record observation_start, observation_end, and the cutoff rationale after profiling. Do not use the current date for historical RFM. Inspect daily/monthly coverage, partial boundary months, and delivery lag: the maximum timestamp alone does not establish complete coverage.

Delivered status in a static extract reflects the recorded outcome. Moving the cutoff backward while using that status includes later knowledge. The initial analysis is a retrospective snapshot, not a historical backtest. Assess end-of-extract delivery bias and document any maturity buffer or cutoff sensitivity check.

Earlier and future purchases may be unobserved. First observed purchase is not necessarily acquisition or first-ever purchase. One-time observed customers are not permanently churned.

## Data preparation

Aggregate items and payments independently by order_id, then join to orders and customers. Preserve diagnostics for missing matches before filtering. Document exclusions instead of silently dropping records or treating unknown values as zero.

Keep merchandise, freight, and payments separate. Investigate differences between payment totals and merchandise plus freight. Merchandise value is neither profit nor confirmed net revenue after returns, and it is not predictive lifetime value.

## Customer metrics and RFM

Produce one row per customer with first/last eligible purchase, distinct order count, observed spend, and purchase span. Span is last purchase date minus first purchase date; zero does not mean the customer relationship ended.

- Recency: days from last eligible purchase date to the fixed reference date; lower is more recent.
- Frequency: distinct eligible orders within observed history.
- Monetary: eligible merchandise value over the same history.

Keep raw metrics beside scores/labels. Inspect distributions before choosing thresholds. Equal values should receive equal scores. Do not blindly use NTILE for tied frequencies. Buckets need not have equal sizes or populate all possible scores.

Candidate groups are recent one-time, older one-time, recent repeat, high-value repeat, and less-recent repeat. These are ideas, not finalized rules. Document threshold boundaries and CASE precedence so every included customer has one segment. Avoid unsupported churn labels.

## Cohort purchasing activity

Assign each customer to their first observed eligible purchase month. Deduplicate customer-by-purchase-month activity. Calculate month indexes using calendar year/month differences, not days divided by 30.

Monthly activity rate = distinct original-cohort customers purchasing in the activity month / original cohort customers.

- Month 0 is a definition-based baseline, not a repeat-purchase rate.
- Customers may skip months and return; this is not continuous retention.
- Fully observable months without activity are zero.
- Future or incomplete months remain NULL/blank.
- Partial acquisition months must be excluded or separately labeled under an explicit policy.
- Second orders in month 0 still count in repeat-purchase analysis.

## Repeat purchases

| Metric | Definition | Limitation |
|---|---|---|
| Observed repeat customer rate | Customers with 2+ orders / customers with 1+ order | Unequal follow-up; descriptive context |
| N-day repeat rate | Eligible customers with second order within N days / eligible customers | N = 30, 60, 90; display eligible counts |
| Purchases per customer | Distinct eligible orders / observed customers | Pair with count distribution |
| Time to second purchase | Second timestamp minus first timestamp | Conditional on observing a second order |
| Consecutive purchase interval | Order timestamp minus preceding timestamp | Frequent buyers contribute more intervals |

Proposed day-window boundaries: eligible when first_purchase_date + N days <= observation_end. Success requires a second distinct order with second_purchase_date <= first_purchase_date + N days. Ineligible indicators stay NULL, not false. A zero denominator yields a blank rate.

Distinct orders on the same day count separately in the primary definition; inspect these cases. Sequence by purchase timestamp and order_id for reproducible ordering. Equal timestamps can yield zero intervals. Retain and flag them unless evidence supports an exclusion rule. Timestamp intervals may contain fractional days.

Denominators may differ across 30/60/90-day rates. A direct same-population comparison can instead use customers with at least 90 days of follow-up for all three rates; label the population explicitly.

Distinguish a repeat customer at the snapshot (2+ observed orders) from an order by a returning customer (a preceding eligible order exists). Date filters must not erase history needed for the latter classification.

## SQL and DAX

SQL owns eligibility, history, RFM rules, cohort membership, repeat flags, and intervals. Prefer readable CTEs and window functions where appropriate. DAX owns filter-aware aggregation, safe ratios, shares, and display. Do not duplicate segmentation/cohort logic in DAX or average group percentages when a ratio of counts is required.

RFM remains a fixed snapshot unless a separate multi-snapshot design is implemented. Acquisition-date and activity-date filters have distinct roles; activity filters must not redefine cohort membership or shrink its original denominator.

If geography is added, distinguish order delivery location from customer/cohort location. First-observed-purchase location is a proposed convention for cohort slicing. Decide and document one convention before implementation.

## Interpretation

Describe observed differences without claiming causality. Link recommendations to evidence, a plausible mechanism, limitations, and a proposed test. Do not set business targets or claim an intervention works without evidence.

## Confirmed source evidence and pending decisions

- Version 2 and source timestamp ranges are recorded in [SOURCE_PROFILE.json](SOURCE_PROFILE.json). These ranges do not establish complete follow-up.
- Review missing-payment/date and monetary reconciliation exceptions before transformation.
- Order eligibility and exception handling.
- Monetary definition and reconciliation policy.
- Observation cutoff, reference date, and delivery maturity policy.
- RFM thresholds, ties, and segment precedence.
- Partial-month handling and BI filter/geography conventions.
