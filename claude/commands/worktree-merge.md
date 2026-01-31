# Worktree Merge

Merge parallel worktrees back to main. Executes directly — no script needed.

## Prerequisites

- All parallel tasks completed and committed
- Run this from the **main project directory** (not a worktree)

## Your tasks

### 1. Identify worktrees

```bash
git worktree list
```

Parse output to find worktrees for this epic.

If epic name not provided in $ARGUMENTS, ask:
> "Which epic to merge? (e.g., myapp)"

### 2. Verify all worktrees are clean

```bash
# For each worktree, check status
git -C ../[epic]-[task] status --porcelain
```

If any worktree has uncommitted changes:
> "Worktree [name] has uncommitted changes. Please commit first, then retry."

Stop and wait for user to fix.

### 3. Confirm before merging

List what will be merged:

```
## Ready to merge

| Branch | Commits | Status |
|--------|---------|--------|
| feature/myapp-api | 3 commits | clean |
| feature/myapp-ui | 5 commits | clean |
| feature/myapp-data | 2 commits | clean |

Proceed with merge? (yes/no)
```

Wait for confirmation.

### 4. Execute merge sequence

```bash
# Ensure we're on the base branch
git checkout main  # or master, or the original branch

# Pull latest (if remote exists)
git pull --ff-only 2>/dev/null || true

# Merge each feature branch
git merge feature/[epic]-api --no-edit
git merge feature/[epic]-ui --no-edit
git merge feature/[epic]-data --no-edit
```

### 5. Handle conflicts

If merge conflict occurs:

1. **Stop and report**:
   > "Merge conflict in feature/[epic]-[task]. Conflicting files: [list]"

2. **Show conflict details**:
   ```bash
   git status
   git diff --name-only --diff-filter=U
   ```

3. **Guide resolution**:
   > "Options:
   > 1. I can help resolve these conflicts
   > 2. Abort merge with `git merge --abort` and fix manually
   > 
   > What would you prefer?"

4. After resolution:
   ```bash
   git add [resolved files]
   git merge --continue
   ```

### 6. Run tests

```bash
# Detect test command and run
if [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
    pytest 2>/dev/null || python -m pytest 2>/dev/null || echo "No pytest found"
elif [ -f "package.json" ]; then
    npm test 2>/dev/null || echo "No npm test configured"
else
    echo "No test command detected"
fi
```

Report test results.

### 7. Cleanup (with confirmation)

```
## Merge complete

All branches merged successfully. Tests: [passed/failed/skipped]

Clean up worktrees and branches? (yes/no)
```

If yes:
```bash
# Remove worktrees
git worktree remove ../[epic]-api --force
git worktree remove ../[epic]-ui --force
git worktree remove ../[epic]-data --force

# Delete feature branches
git branch -d feature/[epic]-api
git branch -d feature/[epic]-ui
git branch -d feature/[epic]-data
```

### 8. Final summary

```
## Merge complete ✓

Merged: feature/myapp-api, feature/myapp-ui, feature/myapp-data
Total commits: 10
Files changed: 25
Tests: passing

Worktrees removed: 3
Branches deleted: 3

Next steps:
  git push                    # Push to remote
  /retro                      # Capture learnings
```

## Error handling

- **Not in main project**: Detect via `git worktree list` and guide user
- **Uncommitted changes in worktree**: Stop, report, wait for fix
- **Merge conflicts**: Guide through resolution or abort
- **Test failures**: Report but don't block (user decides)
- **Branch delete fails**: Use `-D` if unmerged commits (with warning)

---

$ARGUMENTS
