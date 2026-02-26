---
name: data-engineering
description: Best practices for data pipelines, ETL/ELT, data quality and storage. Activates when the user mentions "pipeline", "ETL", "data quality", "parquet", "duckdb", "ingestion", "orchestration", "data pipeline", "schema validation", "idempotent". Do NOT use for machine learning or statistical analysis (use ml-review).
---

# Data Engineering

Guidance for designing and reviewing data pipelines.

## When this skill activates

- Designing or reviewing ETL/ELT pipelines
- Questions about data quality or schema validation
- Choosing storage formats (Parquet, DuckDB, CSV)
- Configuring orchestrators (Kestra, Airflow, Prefect)
- Idempotency or error recovery issues

## Quick checklist

Before validating a pipeline, check:

### Ingestion
- Schema validation at entry point
- API error handling (retry, backoff, timeout)
- Documented backfill strategy

### Transformation
- Idempotent operations
- No dependency on execution order
- Explicit null value handling
- Partitioning aligned with query patterns

### Storage
- Format suited to use case (row vs columnar)
- Compression enabled
- Versioned metadata
- Retention strategy defined

### Orchestration
- Idempotent tasks with timeout
- Explicit failure handling (retry, allowFailure)
- Triggers with explicit timezone
- Backfill strategy if applicable

## Key principles

1. **Idempotency everywhere** — Replaying a pipeline must never corrupt data
2. **Schema first** — Validate structure before processing content
3. **Fail loud** — Log anomalies, not just errors
4. **Partition smartly** — Align with read patterns, not write patterns

## Anti-patterns

- Pipeline that depends on execution time for its logic
- Transformation that reads and writes to the same table
- Implicit schema ("it works because the CSV always has 5 columns")
- No recovery strategy after crash

## When to escalate to @data-ml-expert

Use the full agent for:
- In-depth review of a complex pipeline
- Data quality audit on an existing system
- Data architecture choices (batch vs streaming, lake vs warehouse)
- When detailed checklists and structured review format are needed
