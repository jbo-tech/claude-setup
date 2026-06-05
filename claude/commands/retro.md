---
description: End-of-session retrospective — update project context files
---

# Retro

End-of-session retrospective. Analyze the session and update project context files automatically.

## Your tasks

### 1. Analyze the session

Review what happened:
- What was accomplished?
- What problems were encountered?
- What technical decisions were made?
- What's the current state of the work?
- What should happen next?

### 2. Update status.md (REPLACE)

Rewrite `.claude/context/status.md` entirely:

```markdown
# Status

## Objective
[Main goal - keep or update based on session]

## Current focus
[What we're working on now]

## Log

### [TODAY'S DATE]
- Done: [completed items]
- Blocked: [blockers if any]
- Next: [immediate next steps]

[KEEP PREVIOUS LOG ENTRIES BELOW - newest first]
```

### 3. Update anti-patterns.md (APPEND if needed)

If errors or pitfalls were discovered, append to `.claude/context/anti-patterns.md`:

```markdown
### [Short title]
**Problem**: [What went wrong]
**Cause**: [Why it happened]
**Solution**: [How to fix/avoid]
**Date**: [TODAY'S DATE]
```

Only add entries for **reusable learnings**, not one-time typos or trivial mistakes.

### 4. Update decisions.md (APPEND if needed)

If technical decisions were made, append to `.claude/context/decisions.md`:

```markdown
### [Decision title]
**Decision**: [What was decided]
**Context**: [Why this choice]
**Alternatives considered**: [What else was considered]
**Date**: [TODAY'S DATE]
```

Only add entries for **significant decisions** that affect project direction.

### 5. Update CLAUDE.md (APPLY)

If conventions or critical info should be added to CLAUDE.md, **apply the changes directly**. The user will review via `git diff` after the retro.

### 6. Update README.md (APPLY)

If the session changed functionality, usage, structure or dependencies, and a README.md exists at the project root, **apply the updates directly**. The user will review via `git diff` after the retro.

### 7. Learning loop — capitalize (LIGHT, CONSERVATIVE, AUDITABLE)

Turn this session's learnings into durable rules **at the right level**, without
polluting context. **Propose, never auto-apply** to CLAUDE.md or skills. Only the
candidate ledger updates silently (zero risk). Keep it light: one grouped block, no
heavy analysis. If proposals get noisy, raise thresholds rather than add machinery.

**3 axes** (a learning is qualified by all three, independently):
- **Confidence** — promote only if: explicit user directive ("always/never/from now on")
  → 1× is enough; OR recurrence ≥ 3; OR high cost-of-error. Otherwise it stays staged.
- **Scope** — where it applies → picks the destination (see matrix).
- **Relevance** — still true? Obsolete/contradicted rules trigger a purge proposal.

**Candidate ledger** (`_candidates.jsonl` in this project's memory dir — same folder as
`MEMORY.md`, kept OUT of the index so it costs no context):
```json
{"fingerprint":"stable-kebab-slug","summary":"one line","scope_guess":"cross-project|project|tech",
 "count":2,"first_seen":"YYYY-MM-DD","last_seen":"YYYY-MM-DD","explicit":false,"high_cost":false}
```

**Steps:**
1. Extract this session's learnings (explicit directives, recurring patterns, errors, decisions).
2. Update the ledger: for each, find a *semantically equivalent* candidate (not exact wording)
   and increment `count` + `last_seen`; else add a new entry (`count:1`). Plain JSONL read/write.
3. **Promotion** — for candidates crossing the threshold (`explicit` OR `count>=3` OR `high_cost`),
   route by the matrix and **propose** each (do not apply). On approval: write to the destination,
   then remove the candidate from the ledger.
4. **Purge** — propose (never auto) removing rules that name an absent file/symbol/flag, are
   contradicted by a newer decision, or are dormant low-count candidates.

**Routing matrix** (destination by scope, only once confidence is confirmed):
| Scope | Destination |
|---|---|
| Cross-project | `~/.claude/CLAUDE.md` (global) + memory `type:feedback\|user` |
| Project | `.claude/context/*` (**canonical at project level**) + project `CLAUDE.md` |
| Tech / transferable pattern | a reusable **skill** (skill-factory) |

`.claude/context/*` is the source of truth for project-level learnings; `memory/` holds only
cross-project/global. Never infer scope silently — the user confirms each promotion.

### 8. Docs freshness — flag only (do NOT rewrite)

If `docs/architecture.md` exists with a `generated_from_commit` front-matter stamp, compare it
to HEAD **excluding the docs themselves** (a doc isn't stale because it was committed):
`git diff --stat <stamp>..HEAD -- . ':(exclude)docs/'`. If meaningful code changed since, flag that
the orientation docs may be stale and suggest running `/document`. Never regenerate them here —
regeneration is `/document`'s job and stays an explicit choice. Skip silently if no such docs.

## Output format

After updating files, summarize:

```
## Session retrospective

### Updated files
- status.md: [what changed]
- anti-patterns.md: [added X entries / no changes]
- decisions.md: [added X entries / no changes]

### CLAUDE.md
[changes applied / no changes]

### README.md
[changes applied / no changes]

### Learning loop
- Promoted: [item → destination (trigger: explicit / count=N / high-cost) | none]
- Purged: [rule removed (reason) | none]
- Staged: [candidate (count=N) still below threshold | none]

### Docs freshness
[orientation docs may be stale — run /document (N files changed since stamp) | up to date | n/a]

### Ready for next session
[One sentence: where we are and what's next]
```

The Learning loop block must be **auditable**: for every promotion/purge, state which axis
triggered it (explicit / count / cost / obsolete) so the decision can be replayed.

## Important rules

- **status.md**: Always rewrite entirely, preserve log history
- **anti-patterns.md / decisions.md**: Append by default; delete only via an approved purge proposal (step 7)
- **CLAUDE.md / README.md**: Apply changes directly, user reviews via `git diff`
- **Learning loop (step 7)**: ledger updates silently; promotions/purges are always proposed, never auto-applied
- Use today's date for all new entries
- Keep entries concise — this is reference material, not documentation

---

$ARGUMENTS
