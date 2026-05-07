---
name: actuarial-glm-model
description: Build actuarial Generalized Linear Models for P&C pricing. Creates reproducible R-first modeling workflows for frequency, severity, loss cost, and pure premium GLMs with exposure offsets, leakage screening, diagnostics, relativities, validation exhibits, actuarial documentation, and optional Excel outputs. Use when users need actuarial pricing models, rate indication support, factor relativities, GLM diagnostics, or filing-ready model documentation.
---

# Actuarial GLM Model Builder

## Overview

This skill creates actuarial-quality Generalized Linear Models for P&C pricing. Each analysis produces a reproducible modeling package: R code or Quarto/R Markdown, diagnostics, selected factor relativities, an actuarial model report, and optional Excel exhibits for review, filing support, or handoff.

The default workflow is R-first and pricing-focused. Use `stats::glm` as the baseline modeling engine, with `MASS`, `splines`, `mgcv`, `broom`, `dplyr`, `ggplot2`, and `openxlsx` where appropriate.

## Tools

- Default to all user-provided data and available MCP servers for data sourcing.
- Use R for modeling unless the user explicitly requests another stack.
- Use Python only as a fallback for data wrangling, reporting, or environments where R is unavailable.
- Use Excel outputs only as companion exhibits. The source of truth must remain reproducible code and documented data transformations.

## Critical Constraints - Read These First

These constraints apply throughout all actuarial GLM work. Review before starting:

**Target Definition Is Mandatory:**
- Decide explicitly whether the model target is frequency, severity, loss cost, pure premium, retention, conversion, or another actuarial outcome.
- Do not mix frequency and severity logic in one model unless using a pure premium method such as Tweedie and documenting why that choice is appropriate.
- Document the target numerator, denominator, exposure basis, claim definition, loss definition, and accident/policy/effective period basis before modeling.

**Exposure Offsets and Weights Are Non-Negotiable:**
- Never model claim counts without an exposure offset or equivalent exposure treatment.
- For frequency GLMs, use `offset(log(exposure))` when the target is claim count.
- For average severity GLMs, model positive claim severity only and use appropriate claim-count or exposure weights only when actuarially justified.
- For pure premium, ensure the response, exposure, and variance assumptions are internally consistent.
- Remove or separately handle records with zero, negative, missing, or invalid exposure before fitting any model.

**Distribution and Link Function Must Match the Target:**
- Frequency: Poisson/log as baseline; Negative Binomial when overdispersion is material and stable.
- Severity: Gamma/log as baseline for positive continuous losses; consider inverse Gaussian, lognormal-style modeling, or limited average severity where justified.
- Pure premium: Tweedie/log where the data has a mass at zero and continuous positive losses.
- Binary outcomes: Binomial/logit for conversion, retention, fraud flags, or claim occurrence.
- Do not choose a model family based only on fit statistics. Explain the actuarial and statistical reason for the selected family.

**No Data Leakage:**
- Exclude future fields, post-outcome fields, claim handling fields, paid/incurred values when modeling frequency, and any rating variables not knowable at quote or policy issuance.
- Preserve train/validation/test separation. Do not tune factor groupings, caps, splines, or interactions on the final test set.
- Default to a time-based split for pricing unless the user explicitly requests a random split and the business context supports it.

**Actuarial Judgment Must Be Documented:**
- Document every exclusion, capping rule, winsorization, transformation, grouping, credibility adjustment, and manual override.
- Document why each selected rating variable is allowed, available, stable, and actuarially reasonable.
- Treat low-credibility categorical levels through explicit combining rules, not silent dropping or arbitrary replacement.
- Document base levels and normalization for every relativity table.

**Diagnostics Before Selection:**
- Do not accept a model until diagnostics are reviewed.
- Required diagnostics include holdout deviance or likelihood metric, calibration, lift, residual review, observed vs fitted by key segments, and stability across time or business segments.
- For pricing models, business reasonableness and monotonicity can outweigh small statistical gains.

**Reproducibility:**
- Every transformation used for training must be codified and reusable for scoring.
- Do not make manual spreadsheet-only transformations that are absent from code.
- Set random seeds when random sampling, cross-validation, or stochastic fitting is used.
- Save package versions or session information in the final output.

