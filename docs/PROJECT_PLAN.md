# Project Plan

Status: scaffold, source acquisition, and CSV inspection completed. Setup/profiling SQL are authored but not executed. Database import and customer analytics remain pending.

## Objective and scope

Build a reproducible customer analytics portfolio using PostgreSQL and Power BI. Produce validated tables and written findings before creating a dashboard. Describe observed behavior without claiming permanent churn, complete lifetime histories, or predictive customer lifetime value.

The initial scope includes customers, orders, items, and payments; customer metrics; RFM; monthly cohort activity; fixed-window repeat purchases; and purchase intervals. Product/category enrichment may follow later. Seller analysis, reviews, geolocation, machine learning, and automated pipelines are outside the initial scope.

## Phases and completion criteria

| Phase | Work | Output | Completion criterion |
|---|---|---|---|
| 1. Scaffold | English documentation, placeholders, Git branches | Organized repository | Links resolve and status statements are accurate |
| 2. Acquire and profile | Record version, inspect headers, import, check quality and coverage | Raw tables and quality summary | Import counts reconcile and exceptions have a documented disposition |
| 3. Prepare | Aggregate items/payments before joining and apply reviewed eligibility | Order and customer datasets | Grains are unique and counts/value reconcile |
| 4. RFM | Calculate raw metrics, inspect distributions, select scores/segments | Customer RFM snapshot | Ties are handled consistently; each customer has one segment |
| 5. Cohorts | First-observed month, monthly activity, observable grid | Cohort activity table | Counts respect cohort size; zero and unobservable differ |
| 6. Repeat behavior | Purchase sequence, windows, and intervals | Repeat rates and gap datasets | Denominators are eligible and sample histories pass review |
| 7. Findings | Validate results and write explanations | Analytical findings document | Every finding has supporting output and material caveats |
| 8. Power BI | Relationships, measures, visuals, slicers | Report and screenshots | KPIs match SQL under documented filters |
| 9. Portfolio | Reproduction guide and final presentation | Shareable repository | Another reader can understand and reproduce the work |

Phases 4-6 depend on validated purchase history from phase 3. Phase 8 follows reviewed findings rather than replacing analysis.

## Planned analytical outputs

| Output | Grain | Purpose |
|---|---|---|
| Order dataset | One eligible order | Common transaction base |
| Customer metrics | One customer | First/last purchase, order count, observed spend |
| RFM snapshot | One customer at a fixed reference date | Descriptive segmentation |
| Customer-month activity | One customer per purchase month | Deduplicated monthly activity |
| Cohort summary | One cohort month and month index | Active customers, cohort size, observability |
| Repeat windows | One customer per 30/60/90-day window | Eligibility and repeat indicators |
| Purchase intervals | One order with a preceding order | Time between observed purchases |

These are proposed outputs; database objects do not exist yet.

## Current milestone

All nine CSVs were acquired and inventoried. Four core files received deeper source checks; see the [quality summary](DATA_QUALITY_SUMMARY.md). Setup/profiling SQL are ready for first execution.

Next: install PostgreSQL Server and pgAdmin, import the four core files, reproduce the profiling baseline, and select a defensible cutoff. Database execution has not occurred. Reconcile the order-level dataset before implementing RFM.

## Definition of done

- Source version, import process, and actual coverage are recorded.
- Populations, grains, date boundaries, and cutoff are explicit.
- PostgreSQL SQL uses readable CTEs and window functions where appropriate.
- Validation includes reconciliation, invariants, and example customer histories.
- Findings distinguish evidence, interpretation, and proposed actions.
- Power BI filter behavior and SQL reconciliation are documented.
- Portfolio claims match completed work and observed results.

## Development workflow

Use main for the reviewed baseline and dev_v1 for implementation. Commit reviewable units such as setup/profiling, preparation, RFM, cohorts, repeat behavior, findings, and Power BI. Review changes before merging into main. Documentation evolves alongside implementation; findings remain empty until supported by results.
