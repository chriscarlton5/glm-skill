# Diagnostics

## Minimum Exhibits

Produce these where data supports them:

- train/validation/test performance table
- actual versus expected by prediction decile
- lift and cumulative lift
- calibration ratio
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

Values materially above 1 indicate Poisson standard errors may be understated. Review exposure, omitted variables, aggregation, and segment instability before switching families.

## Severity Metrics

Use positive claim records or cells with positive claim counts. Compare predicted average severity to actual average severity and review claim-count weighted metrics where appropriate.

## Relativity Review

Show coefficients, raw relativities, selected relativities, standard errors where useful, base levels, normalization basis, credibility flags, and manual overrides. Review high-impact cells for volume and stability.