**Step-by-Step Verification With the User:**
- After data intake, show field inventory, target definition, date basis, and exposure reconciliation before modeling.
- After data QA, show exclusions, missingness, capping, and categorical grouping decisions before fitting candidate models.
- After baseline model, show baseline performance and diagnostics before adding complexity.
- After candidate model comparison, show selected variables, performance tradeoffs, and actuarial reasonableness before finalizing relativities.
- After final model, show validation exhibits and relativity tables before producing final report artifacts.

## Actuarial GLM Process Workflow

### Step 1: Data Intake and Schema Validation

Gather user-provided data, database extracts, MCP data, or files. Establish grain and field definitions before analysis.

**Required schema checks:**
- One row per policy-period, exposure segment, claim, or other stated grain
- Policy/effective/expiration/accounting dates
- Exposure measure such as earned car-years, policy-years, house-years, payroll, sales, or insured value
- Claim count and loss amount definitions
- Premium fields when rate adequacy, indications, or loss ratios are in scope
- Candidate rating variables available at pricing time

**Data QA summary:**
```text
Records: X
Grain: policy-term / policy-month / vehicle-year / claim / other
Experience period: YYYY-MM-DD to YYYY-MM-DD
Exposure basis: earned car-years
Claim definition: reported claims, excluding CAT, capped at $X
Loss basis: incurred loss + ALAE, developed to X months
Premium basis: current rate-level earned premium
```

### Step 2: Exposure, Claim, Premium, and Period Reconciliation

Reconcile totals before modeling. A GLM built on unreconciled experience is not audit-ready.

**Validation checklist:**
- Total exposure ties to source or accepted control total
- Claim counts tie by coverage, accident year, and claim definition
- Loss amounts tie after exclusions, caps, development, trend, or LAE treatment
- Premium basis is clear if indications or loss ratios are used
- Policy periods and accident periods are not mixed unintentionally
- Records with zero or invalid exposure are excluded or separately explained

### Step 3: Target Definition

Select the modeling target based on the actuarial question.

**Common targets:**
```text
Frequency:      claim_count with exposure offset
Severity:       loss_amount / claim_count for positive claims
Loss cost:      loss_amount / exposure
Pure premium:   aggregate_loss with Tweedie/log and exposure treatment
Claim occurrence: binary claim indicator with binomial/logit
```

**Frequency and severity are preferred for interpretability** when claim counts and loss amounts have different drivers. Tweedie pure premium can be appropriate when a single model is needed, but document why it is preferred over separate frequency and severity models.

### Step 4: Feature Audit and Leakage Screening

Create a data dictionary and classify every candidate predictor.

**Feature categories:**
- Allowed rating variables known before policy issuance
- Operational fields that may be unavailable or unstable at quote time
- Post-outcome or claim handling fields that must be excluded
- High-cardinality fields requiring grouping
- Continuous fields requiring capping, binning, splines, or monotonic treatment

**Leakage screen examples:**
- Exclude claim paid, incurred, adjuster, litigation, repair cost, salvage, recovery, close date, report lag, and claim status from frequency models.
- Exclude renewal offer premium, final bound premium, or selected deductible if the target is affected by those fields and the timing creates leakage.
- Exclude future underwriting actions or post-renewal endorsements unless the scoring use case has those fields.

### Step 5: Missing Values, Capping, and Categorical Grouping

Define preprocessing before model fitting.

**Rules:**
- Missing values can be informative. Create explicit "Missing" categories where actuarially meaningful.
- Cap continuous predictors using documented percentiles or business thresholds.
- Combine sparse categorical levels using exposure, claim count, loss, credibility, and business similarity.
- Save mapping tables for every categorical grouping.
- Do not tune groupings on the final test set.

### Step 6: Train, Validation, and Test Split

Default to a time-based split for pricing:

```text
Training:   older experience used for fitting
Validation: more recent experience used for model selection
Test:       final holdout period used once for unbiased evaluation
```

