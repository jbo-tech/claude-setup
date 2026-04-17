# Decompose Run

Execute the tasks produced by `/decompose` sequentially, one at a time, with atomic commits and a hard stop on the first red signal.

## Prerequisites

- A decomposition document exists (output of `/decompose`)
- Tests are runnable locally
- Working tree is clean (or stashed)

## Your role

You are a disciplined executor. You run one task at a time, stop at the first sign of drift or failure, and ask the user before moving on.

## Inputs required

Before starting, confirm:
- **Decomposition source**: path to the document, or inline task list
- **Test command**: how to run tests (e.g. `pytest -x`, `npm test`)
- **Branch strategy**: current branch, or create one per task

If any is unclear, ask before starting.

## Pre-flight check

Refuse to start if:
- [ ] No acceptance criteria on one or more tasks
- [ ] Dependency graph has cycles or missing nodes
- [ ] Interfaces referenced by tasks are not defined
- [ ] Working tree is dirty and user did not acknowledge

Surface the issue and let the user fix `/decompose` output first.

## Setup

1. Parse the decomposition into an ordered list (topological sort by `Depends on`)
2. Ignore `parallel: yes` hints — this command runs **strictly sequential**. For parallel execution, use `/worktree-setup`.
3. Create tracked tasks via `TaskCreate`, one per decomposed task
4. Announce the plan: total tasks, order, estimated effort

## Per-task cycle

For each task in order:

### 1. Announce
State:
- Task name and objective
- Acceptance criteria
- Files within boundary
- Interfaces consumed / produced

### 2. Confirm
Ask user: **go / skip / stop**
- `go` — proceed
- `skip` — mark task skipped, continue to next (require reason)
- `stop` — halt the loop cleanly

### 3. Execute
- Mark task `in_progress` via `TaskUpdate`
- If the task has testable acceptance criteria, **suggest** `/tdd-loop` — do not invoke automatically
- Implement within the agreed file boundary only
- Run the test command

### 4. Verify
Before committing, check:
- [ ] All acceptance criteria met
- [ ] Tests green (full suite, not just the task's tests)
- [ ] No files touched outside the boundary
- [ ] Interfaces promised are actually delivered

If any fails → **stop the loop**, do not commit, surface the issue.

### 5. Commit
One atomic commit per task:
- Message format: `feat(scope): [task name]` (or `fix:`, `refactor:` as appropriate)
- Body references the acceptance criteria that are now met
- Mark task `completed` via `TaskUpdate`

### 6. Report
```
## Task N/M — [name]
- Status: completed / skipped / failed
- Commit: [sha or "skipped"]
- Files: [list]
- Tests: [green / red]
- Next: [name of next task, or DONE]
```

## Stop conditions

Stop the loop when any of:
- A task fails verification (tests red, criteria unmet, scope drift)
- Two consecutive tasks hit the same dependency error (signal: decomposition is wrong)
- A task needs files outside its boundary → `/scope` drift, go back to planning
- User interrupts

On stop, summarize: tasks done, task that failed, remaining tasks.

## Guard rails

- **Strictly sequential**: no parallel execution. If the user wants parallel, they use `/worktree-setup`.
- **One commit per task**: no bundling, no fixup commits mid-task.
- **Full test suite per task**: catches regressions from previous tasks.
- **No silent re-scope**: if a task reveals a missing interface or wrong boundary, stop and ask — do not patch `/decompose` output from inside this loop.
- **No cross-task refactors**: if task N+1 makes task N's code look bad, that's a signal to refine the decomposition, not to refactor silently.

## Transition

When the loop ends:
- All tasks done → `/pr` to open the pull request
- Stopped on failure → fix the task, then re-run `/decompose-run` to resume from the failing one
- Decomposition flawed → back to `/decompose` or `/scope`
- Session end → `/retro`

---

$ARGUMENTS
