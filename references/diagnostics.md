# Diagnostics

## Minimum Exhibits

Produce these where data supports them:

- train/validation/test performance table
- actual versus expected by prediction decile
- lift and cumulative lift
- calibration ratio
- actual versus predicted aggregate loss by train/validation/test where applicable
- actual versus predicted pure premium by split for pure premium deliverables
- finite RMSE/MAE or equivalent error metrics appropriate to the target
- exploding prediction checks for extreme fitted values and unstable high-impact segments
- residual summaries
- observed versus fitted by selected variables
- segment stability by time, state/territory, coverage, channel, or material business segment
- overdispersion assessment for frequency models

## Frequency Metrics

For count models, compare actual claims to fitted expected claims. Expected claims from `predict(type = "response")` already include exposure when an offset was used. Divide by exposure only when presenting frequency rates.

Overdispersion check:

```r
sum(residuals(model, type = "pearson")^2) / model$df.residual
```

Values materially above 1 indicate Poisson standard errors may be understated. Review exposure, omitted variables, aggregation, and segment instability before considering quasi-Poisson or negative binomial alternatives.

## Severity Metrics

Use positive claim records or cells with positive claim counts. Compare predicted average severity to actual average severity and review claim-count weighted metrics where appropriate.

Gamma/log is the default severity baseline for positive continuous severity. Inverse Gaussian/log can be a challenger for very skewed positive severity when diagnostics and business rationale support it. Do not include zero-valued targets in Gamma or inverse Gaussian severity models.

## Pure Premium Metrics

For one-part Tweedie pure premium or aggregate loss models, compare actual and predicted aggregate loss by split. Also compare actual and predicted pure premium as `sum(loss) / sum(exposure)` and `sum(predicted_loss) / sum(exposure)`.

For two-part frequency/severity models, validate the combined pure premium in addition to the component frequency and severity models.

## Sanity Checks

Confirm all reported RMSE, MAE, lift, calibration, aggregate loss, and pure premium metrics are finite. Investigate missing, infinite, or non-finite values before delivery.

Review prediction distributions by split. Flag exploding predictions when the maximum, high percentiles, or high-impact cells are implausible relative to exposure, historical loss, or actuarial judgment.

## Relativity Review

Show coefficients, raw relativities, selected relativities, standard errors where useful, base levels, normalization basis, credibility flags, and manual overrides. Review high-impact cells for volume and stability.