Use random splits only when time effects are immaterial or the user requests a random split for a specific reason. Preserve geographic, program, coverage, or channel segment representation where possible.

### Step 7: Baseline Model Build

Fit a simple baseline model before adding complexity.

**Baseline frequency model:**
```r
baseline_freq <- glm(
  claim_count ~ 1,
  family = poisson(link = "log"),
  offset = log(exposure),
  data = train
)
```

**Baseline severity model:**
```r
severity_train <- train |>
  dplyr::filter(claim_count > 0, loss_amount > 0)

baseline_sev <- glm(
  avg_severity ~ 1,
  family = Gamma(link = "log"),
  weights = claim_count,
  data = severity_train
)
```

### Step 8: Candidate Model Iteration

Build candidate models incrementally. Add variables, interactions, splines, or grouped factors only when they improve validation performance and remain actuarially reasonable.

**Candidate evaluation should include:**
- Incremental lift over baseline
- Holdout deviance or log-likelihood improvement
- Stability by accident/effective period
- Observed vs fitted calibration by decile and key segments
- Relativity reasonableness and monotonicity
- Variable availability and operational usability
- Filing, regulatory, or fairness constraints where applicable

### Step 9: Diagnostics and Validation

Do not finalize a model before completing diagnostics.

**Required exhibits:**
- Actual vs expected by decile
- Lift chart and cumulative lift
- Calibration plot
- Residual plots for continuous predictors
- Observed vs fitted by selected categorical variables
- Holdout performance table
- Overdispersion assessment for count models
- Stability by time, state/territory, coverage, channel, or other material segment

**Example validation table:**
```csv
Model,Train Deviance,Validation Deviance,Test Deviance,Lift Top Decile,Calibration Ratio,Selected
Baseline,X.X,X.X,X.X,1.00,1.00,No
Candidate 1,X.X,X.X,X.X,1.18,0.99,No
Selected GLM,X.X,X.X,X.X,1.24,1.01,Yes
```

### Step 10: Relativity Extraction and Normalization

Convert model coefficients into actuarial relativities.

**Relativity requirements:**
- State the base level or exposure-weighted normalization basis.
- Show coefficients, standard errors, p-values if relevant, raw relativities, selected relativities, and manual overrides.
- Preserve categorical grouping maps.
- For continuous variables, show fitted curve, selected curve, and any monotonic smoothing.
- Document the effective date and portfolio segment for the relativities.

### Step 11: Actuarial Review

Review the selected model with actuarial judgment before delivery.

**Review checklist:**
- Selected variables are available at quote or rating time
- Relativities are credible, explainable, and directionally reasonable
- Sparse levels are combined or credibility-weighted
- High-impact cells are reviewed for volume and stability
- Model does not overreact to one accident period or segment
- Regulatory, business, and fairness constraints are documented
- Indicated changes are separated from selected changes when judgment is applied

### Step 12: Final Report and Reproducible Artifacts

Create deliverables that allow another actuary or analyst to rerun and audit the model.

**Required deliverables:**
- `analysis.R` or `model.qmd`
- `data_dictionary.md`
- `model_report.md` or rendered HTML/PDF when available
- `glm_outputs.xlsx` when spreadsheet exhibits are useful
- Session/package version output
- Saved preprocessing maps and selected model object when appropriate

<correct_patterns>

This section contains the CORRECT patterns to follow when building actuarial GLMs.

### Correct Frequency Offset Pattern

Claim counts must be modeled with exposure.

```r
freq_glm <- glm(
  claim_count ~ territory_group + vehicle_age_band + driver_age_spline,
  family = poisson(link = "log"),
  offset = log(exposure),
  data = train
)
```

**Required checks:**
- `exposure > 0` for every modeled row
- exposure unit is documented
- predicted claim frequency is converted as `predict(type = "response") / exposure` only when the response prediction is aggregate expected claims
- overdispersion is tested before relying on Poisson standard errors

### Correct Severity Filtering Pattern

Severity models use positive claim records or aggregated cells with positive claim counts.

