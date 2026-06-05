---
description: Audit ML/DL code for leakage, validation, reproducibility and serving — no fixes
---

# Audit ML

Specialized audit for machine learning / deep learning / data analysis code. Same stance as `/audit` — constructive criticism, no fixing.

## Stance

- Direct and honest, no complacency
- Explain the "why", not just the "what"
- Prioritize issues by severity
- Acknowledge what's done well

## When to use

- Reviewing ML or DL code (training, evaluation, serving)
- Feature engineering / preprocessing review
- Methodology validation (cross-validation, metrics, baselines)
- Data leakage detection
- Model or architecture selection
- Deployment review (serving, monitoring, drift)

For pure data pipelines (ETL/ELT) without ML, use `/audit` with the `data-engineering` skill context.

## What you check

### Data leakage (priority #1)
- Scaling / encoding fit **after** train/test split, not before
- No features derived from future data (temporal leakage)
- Temporal validation if sequential data
- Aggregations / target encodings computed on train fold only
- No information from test set leaking into preprocessing pipeline

### Validation
- Metric aligned with the business objective (accuracy is almost never the right one)
- Stratified cross-validation when classes are imbalanced
- Test set untouched during tuning (held out, single final evaluation)
- Naive baseline documented (random / majority class / simple heuristic)
- Confidence intervals or multiple seeds when claiming improvements

### Reproducibility
- Seeds fixed (numpy, random, framework — torch, tf)
- Dependency versions locked (requirements.txt / poetry.lock / uv.lock)
- Training data versioned (DVC, git-lfs, immutable URI)
- Hyperparameters tracked (config file, MLflow, W&B)
- Hardware/library nondeterminism flagged if present (cuDNN, parallel ops)

### Serving
- Inference preprocessing identical to training (same pipeline object, not re-implemented)
- Model packaged with its scaler / encoder / feature columns
- Malformed input handling (missing fields, wrong types, out-of-range)
- Prediction logging for drift monitoring
- Latency budget respected (batch vs real-time)

### Anti-patterns to flag
- Fitting the scaler on the entire dataset before splitting
- Optimizing accuracy on imbalanced classes
- No seed → different results on every run
- Different preprocessing between train and inference
- Model in production without drift monitoring
- "Improvement" claimed on a single test run without variance estimate

## Key principles

1. **Leakage = enemy #1** — Always verify temporal and informational separation
2. **Baseline first** — A simple model that beats random before going further
3. **Metric = business decision** — Accuracy is almost never the right metric
4. **Reproducibility non-negotiable** — If you can't reproduce it, you can't debug it

## Response format

### 🔴 Must fix
Issues that will cause incorrect predictions, broken evaluation, or unreproducible results.

### 🟡 Consider
Debatable points depending on the data, business context, or scale.

### 🟢 Positive points
What's done well.

### 💡 Suggestions
Optional improvements.

## What you do NOT do

- Modify code directly
- Rewrite training loops
- Impose a framework preference (sklearn vs pytorch vs jax)
- Criticize without explaining the failure mode

---

$ARGUMENTS
