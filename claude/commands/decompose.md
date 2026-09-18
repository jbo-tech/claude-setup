---
description: Break a scoped project into parallelizable, conflict-free tasks
---

# Decompose

Break down a scoped project into parallelizable tasks.

## Prerequisites

This command works best after `/scope` (what, why, and the technical approach). Read
`.claude/context/scope.md` first if it exists.

## Your role

You are a technical lead breaking down work for parallel execution. Your goal: **independent
tasks that each end in something observable**, and that can be worked on simultaneously without
conflicts.

## The unit of work: a vertical slice

A task is a **vertical slice** — one user-visible outcome plus everything it needs, through every
layer. It is never "the data layer" or "the API layer".

| | Layer task | Slice task |
|---|---|---|
| Example | "build the storage models" | "a query returns a ranked answer, end to end" |
| Done when | the code exists | someone can run it and see the result |
| Risk | all of it lands in the integration phase | paid down slice by slice |

**Why this matters here**: `builder` refuses a task whose criterion it cannot verify. A layer has
no observable outcome, so the criterion degrades to "the code looks right" — which is exactly the
kind of task that comes back three times. A slice carries its own verification.

**What a slice is when there is no screen.** In a pipeline or a library, the visible outcome is an
output, not a page: a digest produced, an evaluation score computed, an alert fired, a CLI command
that returns the right thing. If you cannot name the observable outcome, you do not have a slice
yet — go back to `/scope`.

**The cost, stated plainly**: slices share code. Two slices both touch the models, the config, the
common helpers. That is why the foundation comes first and alone (Phase 1 below) — parallel slices
are only conflict-free above a foundation that has stopped moving.

## Process

### 1. Identify the slices

List the user-visible outcomes the scope promises. Each one is a candidate slice. For each, name:
- the outcome, in one sentence, as something a person can observe;
- what it touches, top to bottom.

Order them the way a user meets them, not the way the code is layered.

### 2. Define the foundation

Everything two or more slices need: shared data structures, contracts between components,
configuration, the project skeleton. This is Phase 1, it is **sequential**, and it is the one part
that must be right before anything else starts.

Keep it thin. A foundation that tries to anticipate every slice is a layer decomposition wearing a
different name. If you are unsure whether something belongs to the foundation, leave it in the
first slice that needs it and promote it later.

Document the shared contracts in an `## Interfaces` section.

### 3. Size each slice

A slice is one task when it is small enough to verify in one pass. Count the **data movements**
that cross the slice's boundary — each input read in, each output written out, each store read,
each store written. Four to six movements is one task. Beyond that, split along the boundary that
removes the most movements.

This is a rough adaptation of functional-size counting (COSMIC function points), used here only as
a splitting heuristic, not as an estimate of effort. It replaces "completable in one session,
~2-4h", which an agent has no way to evaluate.

### 4. Create the task breakdown

For each task:

```markdown
## Task: [Name]

**Branch**: `feature/[epic]-[task-name]`
**Phase**: foundation | slice | integration
**Parallel**: [yes/no]
**Depends on**: [other tasks or "none"]
**Data movements**: [count]

### Observable outcome
[One sentence: what a person can see or run when this is done. For a foundation task, state
instead what it unblocks — a foundation task is the one exception to the rule.]

### Scope
- [ ] [Deliverable 1]
- [ ] [Deliverable 2]

### Interfaces
- Consumes: [what it needs from the foundation or another slice]
- Produces: [what it provides to later slices]

### Acceptance criteria
- [ ] [The check that proves the outcome — a command and its expected result]

### Files likely touched
- `src/[path]`
- `tests/[path]`
```

### 5. Validate parallelizability

Check:
- [ ] Every slice task names an observable outcome
- [ ] Tasks marked "parallel: yes" have no file overlap
- [ ] Everything shared by two slices is in the foundation, and the foundation is Phase 1
- [ ] Dependencies form a DAG (no cycles)
- [ ] No task exceeds its data-movement budget without being split

### 6. Check the first task can actually run

The first task of a brand-new project often creates the repository itself. `builder` runs under
`isolation: worktree`, and a worktree cannot be created in a directory that is not yet a git
repository — the spawn fails before the agent starts. If Phase 1 includes `git init` or the initial
skeleton, do that step in the main session and start delegating at the next task.

## Output format

```markdown
# [Epic Name] — Task Decomposition

## Overview
- **Total tasks**: N
- **Slices**: S
- **Parallelizable**: M

## Interfaces (define first!)

### [Interface 1]
[Contract definition]

## Dependency Graph

```
[foundation]
     ↓
┌────┴────┬─────────┐
↓         ↓         ↓
[slice 1] [slice 2] [slice 3]   ← parallel
└────┬────┴─────────┘
     ↓
[integration]
```

## Tasks

### Phase 1: Foundation (sequential)
[Task 1]

### Phase 2: Slices (parallel)
[Task 2]
[Task 3]

### Phase 3: Integration (sequential, thin)
[Task 4]
```

## Rules

1. **A slice, not a layer**: each task ends in something observable
2. **Foundation first, thin**: only what two or more slices share
3. **Interface-first**: shared contracts defined before implementation tasks
4. **Sized by data movements**: split when the count crosses the budget
5. **Test included**: each task carries the check that proves its outcome

## Transition

When decomposition is solid:
- Do the foundation task in this session — it often creates the repo, and a `builder` worktree
  cannot be created in a directory that is not yet one.
- Then hand each slice to `builder` (it gets its own worktree, created and cleaned for you) or to
  `/delegate` when an external model is cheap enough to earn the round trip.

---

$ARGUMENTS
