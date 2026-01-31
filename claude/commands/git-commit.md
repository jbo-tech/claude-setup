# Commit

Analyze changes and create well-structured commits with conventional commit messages.

## Your tasks

### 1. Analyze the diff

Run:
```bash
git status
git diff --staged
git diff
```

Understand what changed:
- Which files were modified, added, deleted?
- What's the nature of changes? (feature, fix, refactor, docs, chore, test)
- Are there multiple logical changes that should be separate commits?

### 2. Stage appropriately

If nothing is staged, decide what to stage:
- **Single logical change** → `git add -A`
- **Multiple logical changes** → Stage files per commit group

### 3. Generate commit message(s)

Use conventional commits format:
```
<type>(<scope>): <short description>

[optional body: what and why, not how]

[optional footer: breaking changes, references]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `docs`: Documentation only
- `style`: Formatting, no code change
- `test`: Adding or updating tests
- `chore`: Maintenance, dependencies, config

Rules:
- Subject line: max 50 chars, imperative mood, no period
- Scope: optional, indicates area (api, ui, auth, etc.)
- Body: wrap at 72 chars

### 4. Execute or propose

**If single commit:**
```bash
git add -A  # or specific files
git commit -m "type(scope): description"
```

**If multiple commits recommended:**
Propose the split:
```
I suggest splitting into 2 commits:
1. refactor(api): extract validation logic
   Files: src/api/validation.py, src/api/routes.py
   
2. feat(api): add rate limiting
   Files: src/api/middleware.py, src/api/config.py

Proceed with this split? (yes / single commit / edit)
```

## Output format

```
## Commit summary

### Changes detected
- [file]: [what changed]
- [file]: [what changed]

### Commit(s) created
`type(scope): message`
[hash] [files count] changed

### Uncommitted changes remaining
[list if any, or "None - working tree clean"]
```

## Important rules

- **Never commit secrets, credentials, or .env files** — warn and exclude
- **Check for debug code** — warn about console.log, print statements, debugger
- **Respect .gitignore** — don't suggest staging ignored files
- **Ask if unsure** — ambiguous changes deserve clarification before commit

---

$ARGUMENTS
