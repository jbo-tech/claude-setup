---
name: data-engineering
description: Best practices for open-source data pipelines, ETL/ELT, data quality and storage. Activates when the user mentions "pipeline", "ETL", "data quality", "parquet", "duckdb", "kestra", "minio", "ingestion", "orchestration", "data pipeline", "schema validation", "idempotent". Do NOT use for machine learning or statistical analysis (use /audit-ml). For managed/commercial stacks (Snowflake, Databricks, dbt Cloud, Airflow on Astronomer), defer to astronomer-data plugin if available.
---

# Data Engineering

Guidance for designing and reviewing open-source data pipelines.

## Scope

**In scope** (open-source stack) :
- DuckDB, Parquet, CSV, JSON Lines
- Kestra, Airflow (self-hosted), Prefect (self-hosted)
- MinIO, local filesystem, rclone-mounted storage
- Generic ETL/ELT patterns, schema validation, idempotency

**Out of scope** — defer to specialized plugins :
- Airflow on Astronomer / managed Airflow → `astronomer-data` plugin
- dbt Core / dbt Fusion → `astronomer-data:cosmos-*` skills
- Snowflake / Databricks / BigQuery managed warehouses → `astronomer-data`
- Pure ML/DL code → `/audit-ml`

## When this skill activates

- Designing or reviewing ETL/ELT pipelines on an open-source stack
- Questions about data quality or schema validation
- Choosing storage formats (Parquet, DuckDB, CSV)
- Configuring self-hosted orchestrators (Kestra, Airflow, Prefect)
- Idempotency or error recovery issues

## Quick checklist

Before validating a pipeline, check :

### Ingestion
- Schema validation at entry point (pydantic, Great Expectations, manual)
- API error handling (retry, backoff, timeout)
- Documented backfill strategy
- Source-of-truth identified (no implicit "the file that arrives in `/incoming`")

### Transformation
- Idempotent operations (replay-safe)
- No dependency on execution order
- Explicit null value handling
- Partitioning aligned with query patterns
- DuckDB used for in-process aggregations rather than re-implementing SQL in Python

### Storage
- Format suited to use case (Parquet for columnar reads, JSONL for streaming append)
- Compression enabled (zstd / snappy)
- Versioned metadata (manifest file, table version)
- Retention strategy defined
- MinIO buckets with lifecycle rules if applicable

### Orchestration (Kestra / Airflow / Prefect)
- Idempotent tasks with timeout
- Explicit failure handling (retry, allowFailure, onError)
- Triggers with explicit timezone
- Backfill strategy if applicable
- DAG/flow size kept readable (split if > 20 tasks)

## Key principles

1. **Idempotency everywhere** — Replaying a pipeline must never corrupt data
2. **Schema first** — Validate structure before processing content
3. **Fail loud** — Log anomalies, not just errors
4. **Partition smartly** — Align with read patterns, not write patterns
5. **Local before remote** — Prototype with local files and DuckDB before touching MinIO/S3

## Anti-patterns

- Pipeline that depends on execution time for its logic
- Transformation that reads and writes to the same table
- Implicit schema ("it works because the CSV always has 5 columns")
- No recovery strategy after crash
- Pandas for everything when DuckDB / polars would handle the volume in seconds
- Re-implementing dbt features by hand instead of delegating to the dbt-via-Cosmos path (see `astronomer-data`)
