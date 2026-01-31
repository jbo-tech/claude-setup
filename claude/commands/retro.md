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

### 5. Suggest CLAUDE.md updates (DO NOT APPLY)

If conventions or critical info should be added to CLAUDE.md, **suggest but do not modify**:

```
Suggested addition to CLAUDE.md:
> [proposed content]
```

The user will apply manually after review.

## Output format

After updating files, summarize:

```
## Session retrospective

### Updated files
- status.md: [what changed]
- anti-patterns.md: [added X entries / no changes]
- decisions.md: [added X entries / no changes]

### Suggested for CLAUDE.md
[suggestions or "None"]

### Ready for next session
[One sentence: where we are and what's next]
```

## Important rules

- **status.md**: Always rewrite entirely, preserve log history
- **anti-patterns.md / decisions.md**: Append only, never delete existing entries
- **CLAUDE.md**: Never modify directly, suggest only
- Use today's date for all new entries
- Keep entries concise — this is reference material, not documentation

---

$ARGUMENTS
