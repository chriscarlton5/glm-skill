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
  "dplyr", "readr", "lubridate", "broom", "ggplot2",
  "openxlsx", "MASS", "mgcv", "statmod"
)
```

Install the required packages:

```r
install.packages(
  c("dplyr", "readr", "lubridate", "broom", "ggplot2", "openxlsx", "statmod"),
  repos = "https://cloud.r-project.org"
)
```

`MASS` and `mgcv` are usually included with R distributions, but the preflight script will report if they are missing.

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

## Optional Setup Check

The repo includes an optional setup check for users who want to verify that the bundled scripts can run end-to-end without using private data.

This demo uses a public actuarial dataset loaded through the optional `CASdatasets` R package. You do not need this demo dataset to use the skill on your own data.

To install the optional demo dependency:

```r
install.packages(c("xts", "zoo"), repos = "https://cloud.r-project.org")
install.packages(
  "CASdatasets",
  repos = "https://dutangc.perso.math.cnrs.fr/RRepository/pub/",
  type = "source"
)
```

Run the setup check:

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
    load_fremtpl_demo.R            Optional public demo loader
    glm_helpers.R                  QA, split, scoring, diagnostics, and relativity helpers
    analysis_template.R            Runnable modeling template
    export_workbook.R              Excel workbook export helper
    smoke_test.R                   Optional end-to-end demo check
  assets/templates/
    assumptions.yml                Assumptions scaffold
    data_dictionary.md             Field inventory scaffold
    model_report.qmd               Report scaffold
  references/
    pricing_workflow.md            Detailed actuarial workflow and correct/wrong patterns
    diagnostics.md                 Diagnostic exhibits and formulas
    regulatory_fairness.md         Practical regulatory/fairness screening checklist
    fremtpl_demo.md                Optional demo source and limitations
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
