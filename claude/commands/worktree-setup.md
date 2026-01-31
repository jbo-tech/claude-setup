# Worktree Setup

Create Git worktrees for parallel task execution. Executes directly — no script needed.

## Prerequisites

- Task decomposition done (`/decompose`) or clear task list
- Git repository initialized
- Clean working directory (commit or stash changes first)

## Your tasks

### 1. Verify prerequisites

```bash
# Check we're in a git repo
git rev-parse --is-inside-work-tree

# Check for uncommitted changes
git status --porcelain
```

If dirty, ask user to commit or stash first.

### 2. Get task information

From `/decompose` output or conversation, identify:
- Epic name (for branch naming)
- Parallel tasks (typically 2-4)
- Task names (short, for branch suffixes: api, ui, data, etc.)

If not clear, ask:
> "What tasks should run in parallel? (e.g., api, ui, data)"

### 3. Create worktrees

For each parallel task, execute:

```bash
# Get current branch as base
BASE_BRANCH=$(git branch --show-current)

# Create branch and worktree for each task
git branch feature/[epic]-[task] $BASE_BRANCH
git worktree add ../[epic]-[task] feature/[epic]-[task]
```

Example for epic "myapp" with tasks api, ui, data:
```bash
BASE_BRANCH=$(git branch --show-current)

git branch feature/myapp-api $BASE_BRANCH
git worktree add ../myapp-api feature/myapp-api

git branch feature/myapp-ui $BASE_BRANCH
git worktree add ../myapp-ui feature/myapp-ui

git branch feature/myapp-data $BASE_BRANCH
git worktree add ../myapp-data feature/myapp-data
```

### 4. Copy context to worktrees

```bash
# Copy .claude context if it exists
for task in api ui data; do
    if [ -d "../[epic]-${task}" ] && [ -d ".claude" ]; then
        cp -r .claude "../[epic]-${task}/"
    fi
done
```

### 5. Create TASK.md in each worktree

For each worktree, create a `TASK.md` at root:

```markdown
# Task: [Task Name]

## Context
You are working on one part of a larger epic. Other agents work in parallel on other parts.

## Your assignment
[From decomposition]

## Interfaces to respect
[Shared contracts]

## Files you own
- `src/[paths]`

## Files you must NOT touch
- [Files owned by other tasks]

## When done
1. Ensure tests pass
2. Commit with: `feat([epic]-[task]): [description]`
3. Say: "Task [name] complete"
```

### 6. Output summary

```
## Worktrees created

| Worktree | Branch | Task |
|----------|--------|------|
| ../myapp-api | feature/myapp-api | API endpoints |
| ../myapp-ui | feature/myapp-ui | UI components |
| ../myapp-data | feature/myapp-data | Data layer |

## Next steps

Open separate terminals and start working:

Terminal 1:
  cd ../myapp-api && claude

Terminal 2:
  cd ../myapp-ui && claude

Terminal 3:
  cd ../myapp-data && claude

When all tasks complete, return here and run:
  /worktree-merge myapp
```

## Error handling

- **Dirty working directory**: Ask to commit/stash first
- **Branch already exists**: Ask to use existing or create new name
- **Worktree path exists**: Ask to remove or use different path

---

$ARGUMENTS
