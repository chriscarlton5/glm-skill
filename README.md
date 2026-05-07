# Actuarial GLM Model Skill

`actuarial-glm-model` is a Codex skill for building reproducible actuarial Generalized Linear Models for P&C pricing. It is designed for frequency, severity, loss cost, and Tweedie pure premium workflows, with R-first scripts, actuarial guardrails, diagnostics, relativities, documentation templates, and optional Excel review exhibits.

The skill is intentionally not just a checklist. It includes reusable R scripts and templates so a new Codex agent can run a preflight, use the freMTPL demo path, fit a baseline frequency GLM, generate diagnostics, export relativities, and produce workbook artifacts.

## What This Skill Does

- Builds P&C pricing GLMs with correct target and exposure treatment.
- Enforces frequency model exposure offsets such as `offset(log(exposure))`.
- Supports frequency, severity, loss cost, and Tweedie pure premium modeling patterns.
- Screens predictors for leakage, rating-time availability, sparse levels, scoring stability, and regulatory/fairness concerns.
- Produces reproducible R workflows with saved preprocessing maps and session information.
- Generates model diagnostics, calibration/lift exhibits, relativity tables, and optional Excel workbooks.
- Provides a freMTPL smoke-test/demo path without bundling the full dataset into the skill.

## Repository Structure

```text
glm-skill/
  SKILL.md                         Codex-facing skill instructions
  agents/openai.yaml               Skill display metadata
  scripts/
    preflight.R                    R/package environment checks
    load_fremtpl_demo.R            freMTPL loader and deterministic fixture builder
    glm_helpers.R                  QA, split, scoring, diagnostics, and relativity helpers
    analysis_template.R            Runnable demo/modeling template
    export_workbook.R              Excel workbook export helper
    smoke_test.R                   End-to-end freMTPL demo smoke test
  assets/templates/
    assumptions.yml                Assumptions scaffold
    data_dictionary.md             Field inventory scaffold
    model_report.qmd               Report scaffold
  references/
    pricing_workflow.md            Detailed actuarial workflow and correct/wrong patterns
    diagnostics.md                 Diagnostic exhibits and formulas
    regulatory_fairness.md         Practical regulatory/fairness screening checklist
    fremtpl_demo.md                freMTPL source and demo limitations
    output_contract.md             Expected files and workbook tabs
```

## Installation

Place this folder where Codex can discover local skills. The required skill entrypoint is exact-case `SKILL.md`.

For a standard Codex skills directory:

```powershell
Copy-Item -Recurse C:\path\to\glm-skill C:\Users\<you>\.codex\skills\actuarial-glm-model
```

This repo already contains the expected skill metadata:

- `SKILL.md`
- `agents/openai.yaml`
- bundled scripts, templates, and references

## R Requirements

R is the default modeling stack. The scripts have been tested with:

```text
R 4.5.3
```

Required R packages:

```r
c(
  "dplyr", "readr", "lubridate", "broom", "ggplot2",
  "openxlsx", "MASS", "mgcv", "statmod"
)
```

Optional packages:

```r
c(
  "CASdatasets", "tweedie", "rsample", "yardstick",
  "arrow", "duckdb", "quarto"
)
```

`CASdatasets` is required for the freMTPL demo/smoke test. It is not hosted on CRAN because of package size, so install it from an official CASdatasets repository.

Install core packages from CRAN:

```r
install.packages(
  c("dplyr", "readr", "lubridate", "broom", "ggplot2", "openxlsx", "statmod"),
  repos = "https://cloud.r-project.org"
)
```

Install CASdatasets:

```r
install.packages(c("xts", "zoo"), repos = "https://cloud.r-project.org")
install.packages(
  "CASdatasets",
  repos = "https://dutangc.perso.math.cnrs.fr/RRepository/pub/",
  type = "source"
)
```

## Windows Rscript Note

On some Windows machines, `Rscript` is installed but not on `PATH`. If this fails:

```powershell
Rscript scripts\preflight.R
```

use the full executable path:

```powershell
& 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe' scripts\preflight.R
```

Adjust the version folder as needed.

## Quick Validation

Run the preflight:

```powershell
& 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe' scripts\preflight.R
```

Expected result after installing required packages:

```text
All required R packages are installed.
```

Run the full freMTPL smoke test:

```powershell
& 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe' scripts\smoke_test.R
```

