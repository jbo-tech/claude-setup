# PR

Create a pull request with a well-structured description based on branch commits.

## Prerequisites

- GitHub CLI (`gh`) must be installed and authenticated
- Branch must be pushed to remote

## Your tasks

### 1. Gather context

```bash
# Current branch
git branch --show-current

# Commits in this branch vs main
git log main..HEAD --oneline

# Detailed changes
git log main..HEAD --pretty=format:"%s%n%b"

# Files changed
git diff main --stat
```

### 2. Check if ready

Verify:
- [ ] Branch is pushed (`git push` if needed)
- [ ] No uncommitted changes (warn if any)
- [ ] Not on main/master branch

### 3. Generate PR content

**Title**: Based on the overall change
- If single feat: `feat(scope): description`
- If single fix: `fix(scope): description`
- If multiple: Descriptive summary of the change

**Description template**:
```markdown
## Summary
[2-3 sentences: what this PR does and why]

## Changes
- [Key change 1]
- [Key change 2]
- [Key change 3]

## Type of change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Refactoring (no functional changes)
- [ ] Documentation update

## Testing
[How was this tested? What should reviewers check?]

## Notes for reviewers
[Optional: anything specific to look at, concerns, alternatives considered]
```

### 4. Create the PR

```bash
gh pr create --title "..." --body "..."
```

Or if you want to target a specific base branch:
```bash
gh pr create --base main --title "..." --body "..."
```

## Output format

```
## Pull Request created

**Title**: [title]
**Branch**: [branch] → main
**URL**: [PR url]

### Summary
[what the PR does]

### Commits included
- [commit 1]
- [commit 2]

### Review checklist
- [ ] [specific thing to review]
- [ ] [specific thing to review]
```

## Options via $ARGUMENTS

- `/pr` — Create PR to main with auto-generated content
- `/pr draft` — Create as draft PR
- `/pr base:develop` — Target different base branch
- `/pr "Custom title"` — Override the title

## Important rules

- **Never create PR from main** — warn and abort
- **Check for WIP commits** — suggest squashing or warn reviewers
- **Detect sensitive files** — warn if .env, credentials, or secrets in diff
- **Link issues** — if commit messages reference issues (#123), include in PR

---

$ARGUMENTS
