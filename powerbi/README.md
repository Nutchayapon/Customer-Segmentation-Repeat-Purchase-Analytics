# Power BI Plan

Status: report not built. DAX contains comments only. Validate SQL outputs and write findings before dashboard authoring.

## Proposed pages

| Page | Planned content | Question |
|---|---|---|
| Customer overview | Customer/order counts, observed merchandise value, repeat rate, purchase-count distribution | How do customers purchase within observed history? |
| RFM segmentation | Segment counts/shares, spend, raw-metric summaries | Which groups are recent, frequent, and high-spending? |
| Cohort activity | Heatmap, cohort sizes, observable periods, selected cohort curves | How does monthly purchasing activity differ? |
| Repeat behavior | 30/60/90-day rates and eligible counts, gap histogram, time to second purchase | When do observed repurchases occur? |

## Proposed model

- Customer dimension: one row per customer_unique_id.
- Date dimension: one row per date.
- Orders fact: one row per eligible order.
- RFM snapshot: one row per customer at a fixed reference date.
- Customer-month activity: one row per customer per purchase month.
- Repeat windows: one row per customer per follow-up window.
- Purchase intervals: one row per order with a preceding order.
- Cohort summary: one row per cohort month and month index.

Use validated unique dimension keys and deliberate one-to-many relationships. Avoid ambiguous fact-to-fact paths. Keep aggregate cohort outputs separate where needed and document supported filters. Exact views, relationships, connection mode, and refresh settings are pending implementation.

## SQL and DAX responsibilities

SQL defines eligibility, history, segmentation, cohort membership, and repeat flags. DAX aggregates reviewed results in the documented filter context, supplies safe ratios, and controls presentation.

- Pair window rates with eligible customer counts.
- Return blank for an empty denominator.
- Do not average percentages when a ratio of counts is required.
- Do not sum cohort_size repeatedly across month indexes.
- Distinguish acquisition-period and activity-period filters.
- Preserve prior history used to identify returning purchases.
- Label RFM with its fixed reference date.
- Define geography attribution before enabling geography filters.

## Validation and publication

Reconcile totals and representative slices with SQL, including empty populations. Check heatmap blanks, labels, and date roles. Put reviewed screenshots in screenshots/ and link them from the main README when available.

PBIX/PBIT files and caches stay local at this stage. A distributable report format is a later decision; screenshots and measures alone do not imply a complete report file is available.
