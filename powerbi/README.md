# Power BI Project

Status: semantic model, DAX and four PBIR report pages are authored. The model parsed with the installed Power BI Tabular Object Model; 40 schema-bearing PBIR documents passed Microsoft's public JSON schemas. **Native refresh, DAX execution and rendered interaction checks are not yet verified.**

## Open and refresh

1. Start Power BI Desktop and open Olist.pbip in this folder.
2. If required, enable Power BI Project/PBIP and enhanced report format/PBIR in File > Options and settings > Options > Preview features, then restart Desktop. The locally installed Desktop is 2.136.1202.0; use a compatible supported Desktop release if it rejects the project format.
3. The model connects to PostgreSQL at 127.0.0.1:5432, database olist_customer_analytics, schema bi.
4. Select Database authentication and the local project login olist_analyst. Enter its password through Desktop's credential prompt; do not put a password in M, DAX or model.bim.
5. Choose Refresh, then complete the checklist in docs/VALIDATION.md.
6. Save locally after checking results. Imported data/cache files are ignored by Git.

The connection address is editable in the seven M partitions in Olist.SemanticModel/model.bim. Another workstation needs its own PostgreSQL database and credentials.

On the original workstation the generated analyst credential is protected with Windows DPAPI at D:\PostgreSQL\private\olist-analyst-password.dpapi. It is available only in the appropriate local Windows context; see the local credential instructions in the runbook. The final field of the protected local D:/PostgreSQL/private/olist.pgpass file also contains that login's password. Read it only locally when entering Desktop credentials. Neither private file is a project asset.

## Pages

| Page | Authored content | Filter contract |
|---|---|---|
| Customer overview | Four KPIs, monthly order trend, frequency distribution, acquisition-month slicer | Acquisition selection filters customers and their full eligible order histories |
| RFM segmentation | Segment slicer, customer/spend bars, recency/frequency/median value table | Segment filters customer-related facts |
| Cohort purchasing activity | Cohort selector, month-index matrix, original cohort sizes | Disconnected aggregate; only cohort/month-index filters |
| Repeat purchase behavior | 90-day KPI, conditional median to second order, paired repeat-rate bars, interval distribution, denominator table | All-snapshot analysis; interval distribution is a disconnected aggregate |

The static heatmap/figures in outputs/figures are SQL-backed portfolio figures, not screenshots of a rendered Power BI session.

## Semantic model

| Table | Source view | Grain |
|---|---|---|
| Customers | bi.customers | One customer at a fixed RFM snapshot |
| Orders | bi.orders | One eligible order with preserved purchase sequence |
| RepeatWindows | bi.repeat_windows | One customer per 30/60/90-day window |
| Intervals | bi.purchase_intervals | One order with a preceding eligible order |
| Dates | bi.dates | One calendar date |
| Cohort | bi.cohort_activity | One cohort/month-index cell |
| GapDistribution | bi.interval_distribution | One interval bucket, all snapshot customers |

Relationships use single-direction filters: Customers 1:* Orders, RepeatWindows and Intervals; Dates 1:* Orders. Cohort and GapDistribution are deliberately disconnected.

Dates filters activity orders only; they do not recompute RFM or redefine the customer snapshot. Customer geography is the first eligible purchase state. No global geography/segment slicer is presented for the disconnected cohort/interval summaries.

## Measures and display

measures.dax mirrors the semantic model measures. SQL owns all behavioral definitions; DAX owns aggregation, filtering and safe division.

- Window measures return blank without one selected window.
- Common-window rates all use customers with at least 90 days of follow-up.
- Cohort denominators count each cohort once and include only observable cohorts at the selected month index.
- Later Month Activity Rate hides month 0 (100% by definition).
- Median intervals are conditional on observed repeat purchases; no zero gap is assigned to customers without a repeat.
- Snapshot Orders and Observed Merchandise Value aggregate Customers; activity-period measures aggregate Orders.
- GapDistribution does not respond to customer slicers. Its title explicitly states its all-snapshot scope.

## Unfiltered acceptance values

Customers 87,214; Snapshot Orders 90,127; merchandise BRL 12,382,921.47; observed repeat rate 3.0053%; 90-day repeat rate 2.3442%; median days to second order 26.0107. Compare table denominators with docs/ANALYSIS_RESULTS.json.

## Format references

- [Microsoft PBIP overview](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-overview)
- [PBIR report format and schemas](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-report)
- [Semantic model project folder](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-dataset)

Public metadata formats make the project reviewable in Git. Successful parsing/schema validation does not replace Desktop acceptance.
