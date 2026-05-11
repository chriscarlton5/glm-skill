# Pricing GLM Workflow

## Target Selection

Choose one target and deliverable structure before modeling. If the user already specifies a valid target, family, link, and exposure treatment, document those as locked expert choices. If the user is unsure, inspect the data and use this decision tree:

- Modeling counts: frequency model, usually Poisson/log first with `offset(log(exposure))`.
- Modeling positive claim sizes only: severity model, usually Gamma/log with claim-count weights where appropriate.
- Modeling total loss per exposure in one model: one-part pure premium, usually Tweedie/log when the target has zero losses plus positive continuous losses.
- Building pricing indication components: document whether the deliverable is one-part pure premium or two-part frequency/severity.

Document numerator, denominator, exposure unit, claim definition, loss definition, period basis, coverage, and excluded experience.

Poisson is not appropriate for aggregate pure premium unless the modeled target is a count. Gamma is not appropriate when the modeled target includes zeros.

## Family Registry

Use this registry to identify valid candidates, not to force a single answer.

| Family or approach | Valid target shape | Exposure or weights | Default link | Use when | Reject when |
| --- | --- | --- | --- | --- | --- |
| Poisson | Non-negative integer counts | `offset(log(exposure))` or equivalent | log | Claim count frequency baseline | Target is aggregate loss, pure premium, severity, or non-integer continuous |
| Quasi-Poisson | Non-negative integer counts | `offset(log(exposure))` | log | Count model needs overdispersion-adjusted inference | Need likelihood/AIC comparison or materially different prediction shape |
| Negative binomial | Non-negative integer counts with overdispersion | `offset(log(exposure))` | log | Count variance materially exceeds mean and validation/calibration improve | Overdispersion is minor or instability outweighs benefit |
| Gamma | Positive continuous severity or average severity | Claim-count weights or justified exposure weights | log | Positive claim size modeling | Target includes zeros or negative values |
| Inverse Gaussian | Positive continuous severity | Claim-count weights or justified exposure weights | log | Very skewed positive severity where diagnostics support it | Zeros are present or fit is unstable/hard to explain |
| Tweedie | Zero mass plus positive continuous loss | `offset(log(exposure))` for aggregate loss or exposure weights for pure premium rate | log | One-part pure premium or aggregate loss | Target is a pure count, positive-only severity, or two-part indication is required |
| Two-part frequency/severity | Count plus positive severity components | Frequency offset and severity weights | Component-specific | Filing, indication, interpretability, or component monitoring matters | A one-part pure premium model is explicitly required and performs better |

## Correct Patterns

Frequency baseline:

```r
glm(
  claim_count ~ 1,
  family = poisson(link = "log"),
  offset = log(exposure),
  data = train
)
```

Negative binomial frequency challenger:

```r
MASS::glm.nb(
  claim_count ~ territory_group + vehicle_age_band + offset(log(exposure)),
  data = train
)
```

Severity baseline:

```r
severity_train <- train |>
  dplyr::filter(claim_count > 0, loss_amount > 0) |>
  dplyr::mutate(avg_severity = loss_amount / claim_count)

glm(
  avg_severity ~ 1,
  family = Gamma(link = "log"),
  weights = claim_count,
  data = severity_train
)
```

Inverse Gaussian severity challenger:

```r
glm(
  avg_severity ~ territory_group + vehicle_age_band,
  family = inverse.gaussian(link = "log"),
  weights = claim_count,
  data = severity_train
)
```

Tweedie pure premium:

```r
glm(
  aggregate_loss ~ territory_group + vehicle_age_band + driver_age_band,
  family = statmod::tweedie(var.power = 1.5, link.power = 0),
  offset = log(exposure),
  data = train
)
```

Two-part pure premium:

```r
frequency_pred <- predict(frequency_model, newdata = scoring, type = "response") / scoring$exposure
severity_pred <- predict(severity_model, newdata = scoring, type = "response")
pure_premium_pred <- frequency_pred * severity_pred
```

## Data QA

Load user files with an explicit, reproducible step. `load_modeling_data()` supports CSV, TXT, Excel, RDS, and Parquet inputs; document the source file, sheet or table name, extract date, and any parsing assumptions.

Reconcile before fitting:

- row count and grain
- exposure total
- claim count total
- loss total after caps, exclusions, trend, development, and LAE treatment
- premium total when rate adequacy or loss ratios are in scope
- invalid exposure rows and disposition

## Leakage Screen

Exclude fields unavailable at quote/rating time. Frequency models must not use paid loss, incurred loss, claim status, claim close date, litigation, adjuster, repair cost, salvage, recovery, report lag, or other post-claim fields.

## Grouping and Transformations

Create explicit mapping tables for sparse categorical levels. Save categorical training levels, grouping maps, and new/missing-level scoring treatment. Apply the same maps to validation, test, and scoring data. New levels must map to `New/Other` or another documented fallback. Continuous caps, bins, and transformation parameters must be fit on training data only and saved. Spreadsheet transformations are review artifacts only; scoring transformations must be reproducible in code.

## Model Selection

Select models using validation diagnostics and actuarial judgment. P-values alone are insufficient. When family choice is ambiguous, document candidate families considered, rejected families, selected family/link, offset or weights, diagnostics used, selection rationale, and limitations. The statistically best model is not automatically the selected model when it is unstable, non-credible, hard to file, or operationally unavailable.

## Common Mistakes

- Claim count GLM without exposure offset.
- Poisson model used for aggregate pure premium or other non-count losses.
- Gamma model used when zero losses are included.
- Severity model includes zero-claim rows.
- Leakage fields used as predictors.
- Sparse levels left ungrouped.
- Test set used for tuning.
- Relativities delivered without base level or normalization.
- Spreadsheet-only overrides absent from code.
