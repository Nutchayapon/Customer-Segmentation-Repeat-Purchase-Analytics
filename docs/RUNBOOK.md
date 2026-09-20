# Runbook

Status: future execution outline. SQL/DAX files contain comments only. Steps become executable as the scripts are implemented.

## Prerequisites

Access to original Olist CSVs, PostgreSQL, pgAdmin, Git, and later Power BI Desktop. Record actual versions during setup. Keep credentials local. No extra package installation is required by this scaffold.

## Development workflow

Use the existing project directory as the repository root. main is the reviewed baseline; dev_v1 is the first development branch.

Check `git status` and `git branch --show-current` before editing. Implement on dev_v1. Inspect `git diff` and staged files before focused commits. Review changes before merging into main.

Remote: https://github.com/Nutchayapon/Customer-Segmentation-Repeat-Purchase-Analytics

## Planned execution

1. Download the four CSVs listed in [data instructions](../data/README.md).
2. Place originals in data/raw/ and complete the source inventory.
3. Verify headers, encoding, numeric/timestamp formats, and key fields.
4. Implement 00_setup.sql with CSV-compatible raw tables and proposed raw/analytics/bi schemas. Record database name and parameters.
5. Create the local database and run the implemented setup script.
6. Import CSVs through pgAdmin using verified header, delimiter, encoding, and null settings. Record counts and errors.
7. Implement/run 01_data_overview_and_quality.sql and document exceptions.
8. Review coverage and select observation dates with an explicit rationale.
9. Implement/run files 02 through 07 in order, validating each output before proceeding.
10. Implement/run 09_validation.sql as objects become available; validation is a continuing gate, not only an end-stage check.
11. Export reviewed tables to outputs/tables/ and write analytical findings.
12. Implement 08_powerbi_views.sql, connect Power BI to the reviewed PostgreSQL views, and document connection mode/refresh.
13. Reconcile Power BI with SQL and review screenshots before publication.

An empty execution of a comment-only placeholder does not establish successful setup. Database names, DDL, import settings, parameter values, and connection details are pending implementation.

## Evidence and exports

Record the SQL file, parameters, grain, and validation status for each analytical output. Keep raw and customer-level exports local. Publish reviewed aggregate evidence and charts after validation.

## Reproduction details to complete

- Software versions and database/schema names.
- Dataset version, file checks, and exact import settings.
- Script dependencies, rerun behavior, and parameter values.
- Timestamp/date conventions and validation exceptions.
- Power BI relationships, measures, connection, and refresh steps.