```r
severity_train <- train |>
  dplyr::filter(claim_count > 0, capped_loss > 0) |>
  dplyr::mutate(avg_severity = capped_loss / claim_count)

sev_glm <- glm(
  avg_severity ~ territory_group + vehicle_symbol + limit_band,
  family = Gamma(link = "log"),
  weights = claim_count,
  data = severity_train
)
```

Do not include zero-claim records in a severity model. They belong in the frequency model or a pure premium model.

### Correct Tweedie Pure Premium Pattern

Use Tweedie only when the business goal supports a single pure premium model and the data has zero mass plus positive continuous losses.

```r
pure_premium_glm <- glm(
  aggregate_loss ~ territory_group + vehicle_age_band + driver_age_band,
  family = statmod::tweedie(var.power = 1.5, link.power = 0),
  offset = log(exposure),
  data = train
)
```

Document the selected Tweedie power parameter and how it was chosen.

### Correct Time-Based Split Pattern

Pricing models should usually validate on future periods.

```r
train <- modeling_data |> dplyr::filter(accounting_period <= as.Date("2024-12-31"))
valid <- modeling_data |> dplyr::filter(accounting_period >= as.Date("2025-01-01"),
                                        accounting_period <= as.Date("2025-06-30"))
test  <- modeling_data |> dplyr::filter(accounting_period >= as.Date("2025-07-01"))
```

Do not tune on `test`. Use `test` once after model selection.

### Correct Factor Level Grouping Pattern

Group sparse categorical levels before modeling and save the mapping.

```r
territory_map <- train |>
  dplyr::group_by(territory) |>
  dplyr::summarise(
    exposure = sum(exposure),
    claims = sum(claim_count),
    loss = sum(capped_loss),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    territory_group = dplyr::case_when(
      exposure < 100 ~ "Low credibility",
      claims < 10 ~ "Low credibility",
      TRUE ~ territory
    )
  )
```

Apply the same mapping to validation, test, and scoring data. New levels must map to an explicit "New/Other" group.

### Correct Relativity Normalization Pattern

Relativities must have a stated base.

```r
coef_tbl <- broom::tidy(freq_glm)

raw_relativity <- exp(coef(freq_glm))
base_level <- "territory_groupA"
```

For categorical factors, report the base level with relativity `1.000`. For exposure-weighted normalization, show the normalization formula and the portfolio used.

### Correct Model Comparison Pattern

Select models using validation performance and actuarial reasonableness.

```csv
Criterion,Baseline,Candidate,Selected
Validation deviance,X.X,X.X,X.X
Top decile lift,1.00,1.20,1.18
Calibration ratio,1.00,0.96,1.01
Sparse-level risk,Low,Medium,Low
Actuarial reasonableness,High,Medium,High
```

The statistically best model is not automatically the selected model. Explain any tradeoff between fit, stability, credibility, and business constraints.

### Correct Documentation Pattern

Every selected model needs a documented trail:

```text
Data source: [system/file], extract date, row count, control totals
Target: claim_count
Exposure: earned car-years
Family/link: Poisson/log
Offset: log(exposure)
Split: time-based, train/validation/test periods
Exclusions: CAT claims, zero exposure records, losses capped at $X
Selected variables: territory_group, vehicle_age_band, driver_age_spline
Diagnostics: validation deviance, lift, calibration, residual review
Relativity base: exposure-weighted portfolio average as of YYYY-MM-DD
```

</correct_patterns>

<common_mistakes>

This section contains WRONG patterns to avoid when building actuarial GLMs.

### WRONG: Modeling Frequency Without Exposure

```r
# WRONG
glm(claim_count ~ territory + vehicle_age, family = poisson, data = train)
```

Why it is wrong:
- A policy with twice the exposure should have roughly twice the expected claims.
- The model confuses volume with risk.
- Relativities will be biased toward high-exposure segments.

Instead, use `offset = log(exposure)` and validate that exposure is positive.

### WRONG: Using Claim Amount Fields as Predictors for Claim Occurrence

Do not use paid loss, incurred loss, claim status, litigation status, adjuster, salvage, recovery, or close date as predictors in a frequency model.

Why it is wrong:
- These fields are known after the claim occurs.
- They leak outcome information.
- The model will fail when scored at quote time.

