# Workflow Pattern Template

Use this template for skills about repeatable processes or methodologies.

```markdown
---
name: [workflow-name]
description: [Workflow] pattern for [goal]. Triggers on [keyword1], [keyword2], [keyword3].
---

# [Workflow Name]

## When to use
- [Situation 1]
- [Situation 2]
- [Trigger condition]

## Overview

[1-2 sentences: what this workflow achieves]

## Process

### Step 1: [Name]
**Goal**: [What this step achieves]
**Actions**:
1. [Action 1]
2. [Action 2]

**Output**: [What you have after this step]

### Step 2: [Name]
**Goal**: [What this step achieves]
**Actions**:
1. [Action 1]
2. [Action 2]

**Checkpoint**: [How to verify this step is done correctly]

### Step 3: [Name]
...

## Decision points

### [Decision 1]
**If** [condition A]: [do X]
**If** [condition B]: [do Y]

### [Decision 2]
**If** [condition]: [do Z]
**Otherwise**: [skip / alternative]

## Checklist

Before starting:
- [ ] [Prerequisite 1]
- [ ] [Prerequisite 2]

During:
- [ ] [Step 1 complete]
- [ ] [Step 2 complete]
- [ ] [Checkpoint verified]

After:
- [ ] [Verification 1]
- [ ] [Verification 2]

## Anti-patterns

### ❌ [Anti-pattern 1]
[What not to do]
**Why it fails**: [consequence]
**Instead**: [correct approach]

### ❌ [Anti-pattern 2]
[What not to do]

## Examples

### Example 1: [Scenario]
[Walkthrough of applying the workflow]

### Example 2: [Different scenario]
[How the workflow adapts]

## Variations

### [Variation 1]: [When to use]
[How the workflow changes]

### [Variation 2]: [When to use]
[How the workflow changes]
```

---

## Variables to replace

| Variable | Description | Example |
|----------|-------------|---------|
| `[workflow-name]` | Lowercase identifier | `feature-engineering`, `api-design` |
| `[keyword1,2,3]` | Trigger words | `features, engineering, preprocessing` |
| `[goal]` | What the workflow achieves | `building ML features` |
| `[Step N]` | Process step | `Data exploration`, `Feature creation` |
| `[Decision]` | Branch point | `Categorical vs numerical handling` |

## Example workflows

| Workflow | Triggers on | Process |
|----------|-------------|---------|
| Feature engineering | features, preprocessing, ML | Explore → Create → Validate → Document |
| API design | api, endpoints, REST | Resources → Endpoints → Validation → Docs |
| Data validation | validation, quality, checks | Schema → Constraints → Tests → Report |
| Code review | review, PR, quality | Understand → Analyze → Feedback → Verify |
