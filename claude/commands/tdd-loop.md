# TDD Loop

Iterative test-driven loop: write a failing test, make it pass, simplify, repeat until acceptance criteria are met.

## When to use

- A bug to reproduce and fix
- A small, well-scoped feature
- A function whose behavior can be expressed as assertions

Not for: exploratory spikes, infra setup, or UI-only work where tests are impractical.

## Your role

You drive a TDD cycle. The user stays in the loop — pause after each iteration and confirm before the next.

## Inputs required

Before starting, confirm:
- **Target**: bug description, feature, or function under test
- **Acceptance criteria**: observable, testable conditions that end the loop
- **Test command**: how to run tests (e.g. `pytest tests/foo.py -x`, `npm test -- foo`)
- **File boundaries**: which files/modules you may touch

If any is unclear, ask before starting.

## The cycle

Repeat until stop conditions are met.

### 1. Red — write a failing test
- Pick the smallest next behavior from the acceptance criteria
- Write a test that currently fails
- Run the test command, confirm red
- If it passes already: the behavior exists or the test is wrong — stop and check

### 2. Green — minimum code to pass
- Write the smallest change that makes the test pass
- No speculation, no extra logic, no refactor yet
- Run the test command, confirm green
- If other tests break: surface it, do not patch adjacent code silently

### 3. Refactor — simplify
- Only if green
- Only what is ugly *because of this change*
- Re-run tests after refactor
- Skip if nothing obvious to improve (no yak-shaving)

### 4. Report and decide
- State: test added, code changed, criteria left
- Ask user: next iteration or stop?

## Stop conditions

Stop when any of:
- All acceptance criteria have a passing test
- Two consecutive iterations hit the same failure (wrong approach)
- A change would require touching files outside the agreed boundary
- User interrupts

## Guard rails

- **Surgical**: only files in the agreed boundary. If a fix seems to require more, stop and ask.
- **No silent fixes**: if an existing test breaks, surface it before continuing.
- **One behavior per iteration**: no bundling multiple tests or fixes.
- **Test the behavior, not the implementation**: assertions describe *what*, not *how*.
- **No scope drift**: do not extend the target mid-loop ("while I'm here...").

## Output per iteration

```
## Iteration N
- Test added: [file::test_name]
- Test status: red → green
- Code changed: [files]
- Refactor: [yes — what / none]
- Remaining criteria: [N/M]
- Next: [proposed next test, or STOP]
```

## Transition

When the loop stops:
- Criteria met, green → `/commit` then `/pr`
- Stuck (same failure twice) → `/explore` to investigate root cause
- Scope drift → `/scope` to re-align

---

$ARGUMENTS
