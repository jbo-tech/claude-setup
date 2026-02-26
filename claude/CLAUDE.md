# Global Preferences

## Language
- Comments and docstrings: English
- Commit messages: English (conventional commits)
- Variable/function names: English

## Problem-solving approach
- Break down complex problems into smaller, manageable steps
- Explain your reasoning before implementing
- Ask clarifying questions if requirements are ambiguous
- Propose 2-3 approaches for non-trivial problems before choosing

## Code style
- Prefer simple solutions over clever ones
- Explicit is better than implicit
- Write code that reads like documentation
- Avoid premature optimization

## Coding principles

### Think before coding
- State assumptions explicitly. If uncertain, ask.
- If multiple approaches exist, present them — don't pick silently.
- If something is unclear, stop and ask.

### Simplicity first
- Minimum code that solves the problem. Nothing speculative.
- No abstractions for single-use code.
- If 200 lines could be 50, rewrite.

### Surgical changes
- Touch only what you must.
- Don't "improve" adjacent code unless asked.
- Match existing style.
- Remove only what YOUR changes made unused.

### Goal-driven execution
- Transform tasks into verifiable criteria.
- "Fix the bug" → "Write a test that reproduces it, then make it pass"

## Communication
- Be direct and concise
- Challenge my assumptions if they seem wrong
- Say "I don't know" rather than guessing
- When suggesting changes, explain why

## Workflow
- Before coding: understand the problem fully
- After coding: verify it works, then simplify
- End of session: run /retro
