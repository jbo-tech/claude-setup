# Delegate

Delegate a coding task to a cheaper agent CLI. You orchestrate and review.

## Syntax

```
/delegate [--backend <name>] <instruction>
```

- `--backend vibe` or `--backend opencode` forces a specific backend
- Without `--backend`, the script picks the first enabled backend by priority

## Process

1. **Decompose** the user's instruction into a focused, self-contained prompt
   - Include exact file paths, function names, constraints
   - The delegate agent has NO context from this conversation
   - End every prompt with the scope-lock line (see SKILL.md)

2. **Execute** by running:
   ```bash
   ~/.claude/scripts/delegate.sh [--backend <name>] "$(pwd)" "<your focused prompt>" [timeout]
   ```

3. **Review** the output:
   - Check exit code (0 = success)
   - Read the `git diff --stat` summary
   - If successful, run `git diff` to inspect actual changes
   - Verify ONLY the expected files were modified (scope-lock check)
   - Summarize results and flag any concerns

## Rules

- Always decompose before delegating — never pass the user's raw message
- Always end the prompt with the scope-lock boundary
- Always review the diff — never report success without inspecting changes
- If files outside scope were modified, revert and retry with a narrower prompt
- If the delegate fails, offer to retry with a refined prompt or handle directly