### WRONG: Selecting Variables Only by P-Value

P-values are not a model selection strategy.

Why it is wrong:
- Large insurance datasets can make immaterial effects statistically significant.
- Sparse levels can look significant but be unstable.
- Business constraints, credibility, monotonicity, and validation performance matter.

Instead, use validation diagnostics plus actuarial review.

### WRONG: Ignoring Sparse Categorical Levels

Do not leave thousands of low-volume levels ungrouped.

Why it is wrong:
- Relativities become unstable.
- New scoring levels are not handled.
- Filing and peer review become difficult.

Instead, combine low-credibility levels using documented rules and preserve the mapping.

### WRONG: Reporting Relativities Without Base Levels

Do not deliver a relativity table without saying what `1.000` means.

Why it is wrong:
- The user cannot apply or audit the relativities.
- Changes in base level can change every displayed relativity.
- Indicated and selected relativities become ambiguous.

Instead, state the base level or exposure-weighted normalization basis.

### WRONG: Delivering a Model Without Validation

Do not deliver only coefficients, p-values, or in-sample fit.

Why it is wrong:
- It does not show out-of-sample performance.
- It hides calibration and stability issues.
- It is not actuarial-review ready.

Instead, provide holdout diagnostics, lift, calibration, and observed vs fitted exhibits.

### WRONG: Spreadsheet-Only Transformations

Do not manually group levels, cap variables, or override relativities only in Excel.

Why it is wrong:
- The model cannot be reproduced.
- Scoring will not match the documented output.
- Audit trail is incomplete.

Instead, implement transformations in code and export Excel as a review artifact.

### TOP 5 ERRORS SUMMARY

1. **No exposure offset** -> use `offset(log(exposure))` for frequency count models.
2. **Leakage predictors** -> exclude fields unavailable at quote or policy issuance.
3. **Sparse levels ungrouped** -> combine low-credibility levels with documented mappings.
4. **No holdout validation** -> preserve validation and test sets.
5. **Relativities undocumented** -> state base levels, normalization, and judgment overrides.

Re-read this section before starting any actuarial GLM build.

</common_mistakes>

## R Modeling Package Creation

The source of truth is reproducible R code. A professional GLM deliverable should be rerunnable by another analyst with the same inputs.

**Recommended project structure:**
```text
analysis.R or model.qmd
data_dictionary.md
model_report.md
outputs/glm_outputs.xlsx
outputs/diagnostics/
outputs/relativities/
artifacts/preprocessing_maps/
artifacts/session_info.txt
```

**R package guidance:**
- Use `dplyr` for data preparation.
- Use `stats::glm` for baseline GLMs.
- Use `MASS::glm.nb` for Negative Binomial candidates when overdispersion supports it.
- Use `splines` or `mgcv` for continuous effects when simple linear effects are inadequate.
- Use `broom` for model summaries.
- Use `ggplot2` for diagnostics.
- Use `openxlsx` for Excel exhibits.

## Quality Rubric

Every actuarial GLM must maximize for:
1. **Correct target and exposure treatment** for the actuarial question.
2. **Clean, reconciled, documented data** with control totals and exclusions.
3. **No leakage** from future, claim handling, or post-outcome fields.
4. **Appropriate family/link selection** with actuarial rationale.
5. **Strong validation** across holdout periods and material segments.
6. **Credible, explainable relativities** with documented base levels.
7. **Reproducibility** through code, maps, package versions, and reports.
8. **Actuarial judgment trail** for overrides, grouping, smoothing, and selections.

## Input Requirements

### Minimum Required Inputs

1. **Model purpose**: frequency, severity, pure premium, loss cost, retention, or another target.
2. **Modeling dataset**: policy, exposure, claim, premium, or aggregated cell data.
3. **Exposure basis**: earned car-years, policy-years, house-years, payroll, sales, insured value, or other denominator.
4. **Claim/loss definition**: claim count, paid/incurred loss, ALAE/ULAE treatment, cap, trend, development, and CAT handling.
5. **Time basis**: policy period, accident period, accounting period, or effective period.
6. **Candidate predictors**: available fields and whether they are available at quote/rating time.

