# Data Dictionary

| Field | Type | Source | Description | Missingness | Pricing-time available? | Leakage status | Transformation | Notes |
|---|---|---|---|---:|---|---|---|---|
| exposure | numeric |  | Exposure denominator |  | Yes | Allowed | Validate positive |  |
| claim_count | numeric |  | Claim count target |  | Target | Target | None |  |
| loss_amount | numeric |  | Loss amount |  | Target/Severity | Exclude from frequency predictors | Caps if used |  |

## Control Totals

| Measure | Source total | Modeled total | Difference | Notes |
|---|---:|---:|---:|---|
| Records |  |  |  |  |
| Exposure |  |  |  |  |
| Claims |  |  |  |  |
| Loss |  |  |  |  |
