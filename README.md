# Actuarial GLM Model Skill

`actuarial-glm-model` is a Codex skill for building reproducible P&C pricing GLMs. It helps Codex create R-based modeling workflows for frequency, severity, loss cost, and pure premium work, including exposure treatment, diagnostics, relativities, documentation, and optional Excel exhibits.

This skill is for users who want Codex to help build an actuarial pricing model from their own data.

## What You Can Ask Codex To Do

Examples:

```text
Use the actuarial GLM skill to build a frequency model from this policy and claims extract.
```

```text
Create a severity GLM with diagnostics, selected relativities, and a model report.
```

```text
Review this pricing dataset for leakage and build a reproducible loss cost model.
```

```text
Build a pure premium GLM and export review exhibits to Excel.
```

Codex should produce reproducible code and documentation, not just a one-time answer.

## What The Skill Produces

A full run should create some or all of these artifacts, depending on the request and available data:

```text
analysis.R or model.qmd
data_dictionary.md
model_report.md or model_report.qmd
outputs/glm_outputs.xlsx
outputs/diagnostics/
outputs/relativities/
artifacts/preprocessing_maps/
artifacts/session_info.txt
```

The exact outputs may be narrower if you ask for a targeted task, such as only a data QA review or only a baseline model.

## What Data You Need

At minimum, provide:

- A modeling dataset, such as policy, exposure, claim, premium, or aggregated cell data.
- The modeling target: frequency, severity, loss cost, or pure premium.
- An exposure basis, such as earned car-years, policy-years, payroll, sales, insured value, or another denominator.
- Claim and loss definitions, including claim count, paid/incurred basis, caps, trend, development, CAT handling, and LAE treatment where relevant.
- A time basis, such as policy period, accident period, accounting period, or effective period.
- Candidate predictors and any restrictions on which variables may be used for pricing.

If important details are missing, Codex should stop and ask for them. If a detail is non-blocking, Codex should make a conservative assumption and document it.

## Supported Data Files

The bundled helper `load_modeling_data()` supports common starting formats:

- CSV or TXT through base R
- Excel workbooks through `openxlsx`
- RDS files through base R
- Parquet files through optional `arrow`

Example:

```r
source("scripts/glm_helpers.R")
modeling_data <- load_modeling_data("data/my_modeling_file.xlsx", sheet = "modeling")
```

The data still needs a defined modeling grain, target, exposure field, time basis, and predictor list. The skill is designed to help Codex inspect and clean imperfect data, but it cannot infer claim definitions, exposure units, or pricing restrictions with confidence unless those are provided or documented.

## Skill Guardrails

The skill instructs Codex to follow these actuarial modeling rules:

- Frequency models must use exposure offsets or an equivalent exposure treatment.
- Severity models should use positive claims only.
- Future, post-outcome, claim handling, paid/incurred, recovery, salvage, close-date, adjuster, and litigation fields must not be used as frequency predictors.
- Train, validation, and test separation must be preserved.
- Sparse categorical levels must be grouped with documented mapping rules.
- Relativities must include base levels or normalization basis.
- Manual overrides and judgment selections must be documented.
- Excel outputs are review exhibits; reproducible code remains the source of truth.

## Installation

Place this folder where Codex can discover local skills. The required entrypoint is exact-case `SKILL.md`.

For a standard Codex skills directory:

```powershell
Copy-Item -Recurse C:\path\to\glm-skill C:\Users\<you>\.codex\skills\actuarial-glm-model
```

The skill package includes:

```text
SKILL.md
agents/openai.yaml
scripts/
assets/templates/
references/
```

## R Setup

R is the default modeling stack.

Required R packages:

```r
c(
  "dplyr", "lubridate", "broom", "ggplot2",
  "MASS", "mgcv", "statmod"
)
```

Install the required packages:

```r
install.packages(
  c("dplyr", "lubridate", "broom", "ggplot2", "statmod"),
  repos = "https://cloud.r-project.org"
)
```

`MASS` and `mgcv` are usually included with R distributions, but the preflight script will report if they are missing.

Optional packages:

- `openxlsx` for Excel input and workbook exhibits
- `arrow` for Parquet input
- `tweedie` for some advanced pure premium workflows
- `rsample` and `yardstick` if you want tidymodels-style splitting and metrics
- `duckdb` for larger local extracts
- `quarto` to render `.qmd` model reports

## Check Your Setup

Run the preflight script before using the skill for a real model:

```powershell
Rscript scripts\preflight.R
```

On Windows, if `Rscript` is not on `PATH`, use the full path instead:

```powershell
& 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe' scripts\preflight.R
```

Adjust the R version folder as needed.

Expected result:

```text
All required R packages are installed.
```

## Verify The Skill Works

Run the smoke test to confirm the bundled R helpers can fit a small GLM, create diagnostics, export workbook exhibits, and save session information:

```powershell
Rscript scripts\smoke_test.R
```

Or on Windows with a full R path:

```powershell
& 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe' scripts\smoke_test.R
```

## Repository Structure

```text
glm-skill/
  SKILL.md                         Codex-facing skill instructions
  agents/openai.yaml               Skill display metadata
  scripts/
    preflight.R                    R/package environment checks
    sample_data.R                  Synthetic validation data for smoke tests
    glm_helpers.R                  Data loading, QA, split, scoring, diagnostics, and relativity helpers
    analysis_template.R            Runnable frequency workflow template
    export_workbook.R              Excel workbook export helper
    smoke_test.R                   End-to-end script check
  assets/templates/
    assumptions.yml                Assumptions scaffold
    data_dictionary.md             Field inventory scaffold
    model_report.qmd               Report scaffold
  references/
    pricing_workflow.md            Detailed actuarial workflow and correct/wrong patterns
    diagnostics.md                 Diagnostic exhibits and formulas
    regulatory_fairness.md         Practical regulatory/fairness screening checklist
    output_contract.md             Expected files and workbook tabs
```

## Regulatory And Fairness Note

The skill includes a practical screening checklist for protected/proxy variables, jurisdictional restrictions, consumer explainability, adverse impact concerns, filing support, and monitoring.

This skill does not provide legal or regulatory advice. Pricing variable eligibility and filing requirements should be reviewed for the relevant jurisdiction, line of business, and company policy.

## Troubleshooting

### `Rscript` is not recognized

Use the full path to `Rscript.exe`:

```powershell
& 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe' scripts\preflight.R
```

### Preflight reports missing packages

Install the missing packages, then rerun:

```powershell
Rscript scripts\preflight.R
```

### Codex asks for more information

That is expected when required modeling inputs are missing. The most common blockers are target definition, exposure basis, claim/loss definition, time basis, and variable restrictions.

### Generated files appear in the repo

Generated model outputs should not be committed. The `.gitignore` excludes common output folders and generated workbook/data files.
