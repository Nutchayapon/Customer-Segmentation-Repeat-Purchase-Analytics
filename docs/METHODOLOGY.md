# Methodology and Assumptions

Status: implemented in SQL 02-09 and checked against the original CSVs. This is a retrospective portfolio study, not a production retention model.

## Decision and source

The audience is a customer analytics or CRM reviewer deciding which purchasing behaviors merit further investigation. Olist version 2 contains observed marketplace orders, not a complete history of customer relationships across all channels. The four core source tables support order/customer behavior; no external CRM, campaign, margin, or churn labels are available.

## Population and observation period

| Rule | Implementation |
|---|---|
| Customer identity | customer_unique_id; join orders to customer records with customer_id |
| Purchase unit | Distinct order_id; separate same-day orders are separate purchases |
| Status | Final recorded delivered status |
| History start | September 4, 2016, preserving all available earlier source history |
| Purchase cutoff | July 31, 2018, inclusive through the end of that calendar day |
| RFM reference | August 1, 2018 |
| Main acquisition cohorts | January 2017 through July 2018 |
| Monetary | Sum of item prices in BRL, excluding freight; not profit, net revenue, or predicted lifetime value |
| Timezone | Source timestamps have no offset; retain their recorded values without inventing a timezone |

August is excluded from the primary snapshot because it is near the extract boundary; the latest delivered purchase is August 29. July gives a full calendar reporting month and additional subsequent source history, but the buffer does not establish complete fulfillment or follow-up. June/July/August sensitivity results are published. September/October all-status purchases do not extend complete delivered-purchase coverage.

Final status can include delivery outcomes learned after the purchase cutoff. This is an explicitly retrospective analysis; it cannot serve as an as-of historical prediction backtest.

Sparse 2016 customers remain in order history, RFM and repeat analysis. Their cohorts are excluded from the main monthly cohort grid, not reclassified as new January 2017 customers. First observed purchase is not necessarily acquisition or first-ever purchase. July is treated as analytically observable under the extract assumption, not proven operationally complete.

## Preparation and exceptions

Items and payments are aggregated independently per order before joining. The diagnostic view retains all source orders and assigns one primary eligibility reason in documented CASE order. Source duplicate keys fail preparation.

Missing customer identity, purchase timestamp, items, or valid nonnegative item prices prevent eligibility. Missing payment rows, missing approval/delivery timestamps and payment mismatches do not exclude an otherwise eligible merchandise purchase. Their flags remain visible. A missing payment is NULL, not a zero payment. Mismatches use abs(payment - merchandise - freight) > BRL 0.01. Causes are unknown; no values are corrected speculatively.

Date eligibility uses the purchase date. Invalid freight/payment totals remain NULL. Raw files and raw tables are not modified by analytical preparation.

## Customer history

One row per customer records first/last purchase, second purchase, distinct order count, merchandise spend, purchase span and available follow-up. Purchase span is last date minus first date; zero is compatible with one order or multiple same-day orders. Follow-up is cutoff date minus first date. Neither is a complete customer lifetime.

Sequence uses purchase timestamp and order_id as a deterministic tie-breaker. The tie-breaker does not establish real chronological order between equal timestamps. Returning orders have a preceding eligible order; repeat customers have at least two orders at the snapshot. Presentation date filters must not erase prior history.

Geography is the state on the first eligible purchase, not a claim about a person's permanent residence.

## RFM scores and segment precedence

Recency is reference date minus last purchase date. Frequency is eligible order count. Monetary is observed merchandise spend.

| Score | Recency days | Frequency |
|---|---|---|
| 5 | 1-30 | 5 or more |
| 4 | 31-60 | 4 |
| 3 | 61-90 | 3 |
| 2 | 91-180 | 2 |
| 1 | Over 180 | 1 |

Monetary thresholds use percentile_disc at 20/40/60/80 percent: BRL 39.90 / 69.90 / 109.90 / 179.90 in this snapshot. Scores 1-4 include their upper boundary; score 5 is above the final boundary. Equal monetary values receive equal scores. Frequency deliberately uses actual purchase counts rather than NTILE, which would split the dominant one-order tie. Group sizes need not be equal.

The following first-match rules cover every customer:

1. Recent high-value repeat: 2+ orders, recency <= 90 days, Monetary score >= 4 (above BRL 109.90 in this snapshot).
2. Recent repeat: remaining customers with 2+ orders and recency <= 90.
3. Less-recent repeat: remaining customers with 2+ orders.
4. Recent one-time: one order and recency <= 90.
5. Older one-time: remaining one-order customers.

These are transparent descriptive thresholds, not optimized campaign rules or validated churn predictions.

## Monthly cohort activity

Assign the first eligible observed purchase month, then deduplicate customer/activity-month pairs. Month index uses calendar year/month differences. Rate = original-cohort customers purchasing in the month / original cohort size.

Month 0 is 100% by definition, not a repeat-purchase rate. Customers may skip months and return. An assumed observable full month with no activity is zero; future/incomplete months are NULL. The primary grid includes month indexes 0-18 for all included cohorts so the unobservable triangle is explicit. The Power BI matrix omits month 0 through its measure to keep later-month rates readable.

Aggregate rates pool active counts and eligible cohort sizes at a single month index. They never average cohort percentages or sum the same cohort denominator over many month indexes. Cohort aggregate visuals are disconnected from customer/segment filters.

## Repeat purchases and windows

Observed repeat rate = customers with 2+ orders / all customers. It is descriptive and has unequal follow-up.

For N in 30, 60, 90, eligibility requires first_purchase_date + N <= cutoff. Success requires a second distinct order dated on or before first_purchase_date + N. These are inclusive calendar-day windows, not exact N*24-hour windows. Ineligible outcomes stay NULL; empty denominators return blank. Same-day orders count.

Window-specific rates have different denominators. A second comparison restricts all three windows to customers with 90 days of follow-up. Distinct-day sensitivity counts customers purchasing on two or more separate dates; it does not replace the primary order definition.

## Purchase intervals

Consecutive elapsed gaps use timestamps and can be fractional days or zero. A customer with k orders contributes k-1 intervals. First-to-second gaps give each observed repeat customer one interval; all consecutive gaps give frequent buyers more weight.

Both distributions are conditional on repeat purchases observed before the cutoff. Customers without an observed repeat are not assigned a zero gap, and their eventual waiting times are censored. Observed medians are not an unbiased time-to-return estimate for all customers.

## SQL and DAX ownership

SQL defines populations, histories, RFM, cohorts, repeat flags, interval durations and bins. DAX aggregates those outputs under filters and uses DIVIDE for safe ratios. Customer snapshot metrics respond to acquisition/segment filters; activity dates filter Orders, not snapshot membership. Recomputing a truly dynamic RFM snapshot requires new SQL outputs.

All recommendations are hypotheses. Campaign lift, optimal timing, profit and permanent churn cannot be established from these tables.
