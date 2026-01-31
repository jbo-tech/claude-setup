# Decompose

Break down a scoped project into parallelizable tasks.

## Prerequisites

This command works best after:
- `/prd` (product requirements defined)
- `/scope` (technical architecture defined)

Read these documents first if they exist.

## Your role

You are a technical lead breaking down work for parallel execution. Your goal: **independent tasks that can be worked on simultaneously without conflicts**.

## Process

### 1. Identify natural boundaries

Look for:
- **Layers**: data, API, UI, infra
- **Features**: auth, billing, notifications
- **Modules**: independent components with clear interfaces

### 2. Define interfaces first

Before decomposing, clarify:
- What data structures are shared?
- What APIs will modules use to communicate?
- What contracts must be respected?

Document these in a `## Interfaces` section.

### 3. Create task breakdown

For each task:

```markdown
## Task: [Name]

**Branch**: `feature/[epic]-[task-name]`
**Estimated effort**: [S/M/L or hours]
**Parallel**: [yes/no]
**Depends on**: [other tasks or "none"]

### Objective
[One sentence: what this task delivers]

### Scope
- [ ] [Deliverable 1]
- [ ] [Deliverable 2]
- [ ] [Deliverable 3]

### Interfaces
- Consumes: [what it needs from other tasks]
- Produces: [what it provides to other tasks]

### Acceptance criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]

### Files likely touched
- `src/[path]`
- `tests/[path]`
```

### 4. Validate parallelizability

Check:
- [ ] Tasks marked "parallel: yes" have no file overlap
- [ ] Interfaces are defined before implementation tasks
- [ ] Dependencies form a DAG (no cycles)
- [ ] Each task is completable in one session (~2-4h)

## Output format

```markdown
# [Epic Name] — Task Decomposition

## Overview
- **Total tasks**: N
- **Parallelizable**: M
- **Sequential**: N-M
- **Estimated total effort**: [X hours sequential, Y hours with parallelism]

## Interfaces (define first!)

### [Interface 1]
[Contract definition]

### [Interface 2]
[Contract definition]

## Dependency Graph

```
[setup] 
    ↓
[interfaces]
    ↓
┌───┴───┐
↓       ↓
[api]  [ui]  ← parallel
↓       ↓
└───┬───┘
    ↓
[integration]
```

## Tasks

### Phase 1: Setup (sequential)
[Task 1]

### Phase 2: Core (parallel)
[Task 2]
[Task 3]
[Task 4]

### Phase 3: Integration (sequential)
[Task 5]
```

## Rules

1. **Smallest viable task**: Can be completed and tested independently
2. **Clear boundaries**: No ambiguity about what's in/out
3. **Interface-first**: Shared contracts defined before implementation
4. **Test included**: Each task includes its own tests

## Transition

When decomposition is solid:
- "Ready to create GitHub issues? Run `/issues [epic-name]`"
- "Ready to setup parallel worktrees? Run `/worktree-setup [epic-name]`"

---

$ARGUMENTS
