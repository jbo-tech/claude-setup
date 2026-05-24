---
name: delegate
description: Delegate coding tasks to a cheaper agent CLI (Vibe CLI or OpenCode). Claude orchestrates and reviews the diff. Activates on "/delegate", "delegate this", "hand off", "offload this task". Do NOT activate for tasks requiring Claude-specific features (MCP tools, complex multi-file refactoring, architecture decisions).
---

# Delegate

Delegate implementation tasks to a cheaper coding agent. You orchestrate (decompose, write a focused prompt) and review (read the git diff). The agent executes autonomously.

## When to delegate

- Well-defined implementation tasks ("add validation to this function", "write tests for X")
- File edits where the intent is clear and the scope is bounded
- Repetitive changes across multiple files

## When NOT to delegate

- Architecture decisions or design exploration
- Tasks requiring MCP tools or Claude-specific features
- Security-sensitive code changes
- Complex multi-file refactoring where context matters
- Debugging sessions requiring back-and-forth

## How to delegate

### Step 1 — Decompose

Break the user's request into a focused, self-contained prompt. The delegate agent has NO context from this conversation. Include:
- Exact file paths to modify
- What to change and why (be specific)
- Any constraints or patterns to follow

### Step 2 — Execute

Run the delegate script:

```bash
~/.claude/scripts/delegate.sh <workdir> "<prompt>" [timeout]
```

- `workdir`: the project root (usually the current working directory)
- `prompt`: the focused instruction for the delegate agent
- `timeout`: optional, in seconds (default: from config)

The script automatically selects the best available backend (by priority in `~/.config/claude-code/delegate.yaml`).

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

### Example prompts

Good:
> In src/auth/signup.py, add email format validation to the `validate_email()` function (line 42). Use a regex pattern. Return False for invalid emails. Add 3 test cases in tests/test_signup.py.

Bad:
> Fix the email thing we discussed earlier.
