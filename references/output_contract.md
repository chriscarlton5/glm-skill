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
- `artifacts/model_decision_record.yml` or equivalent content in `assumptions.yml`

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
- Data reconciliation and methodology
- Target and exposure definition
- Target/family selection rationale
- Split rationale
- Exclusions and transformations
- Candidate models, rejected families, and selected model
- Diagnostics and validation
- Relativities and selected factors
- Regulatory/fairness notes
- Limitations and monitoring
- Internal run/usability notes when the deliverable is for skill evaluation rather than client-facing actuarial review
