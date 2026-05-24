# Delegate

Delegate a coding task to a cheaper agent CLI. You orchestrate and review.

## Process

1. **Decompose** the user's instruction into a focused, self-contained prompt
   - Include exact file paths, function names, constraints
   - The delegate agent has NO context from this conversation

2. **Execute** by running:
   ```bash
   ~/.claude/scripts/delegate.sh "$(pwd)" "<your focused prompt>" [timeout]
   ```

3. **Review** the output:
   - Check exit code (0 = success)
   - Read the `git diff --stat` summary
   - If successful, run `git diff` to inspect actual changes
   - Summarize results and flag any concerns

## Rules

- Always decompose before delegating — never pass the user's raw message
- Always review the diff — never report success without inspecting changes
- If the delegate fails, offer to retry with a refined prompt or handle directly