### Optional Parameters

- Coverage or line of business
- State, territory, product, channel, or program scope
- Train/validation/test split dates
- Required rating variables
- Disallowed variables or regulatory constraints
- Credibility thresholds for categorical grouping
- Loss caps, trend factors, development factors, or on-level premium factors
- Desired output format: R script, Quarto, Markdown report, Excel workbook, or all

## Output Structure

### Required Artifacts

Create these files unless the user requests a narrower deliverable:

1. **`analysis.R` or `model.qmd`** - Reproducible data prep, modeling, diagnostics, and export workflow.
2. **`data_dictionary.md`** - Field definitions, type, source, missingness, allowed/leakage status, and transformation notes.
3. **`model_report.md`** - Executive summary, data basis, methods, diagnostics, selected model, relativities, limitations, and next steps.
4. **`glm_outputs.xlsx`** - Review workbook when spreadsheet output is useful.

### Excel Workbook Architecture

When creating `glm_outputs.xlsx`, use these tabs:

1. **Inputs** - Model purpose, data source, periods, target, exposure, assumptions, exclusions.
2. **Data QA** - Record counts, exposure/loss/premium reconciliation, missingness, outliers.
3. **Model Summary** - Candidate models, selected model, family/link, variables, performance.
4. **Diagnostics** - Lift, calibration, residuals, observed vs fitted summaries.
5. **Relativities** - Raw and selected relativities, base levels, credibility, overrides.
6. **Validation** - Train/validation/test metrics and segment stability.
7. **Change Log** - Manual selections, judgment adjustments, dates, and rationale.

### Excel Formatting Standards

Borrow the financial-modeling convention where useful:

**Font colors:**
- **Blue text (`#0000FF`)**: hardcoded assumptions, manual selections, judgment overrides.
- **Black text (`#000000`)**: calculated values or exported model outputs.
- **Green text (`#008000`)**: links or references to another sheet/output.

**Fill colors:**
- **Section headers**: dark blue (`#1F4E79`) with white bold text.
- **Subheaders**: light blue (`#D9E1F2`) with black bold text.
- **Manual actuarial selections**: light grey (`#F2F2F2`) with blue text.
- **Key selected outputs**: medium blue (`#BDD7EE`) with bold black text.

**Documentation:**
- Every manual selection or override must include a note/comment with rationale.
- Every exhibit must state whether values are train, validation, test, or full portfolio.
- Relativity exhibits must state base level or normalization.

## Detailed Report Structure

### Executive Summary

Include:
- Model purpose and target
- Recommended model and family/link
- Key selected variables
- Validation performance
- Main actuarial judgments
- Limitations and recommended monitoring

### Data and Methodology

Include:
- Data source and extract date
- Experience period and valuation/development basis
- Exposure, claim, loss, and premium definitions
- Exclusions and transformations
- Train/validation/test split
- Candidate model families considered

### Diagnostics

Include:
- Model comparison table
- Lift and calibration exhibits
- Residual and fitted value review
- Segment stability
- Overdispersion or distribution diagnostics
- Notes on rejected variables or models

### Relativities and Selection

Include:
- Raw modeled relativities
- Selected relativities
- Base levels or exposure-weighted normalization
- Credibility and smoothing adjustments
- Manual overrides and rationale
- Scoring considerations for new or missing levels

## Common Variations

### Personal Auto Frequency

- Use earned car-years or vehicle-years as exposure.
- Common predictors include territory, driver age, vehicle age, prior claims, coverage, limits, deductibles, and usage.
- Review monotonicity and regulatory constraints carefully.

### Homeowners Severity

- Use positive claims only.
- Cap large losses or model large loss separately when needed.
- Consider construction, amount of insurance, territory, peril, deductible, and age of home.

### Commercial Lines

- Exposure may be payroll, sales, area, insured value, car-years, or policy-years.
- Size effects and industry classifications often require credibility grouping.
- Large accounts may need separate treatment or credibility blending.

### Claims Reserving GLMs

