# Domain Knowledge Template

Use this template for skills about specific technologies, APIs, or domains.

```markdown
---
name: [technology-name]
description: [Technology] best practices and patterns. Triggers on [keyword1], [keyword2], [keyword3].
---

# [Technology Name]

## When to use
- Working with [technology]
- [Specific use cases]

## Key concepts

### [Concept 1]
[Explanation]

### [Concept 2]
[Explanation]

## Best practices

### [Practice 1]
[What to do and why]

```[language]
# Example code
```

### [Practice 2]
[What to do and why]

## Common patterns

### [Pattern name]
**When**: [situation]
**How**:
```[language]
# Pattern implementation
```

## Anti-patterns

### ❌ [Anti-pattern 1]
[What not to do]
```[language]
# Bad example
```

**Instead**:
```[language]
# Good example
```

### ❌ [Anti-pattern 2]
[What not to do and why]

## Quick reference

| Task | Command / Code |
|------|----------------|
| [Task 1] | `[code]` |
| [Task 2] | `[code]` |

## Gotchas
- [Non-obvious thing 1]
- [Non-obvious thing 2]
```

---

## Variables to replace

| Variable | Description | Example |
|----------|-------------|---------|
| `[technology-name]` | Lowercase identifier | `duckdb`, `kestra` |
| `[keyword1,2,3]` | Trigger words | `duckdb, analytics, olap` |
| `[Concept]` | Key concept to understand | `Vectorized execution` |
| `[Practice]` | Recommended approach | `Use CTEs for readability` |
| `[Pattern]` | Reusable code pattern | `Incremental load pattern` |

## Example skills

| Skill | Triggers on | Content |
|-------|-------------|---------|
| DuckDB | duckdb, analytics, parquet | Query patterns, performance tips, anti-patterns |
| Kestra | kestra, workflow, orchestration | Flow structure, triggers, error handling |
| Plex API | plex, media server, library | API endpoints, scan optimization, metadata |
