# Portfolio Figures

These are project-generated static figures from the reviewed PostgreSQL aggregate outputs, not Power BI screenshots and not user-provided chat images.

| Figure | Evidence section in docs/ANALYSIS_RESULTS.json |
|---|---|
| rfm_segments.png | segments |
| repeat_windows.png | repeat |
| cohort_activity.png | cohorts |
| purchase_intervals.png | interval_distribution and interval_caveats |

Each image states its population or key limitations. Cohort values are percentages, month 0 is omitted, and future cells are dashes rather than zero. Interval bins are ordered categorical counts with unequal widths, not a probability density histogram. All four images were visually inspected for labels, clipping, values and scale.

The figures represent the July 31, 2018 snapshot. Regenerate/review them after changing definitions or dates; running SQL does not automatically update images or written findings.
