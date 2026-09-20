# Customer Segmentation & Repeat Purchase Analytics

A PostgreSQL and Power BI portfolio project exploring customer purchasing behavior with the Olist Brazilian E-Commerce dataset.

**Status: repository scaffold.** English documentation and comment-only SQL/DAX placeholders are available. Data import, executable analysis, validated findings, and the Power BI report are pending. No analytical results are claimed.

## Business questions

- How many orders do customers place during the observed period?
- Which customers purchased recently, frequently, and with high observed spend?
- What share place a second order within an observable 30, 60, or 90 days?
- How does monthly purchasing activity differ by first-observed-purchase cohort?
- How long are the observed intervals between purchases?
- Which retention hypotheses should be investigated further?

## Dataset

Source: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

The publisher describes orders from 2016–2018. Exact coverage, headers, row counts, and the downloaded version must be checked before analysis. The four planned inputs are customers, orders, order items, and order payments. See [data instructions](data/README.md).

The [publisher metadata](https://www.kaggle.com/olistbr/brazilian-ecommerce/metadata) explains customer identifiers and lists the dataset license as CC BY-NC-SA 4.0. Preserve attribution and confirm the terms for the downloaded version. Dataset terms are separate from any future license for original project code.

## Technology stack

| Tool | Role |
|---|---|
| PostgreSQL | Store data and execute analytical SQL |
| pgAdmin | Manage the database, import CSVs, and run SQL |
| SQL | Prepare data, define metrics, and validate results |
| Power BI | Explore and present validated outputs |
| DAX | Calculate filter-aware measures and presentation logic |
| Git and GitHub | Track changes and publish the portfolio |

No Python pipeline or additional dependency is planned at this stage.

## Planned workflow

1. Define questions, metrics, and assumptions.
2. Import sources and profile quality and coverage.
3. Prepare validated order-level and customer-level datasets.
4. Implement RFM, cohort, repeat-purchase, and purchase-interval analysis.
5. Validate outputs and write evidence-backed findings.
6. Build Power BI pages from reviewed SQL outputs.
7. Finalize the reproduction guide and portfolio.

The first analytical deliverable is validated tables and a written findings document. The dashboard follows that analysis.

## Repository structure

```text
data/                  Source instructions and local raw data
docs/                  Plan, dictionary, methodology, runbook, validation
sql/                   Ordered, comment-only analysis placeholders
outputs/tables/        Local analytical exports; ignored by Git
outputs/figures/       Reviewed charts for publication
reports/               Written analytical findings
powerbi/               Model plan, DAX placeholder, and screenshots
```

## Documentation

- [Project plan](docs/PROJECT_PLAN.md)
- [Data dictionary](docs/DATA_DICTIONARY.md)
- [Methodology and assumptions](docs/METHODOLOGY.md)
- [Setup and execution runbook](docs/RUNBOOK.md)
- [Validation checklist](docs/VALIDATION.md)
- [SQL execution plan](sql/README.md)
- [Analytical findings outline](reports/ANALYSIS_FINDINGS.md)
- [Power BI plan](powerbi/README.md)

## Methodological considerations

Use `customer_unique_id` for customer-level analysis and `customer_id` to join orders to customer records. Aggregate items and payments separately before joining them to orders. Count distinct orders, not items or installments.

Proposed defaults are delivered orders, purchase timestamps, and merchandise value excluding freight. Review these choices against the data. Select observation dates and RFM scoring thresholds after profiling.

A one-time observed customer is not necessarily churned. First observed purchase is not necessarily first-ever purchase. Fixed-window repeat rates require sufficient follow-up, and unobservable cohort periods stay blank rather than appearing as zero activity. Observed spending is not predictive lifetime value.

## Getting started

1. Read the project plan and methodology.
2. Download the four CSVs into `data/raw/` and complete the source inventory.
3. Confirm PostgreSQL and pgAdmin availability.
4. Implement setup and profiling before subsequent analyses.

**SQL and DAX files currently contain comments only. Running them will not create tables or calculate results.** Follow the [runbook](docs/RUNBOOK.md) as implementation progresses.

## Planned deliverables

- Reproducible PostgreSQL scripts and validation checks.
- Order-level and customer-level analytical datasets.
- RFM segments, cohort activity, repeat windows, and purchase intervals.
- Findings that distinguish evidence, interpretation, and hypotheses.
- Power BI report, documented filter behavior, and reviewed screenshots.

## Milestones

- [x] English documentation scaffold and SQL/DAX placeholders
- [ ] Source data acquired and version recorded
- [ ] Database setup, import, and quality review completed
- [ ] Analytical datasets and SQL analyses implemented
- [ ] Results validated and findings written
- [ ] Power BI report reconciled with SQL
- [ ] Portfolio presentation finalized

## Development workflow

Use `main` as the reviewed baseline and `dev_v1` for the first implementation cycle. Make focused commits on `dev_v1` and review changes before merging. Do not commit raw data, customer-level exports, credentials, or Power BI files containing imported data.
