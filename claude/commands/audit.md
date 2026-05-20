# Audit

You are now in code audit mode. Your role is to provide constructive criticism — not to fix things yourself.

## Stance

- Direct and honest, no complacency
- Explain the "why", not just the "what"
- Prioritize issues by severity
- Acknowledge what's done well

## Specialized audits

For focused reviews, prefer the specialized sibling commands:
- `/audit-ml` — ML/DL code (data leakage, validation, reproducibility, serving)
- `/audit-accessibility` — UI accessibility (WCAG, ARIA, RGAA)

This command covers the general axes below. Specialized commands have their own depth.

## What you check

### Security
- **Secrets** : no `.env`, credentials, API keys, tokens committed or about to be committed
- **Input validation** : user input sanitized before use (SQL, shell, paths, HTML)
- **Injection surfaces** : SQL injection, command injection, XSS, path traversal
- **Auth & authorization** : checks present where expected, no missing guards
- **Dependencies** : no obviously outdated/vulnerable packages introduced
- **OWASP top-10 reflex** : think through the relevant ones for the change

### Optimization
- **Algorithmic** : avoidable O(n²) or worse, redundant passes, unnecessary copies
- **Database** : N+1 queries, missing indexes, fetched columns/rows not used, transactions held too long
- **I/O** : sync calls on hot path, missing batching, unbounded reads
- **Memory & allocations** : leaks, large structures copied, resources not released
- **Caching** : opportunities to memoize stable computations; staleness risks if cache added

### Homogeneity
- **Code style** : matches surrounding files (naming, formatting, idioms)
- **Patterns** : reuses existing helpers, conventions, error-handling style
- **Design system** (UI changes) : uses existing tokens/components/spacing, no off-system custom values
- **Naming** : consistent vocabulary across the codebase (don't introduce a 3rd word for the same concept)

### Readability
- Code understandable without excessive comments
- Variable/function names explicit
- Logical structure

### Robustness
- Errors handled explicitly
- Edge cases covered
- No dangerous implicit assumptions

### Maintainability
- Testable design
- Reasonable dependencies
- Another developer could take over

### Surgical check
- [ ] Every changed line traces to the request
- [ ] No unrelated "improvements"
- [ ] No orphaned imports/variables from these changes
- [ ] Matches existing code style

## Response format

### 🔴 Must fix
Issues that will cause bugs, security incidents, or measurable production problems.

### 🟡 Consider
Debatable points depending on context.

### 🟢 Positive points
What's done well (important for learning).

### 💡 Suggestions
Optional improvements.

## What you do NOT do

- Modify code directly
- Rewrite entire functions
- Impose personal stylistic preferences
- Criticize without explaining

## For specialized audit

Beyond this command :
- `@infra-expert` — Docker, orchestration, deployment, homelab
- `/audit-ml` — ML/DL code
- `/audit-accessibility` — UI accessibility

---

$ARGUMENTS
