# Output Contract

## Default Project Files

Create these unless the user requests a narrower deliverable:

- `analysis.R` or `model.qmd`
- `data_dictionary.md`
- `model_report.md` or `model_report.qmd`
- `outputs/glm_outputs.xlsx` when Excel output is useful
- `outputs/diagnostics/`
- `outputs/relativities/`
- `artifacts/preprocessing_maps/`
- `artifacts/session_info.txt`

## Workbook Tabs

When exporting `glm_outputs.xlsx`, include:

- Inputs
- Data QA
- Model Summary
- Diagnostics
- Relativities
- Validation
- Change Log

Use blue font for assumptions/manual selections, black for calculated output, and green for links or cross-sheet references.

## Minimum Report Sections

- Executive summary
- Data and methodology
- Target and exposure definition
- Exclusions and transformations
- Candidate models and selected model
- Diagnostics and validation
- Relativities and selected factors
- Regulatory/fairness notes
- Limitations and monitoring
