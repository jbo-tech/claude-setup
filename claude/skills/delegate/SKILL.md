---
name: delegate
description: Delegate coding tasks to a cheaper agent CLI (Vibe CLI or OpenCode). Claude orchestrates and reviews the diff. Activates on "/delegate", "delegate this", "hand off", "offload this task". Do NOT activate for tasks requiring Claude-specific features (MCP tools, complex multi-file refactoring, architecture decisions).
---

# Delegate

Delegate implementation tasks to a cheaper coding agent. You orchestrate (decompose, write a focused prompt) and review (read the git diff). The agent executes autonomously.

## Explicit invocation overrides the gate

If the user invoked `/delegate` (or said "delegate this", "hand off", "offload this"), the decision is **already made** — delegate. The "When NOT to delegate" criteria below govern only *proactive* delegation (auto-mode, or deciding on your own whether to hand off). Do not re-litigate an explicit request.

The only valid reasons to refuse an explicit `/delegate` are **hard blockers**:
- No backend is installed/available, or
- The task genuinely requires an MCP tool the delegate agent cannot call.

In those cases, **say so and stop** — do not silently do the task yourself. "This feels complex / I'd do it better / it's faster if I handle it" is **not** a valid reason to override an explicit `/delegate`.

## When to delegate

- Well-defined implementation tasks ("add validation to this function", "write tests for X")
- File edits where the intent is clear and the scope is bounded
- Repetitive changes across multiple files

## When NOT to delegate (proactive mode only)

These criteria apply when **you** are deciding whether to hand off. They do **not** override an explicit `/delegate` (see above). Each must be **verifiable** — if you can't point to a concrete reason, the task is delegable.

- **Requires an MCP tool** — the delegate agent has none.
- **Touches more than ~5 files _and_ needs cross-file design decisions** that can't be written into the prompt as a flat spec. (Many-file mechanical edits are *ideal* delegation targets — count is not enough on its own.)
- **Security-sensitive code**: auth, crypto, secret handling, permissions, access control.
- **The goal itself is undefined** — open-ended exploration or debugging where you don't yet know what change to make. (Once the change is known, it's delegable.)

"Feels complex", "context matters", or "I'd do it better" are **not** criteria. If none of the above is concretely true, delegate.

## How to delegate

### Step 1 — Decompose

Break the user's request into a focused, self-contained prompt. The delegate agent has NO context from this conversation. Include:
- Exact file paths to modify
- What to change and why (be specific)
- Any constraints or patterns to follow

### Step 2 — Select task type

Before running the script, pick the right `--task` flag based on context:

| Context | `--task` | Model used | Tier |
|---|---|---|---|
| Python files, data scripts, ML code | `python` | MiniMax M3 (alt GLM-5.1) | complex |
| Simple edits in any other language | `coding` | DeepSeek V4-Flash | easy |
| README, docs, copywriting, descriptions | `marketing` | DeepSeek V4-Pro | medium |
| Complex / multi-file / unclear | _(omit)_ | DeepSeek V4-Pro / vibe (default) | medium |

When in doubt, omit `--task` — the default generalist backend handles all cases.

### Step 3 — Execute

Run the delegate script:

```bash
~/.claude/scripts/delegate.sh [--task <type>] <workdir> "<prompt>" [timeout]
```

- `--task`: optional — routes to the specialized backend for that type
- `workdir`: the project root (usually the current working directory)
- `prompt`: the focused instruction for the delegate agent
- `timeout`: optional, in seconds (default: from config)

The script selects the best available backend matching the task (by priority in `~/.config/claude-code/delegate.yaml`). Falls back to untagged generalist backends if no task-specific one is found.

### Step 3 — Review

After the script returns, read the output. It includes:
- Backend used and model
- Exit code and duration
- `git diff --stat` showing changed files

If exit code is 0 and the diff looks reasonable:
1. Run `git diff` to inspect the actual changes
2. Summarize what was done to the user
3. Flag any concerns (style issues, missing edge cases)

If exit code is non-zero:
1. Report the failure
2. Offer to retry with a refined prompt or handle it directly

## Auto-mode

When auto-mode is active (`.claude/delegate-auto` file exists in project root), delegate ALL implementation tasks automatically without asking. Still review every diff.

Check auto-mode: `test -f .claude/delegate-auto`

## Prompt writing guidelines

Good delegate prompts are:
- **Imperative**: "Add email validation to signup.py" not "Could you maybe look at..."
- **Specific**: Include exact file paths, function names, line references
- **Self-contained**: The agent knows nothing about our conversation
- **Bounded**: One clear task, not "improve the codebase"
- **Scope-locked** (mandatory): Always end with an explicit scope boundary

### Scope-lock rule

Every delegate prompt MUST end with a scope boundary line:

> You must ONLY edit the file(s) at: [list exact paths]. Do not create, delete, or modify any other file.

This prevents the delegate agent from "helpfully" refactoring adjacent files. Cheap models have weak instruction-following on scope boundaries — the explicit constraint is the only reliable guard.

### Example prompts

Good:
> In src/auth/signup.py, add email format validation to the `validate_email()` function (line 42). Use a regex pattern. Return False for invalid emails. Add 3 test cases in tests/test_signup.py. You must ONLY edit the files at: src/auth/signup.py, tests/test_signup.py. Do not create, delete, or modify any other file.

Bad:
> Fix the email thing we discussed earlier.