- If the user asks for reserving, adapt the workflow to triangle or transaction-level reserving.
- Consider overdispersed Poisson, calendar/accident/development effects, and uncertainty intervals.
- Do not force pricing relativities onto reserving outputs.

### Mortality, Lapse, or Life/Health Models

- Use binomial, Poisson, or survival-style models as appropriate.
- Document exposure-to-risk, censoring, duration, attained age, underwriting class, and policy behavior.
- Adapt validation to the product and available experience.

## Troubleshooting

### Overdispersion in Frequency Model

Symptoms:
- Residual deviance materially exceeds degrees of freedom.
- Standard errors appear too small.
- Lift looks strong in train but unstable in validation.

Actions:
- Check missing exposure or aggregation issues.
- Consider quasi-Poisson for standard errors or Negative Binomial for model fit.
- Review omitted variables and segment instability.

### Unstable Relativities

Symptoms:
- Extreme relativities for sparse levels.
- Large changes between train and validation.
- Non-credible selected factors.

Actions:
- Combine sparse levels.
- Use credibility thresholds.
- Smooth continuous effects.
- Remove or constrain variables that are not stable.

### Poor Calibration

Symptoms:
- Actual/expected ratios deviate materially by decile or key segment.
- The model consistently underpredicts high-risk or low-risk groups.

Actions:
- Check target/exposure alignment.
- Review loss development, trend, and capping.
- Add missing interaction or nonlinear effect if actuarially justified.
- Reassess train/test period representativeness.

### Scoring Data Fails

Symptoms:
- New factor levels appear at scoring time.
- Missing fields or changed data types break predictions.

Actions:
- Create explicit new/other mappings.
- Save preprocessing maps.
- Validate scoring schema before prediction.
- Document fallback treatment for missing or new values.

## Workflow Integration

### At Start of GLM Build

1. Confirm model purpose, target, exposure, and time basis.
2. Load and profile data.
3. Reconcile exposure, claim count, loss, and premium totals.
4. Create a data dictionary and leakage screen.
5. Present QA findings and proposed exclusions before modeling.

### During Model Construction

1. Build reproducible R transformations.
2. Split train/validation/test data.
3. Fit baseline model.
4. Fit candidate models incrementally.
5. Generate diagnostics after each material candidate.
6. Extract and normalize relativities.
7. Record all actuarial judgment decisions.

### Before Delivering Model

1. Confirm no leakage variables remain.
2. Confirm every modeled row has valid exposure treatment.
3. Confirm diagnostics are generated for train, validation, and test where available.
4. Confirm selected variables and relativities are documented.
5. Confirm preprocessing maps are saved.
6. Confirm report and optional Excel workbook match the final selected model.
7. Save package/session information.

### Available Data Sources

- **User-provided data**: policy, exposure, claim, premium, rating, and underwriting extracts.
- **MCP servers**: when configured for internal data or documentation.
- **External benchmarks**: use only when the user provides them or asks for market/industry context.
- **Manual assumptions**: allowed only when clearly documented as actuarial judgment.

## Final Output Checklist

Before delivering an actuarial GLM model:

**Required:**
- Reproducible `analysis.R` or `model.qmd`
- `data_dictionary.md`
- `model_report.md` or rendered report
- Documented target, exposure, family/link, and split
- No leakage variables
- Valid exposure offset or weighting treatment
- Documented exclusions, caps, transformations, and grouping maps
- Train/validation/test diagnostics where data supports them
- Relativity tables with base levels and normalization
- Session/package version output

**Validation:**
- Frequency model uses exposure offset or equivalent exposure treatment
- Severity model uses positive claims only
- Pure premium model documents Tweedie or alternative rationale
- Sparse categorical levels are grouped or credibility-treated
- Holdout performance is reviewed
- Calibration and lift exhibits are generated
- Manual actuarial selections are documented

**Optional Excel Output:**
- `glm_outputs.xlsx` includes Inputs, Data QA, Model Summary, Diagnostics, Relativities, Validation, and Change Log tabs
- Blue font for manual assumptions/selections
- Black font for calculated outputs
- Green font for cross-sheet references
- Comments or notes on manual judgment selections
