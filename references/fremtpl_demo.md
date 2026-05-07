# freMTPL Demo

Use freMTPL for demos and smoke tests because it is a well-known motor third-party liability dataset used in actuarial pricing examples.

## Source

Prefer the `CASdatasets` R package as the canonical source. Its freMTPL reference documents `freMTPLfreq`, `freMTPLsev`, `freMTPL2freq`, and `freMTPL2sev`, including policy exposure, claim counts, risk features, and claim amounts.

Do not bundle the full dataset into this skill. The full data is too large for a fast skill package and may carry redistribution/licensing constraints.

## Loader Behavior

Use `scripts/load_fremtpl_demo.R`.

- If `CASdatasets` is installed, load `freMTPL2freq`.
- Clean obvious invalid exposure and cap extreme claim counts for demo stability.
- Add deterministic pseudo-period fields for train/validation/test demonstration because the public dataset is mostly one-year exposure and does not include a normal pricing time split.
- Create a small deterministic fixture with a fixed seed.
- If `CASdatasets` is missing, stop with a clear optional dependency message.

## Demo Limitations

freMTPL is useful for workflow validation, but it is not a substitute for a user's pricing data. Note these limitations in reports:

- French motor TPL experience may not match the user's jurisdiction or product.
- Some variables are anonymized or country-specific.
- Demo pseudo-period splits are illustrative, not real future validation.
- Regulatory and fairness review still depends on the user's jurisdiction.
