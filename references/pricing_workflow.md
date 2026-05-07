# Pricing GLM Workflow

## Target Selection

Choose one target before modeling:

- Frequency: `claim_count` with `offset(log(exposure))`, usually Poisson/log first.
- Severity: positive claims only, `avg_severity = loss / claim_count`, usually Gamma/log.
- Loss cost: `loss / exposure` or aggregate loss with a documented variance assumption.
- Pure premium: aggregate loss with Tweedie/log when zero losses and positive continuous losses must be modeled together.

Document numerator, denominator, exposure unit, claim definition, loss definition, period basis, coverage, and excluded experience.

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

Tweedie pure premium:

```r
glm(
  aggregate_loss ~ territory_group + vehicle_age_band + driver_age_band,
  family = statmod::tweedie(var.power = 1.5, link.power = 0),
  offset = log(exposure),
  data = train
)
```

## Data QA

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

Create explicit mapping tables for sparse categorical levels. Apply the same maps to validation, test, and scoring data. New levels must map to `New/Other` or another documented fallback. Continuous caps and bins must be fit on training data only and saved.

## Model Selection

Select models using validation diagnostics and actuarial judgment. P-values alone are insufficient. The statistically best model is not automatically the selected model when it is unstable, non-credible, hard to file, or operationally unavailable.

## Common Mistakes

- Claim count GLM without exposure offset.
- Severity model includes zero-claim rows.
- Leakage fields used as predictors.
- Sparse levels left ungrouped.
- Test set used for tuning.
- Relativities delivered without base level or normalization.
- Spreadsheet-only overrides absent from code.
