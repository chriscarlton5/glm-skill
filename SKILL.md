---
name: actuarial-glm-model
description: Build reproducible actuarial Generalized Linear Models for P&C pricing. Use for frequency, severity, loss cost, pure premium, rate indication support, rating factor relativities, GLM diagnostics, leakage screening, actuarial model documentation, or Excel review exhibits. Defaults to R-first workflows with exposure offsets, holdout validation, regulatory/fairness review, reusable scoring transformations, and filing-ready documentation.
---

# Actuarial GLM Model Builder

## Operating Mode

Use this skill for P&C pricing GLMs. The supported v1 targets are frequency, severity, loss cost, and Tweedie pure premium. For reserving, retention, conversion, life/health, or mortality work, explain that this skill is pricing-focused and adapt only after documenting the changed target, exposure basis, and validation requirements.

Proceed autonomously when the user asks for an end-to-end model. Stop only when a hard gate is missing or contradictory:

- modeling data or a demo-data request
- target type
- exposure basis
- claim/loss definition
- time basis or acceptable random split rationale
- material regulatory restriction that changes variable eligibility

For non-blocking uncertainty, choose a conservative actuarial default, document it in `assumptions.yml` and the model report, and continue.

## Required Workflow

1. Run or adapt `scripts/preflight.R` before modeling. R is the default stack. If `Rscript` is not on `PATH`, locate it first; on Windows, check common paths such as `C:\Program Files\R\<version>\bin\Rscript.exe`. Use Python only for file conversion or when R is unavailable and the user accepts the fallback.
2. Create a reproducible project with `analysis.R` or `model.qmd`, `data_dictionary.md`, `model_report.md` or `model_report.qmd`, `outputs/`, `artifacts/preprocessing_maps/`, and `artifacts/session_info.txt`.
3. Define the target explicitly:
   - Frequency: claim count with `offset(log(exposure))`.
   - Severity: positive claims only, usually Gamma/log with claim-count weights when justified.
   - Loss cost: aggregate loss per exposure with documented variance treatment.
   - Pure premium: Tweedie/log when one model is needed for zero mass plus positive continuous losses.
4. Reconcile exposure, claim counts, loss, premium if relevant, and exclusions before fitting.
5. Screen every candidate predictor for leakage, rating-time availability, sparse levels, regulatory/fairness concerns, and scoring stability.
6. Split train/validation/test. Use a time-based split for pricing unless the user gives a defensible reason for random splitting.
7. Fit a baseline before candidate models. Compare candidates using validation performance, calibration, lift, residuals, segment stability, and actuarial reasonableness.
8. Extract relativities with base levels or exposure-weighted normalization. Preserve grouping maps and new/missing-level scoring rules.
9. Export documentation and exhibits. Excel is a review artifact only; code and saved maps are the source of truth.

## Bundled Resources

- `scripts/preflight.R`: dependency and environment checks.
- `scripts/load_fremtpl_demo.R`: CASdatasets-based freMTPL loader and deterministic demo fixture builder. Do not bundle full freMTPL data in this skill.
- `scripts/glm_helpers.R`: QA, split, grouping, diagnostics, relativity, and session helpers.
- `scripts/analysis_template.R`: runnable frequency demo and template for user data.
- `scripts/export_workbook.R`: `openxlsx` workbook export helpers.
- `scripts/smoke_test.R`: freMTPL/demo fixture smoke test.
- `assets/templates/model_report.qmd`: report scaffold.
- `assets/templates/data_dictionary.md`: field inventory scaffold.
- `assets/templates/assumptions.yml`: assumptions scaffold.
- `references/pricing_workflow.md`: detailed workflow and correct/wrong GLM patterns.
- `references/diagnostics.md`: diagnostics definitions and minimum exhibits.
- `references/regulatory_fairness.md`: practical regulatory and fairness screening checklist.
- `references/fremtpl_demo.md`: freMTPL source, demo behavior, and limitations.
- `references/output_contract.md`: expected output files and workbook tabs.

Read only the reference files needed for the task. Start with `references/pricing_workflow.md` for modeling work, `references/fremtpl_demo.md` for demos, and `references/regulatory_fairness.md` before final variable selection.

## Non-Negotiable Checks

- Never model claim counts without exposure offset or equivalent exposure treatment.
- Never include future, post-outcome, claim handling, paid/incurred, recovery, salvage, close-date, adjuster, or litigation fields as predictors in frequency models.
- Never tune caps, groupings, splines, interactions, or selected relativities on the final test set.
- Never deliver relativities without base levels, normalization basis, grouping maps, and scoring treatment for new/missing levels.
- Never make spreadsheet-only transformations that are absent from code.
- Save package/session information with every final deliverable.

## freMTPL Demo

Use freMTPL only through `scripts/load_fremtpl_demo.R`. Prefer `CASdatasets` as the canonical R source. If `CASdatasets` is missing, report the missing optional package and give the install command; do not silently switch to Kaggle, Hugging Face, or OpenML. The loader creates a small deterministic fixture for smoke tests and demos so the skill stays fast and lightweight.

## Delivery Checklist

Before final response, verify:

- target, exposure, family/link, split, exclusions, and assumptions are documented
- exposure is positive for every modeled row
- leakage and regulatory/fairness screens are recorded
- train/validation/test diagnostics are produced where data supports them
- relativity tables include raw and selected relativities, base levels, and overrides
- preprocessing maps and session information are saved
- workbook and report match the selected model
