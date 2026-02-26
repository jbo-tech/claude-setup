---
name: ml-review
description: Best practices for machine learning, deep learning and data analysis. Activates when the user mentions "model", "training", "features", "cross-validation", "accuracy", "overfitting", "data leakage", "preprocessing", "sklearn", "pytorch", "tensorflow", "neural network", "regression", "classification". Do NOT use for ETL pipelines or data quality (use data-engineering).
---

# ML Review

Guidance for designing, validating and deploying ML/DL models.

## When this skill activates

- Reviewing ML or deep learning code
- Questions about feature engineering or preprocessing
- Methodology validation (cross-validation, metrics)
- Data leakage detection
- Model or architecture selection
- Model deployment (serving, monitoring)

## Quick checklist

### Data Leakage
- Scaling/encoding AFTER train/test split
- No features derived from future data
- Temporal validation if sequential data
- Aggregations computed on train set only

### Validation
- Metric aligned with business objective
- Stratified cross-validation if imbalanced data
- Test set never touched during tuning
- Naive baseline documented

### Reproducibility
- Seeds fixed (numpy, random, framework)
- Dependency versions locked
- Training data versioned
- Hyperparameters tracked

### Serving
- Inference preprocessing identical to training
- Model packaged with scaler/encoder
- Malformed input handling
- Prediction logging for monitoring

## Key principles

1. **Leakage = enemy #1** — Always verify temporal and informational separation
2. **Baseline first** — A simple model that beats random before going further
3. **Metric = business decision** — Accuracy is almost never the right metric
4. **Reproducibility non-negotiable** — If you can't reproduce it, you can't debug it

## Anti-patterns

- Fitting the scaler on the entire dataset before splitting
- Optimizing accuracy on imbalanced classes
- No seed → different results on every run
- Different preprocessing between train and inference
- Model in production without drift monitoring

## When to escalate to @data-ml-expert

Use the full agent for:
- In-depth ML/DL code review with detailed checklists
- End-to-end ML pipeline audit
- Complex model architecture choices
- Deployment review (API, Streamlit, Gradio)
- When structured review format (critical/warning/positive) is needed