Expected result:

```text
GLM skill smoke test passed: <temp path>/glm_skill_smoke_test
```

The smoke test verifies these artifacts:

- `outputs/diagnostics/performance.csv`
- `outputs/diagnostics/calibration_decile.csv`
- `outputs/relativities/frequency_relativity_table.csv`
- `outputs/glm_outputs.xlsx`
- `artifacts/preprocessing_maps/area_map.csv`
- `artifacts/session_info.txt`

## freMTPL Demo Behavior

The skill uses freMTPL only through `scripts/load_fremtpl_demo.R`.

Important design choices:

- The full freMTPL dataset is not bundled in this repo.
- The canonical source is the `CASdatasets` R package.
- The loader uses `freMTPL2freq` for frequency demos.
- A small deterministic fixture is created at runtime for smoke tests.
- If `CASdatasets` is unavailable, the script stops with a clear optional dependency message rather than silently switching to another source.

This keeps the skill lightweight while preserving reproducibility and actuarial familiarity.

## Running the Demo Template

To run the demo modeling path directly:

```powershell
& 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe' scripts\analysis_template.R
```

By default, this writes demo output to:

```text
glm_demo_output/
```

Generated model artifacts are ignored by git through `.gitignore`.

## Expected Modeling Workflow

The skill instructs Codex to:

1. Run `scripts/preflight.R`.
2. Define target, exposure, claim/loss definition, and time basis.
3. Reconcile exposure, claim count, loss, and premium where relevant.
4. Screen predictors for leakage and availability at rating time.
5. Split train/validation/test, using time-based splits by default.
6. Fit a baseline model before candidates.
7. Generate diagnostics before selecting a model.
8. Extract relativities with base levels and normalization.
9. Save preprocessing maps and session information.
10. Produce report/workbook outputs aligned to the selected model.

## Output Contract

A full modeling run should produce:

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

Workbook tabs, when Excel output is requested:

- Inputs
- Data QA
- Model Summary
- Diagnostics
- Relativities
- Validation
- Change Log

## Actuarial Guardrails

The skill treats these as non-negotiable:

- Claim count models require an exposure offset or equivalent exposure treatment.
- Severity models use positive claims only.
- Leakage fields are excluded from frequency predictors.
- Grouping, capping, and splines are tuned only on training/validation data, not final test.
- Relativities include base levels, normalization, and scoring treatment for new/missing levels.
- Spreadsheet outputs are review exhibits, not the source of truth.
- Session/package information is saved with final artifacts.

## Regulatory and Fairness Review

The skill includes `references/regulatory_fairness.md` for practical screening of variable eligibility, protected/proxy risk, jurisdictional restrictions, consumer explainability, adverse impact concerns, filing support, and monitoring.

This skill does not provide legal or regulatory advice. The final model report should document assumptions and recommend jurisdiction-specific review when variable eligibility or filing support is material.

## Validation Performed

The current implementation has been validated as follows:

- Official Codex skill validation passes.
- All R scripts parse successfully.
- R preflight passes after installing required packages.
- freMTPL smoke test passes end-to-end.
- A fresh forward-test agent independently ran the skill and confirmed the demo path works, with the only caveat that `Rscript` may need a full Windows path.

## Development Notes

- Keep `SKILL.md` concise because it is loaded into Codex context.
- Put detailed guidance in `references/`.
- Put deterministic, repeated procedures in `scripts/`.
- Do not commit full freMTPL data or generated model outputs.
- Do not add `renv.lock` in v1; use preflight checks and explicit dependency installation instead.

## Common Troubleshooting

### `Rscript` is not recognized

Use the full path to `Rscript.exe`, for example:

```powershell
& 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe' scripts\preflight.R
```

### `CASdatasets` is not available on CRAN

Install it from the official CASdatasets repository:

```r
install.packages(
  "CASdatasets",
  repos = "https://dutangc.perso.math.cnrs.fr/RRepository/pub/",
  type = "source"
)
```

### Smoke test fails during preflight

Install missing required packages, then rerun:

```powershell
& 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe' scripts\preflight.R
& 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe' scripts\smoke_test.R
```

### Generated outputs appear in the repo

They should be ignored by `.gitignore`. Remove generated folders such as `glm_demo_output/`, `outputs/`, and `artifacts/` before committing if they were created manually.
