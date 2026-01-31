# Bootstrap

Initialize Claude Code context for this project. Analyzes the codebase and creates the context structure with relevant content.

## Your tasks

### 1. Analyze the project

Determine project state:
- **New project**: Few or no files, possibly just discussed via `/explore`
- **Existing project**: Has code, config files, README, git history

Gather information from:
- README.md, CONTRIBUTING.md
- Config files: pyproject.toml, package.json, Makefile, docker-compose.yml
- Recent git commits (if available): `git log --oneline -20`
- Code structure: main directories and their purpose
- Previous conversation context (if `/explore` was run)
- **Existing `.claude/context/` files**: Check for pre-existing context (creative-direction.md, etc.)

### 2. Scan existing context

Before creating anything, check if `.claude/context/` already exists:

```bash
ls -la .claude/context/ 2>/dev/null
```

**If context files exist:**
- Read and understand each file
- Note their purpose for the summary
- **Never overwrite** existing context files
- Only create missing standard files (status.md, anti-patterns.md, decisions.md)

**Common context files to look for:**
| File | Purpose |
|------|---------|
| `creative-direction.md` | Brand, naming, tone of voice |
| `architecture.md` | System design decisions |
| `personas.md` | User profiles |
| `glossary.md` | Domain terminology |
| `constraints.md` | Technical or business constraints |

These files inform the project. Reference them in CLAUDE.md.

### 3. Create directory structure

```bash
mkdir -p .claude/context
```

### 4. Create and populate context files

#### .claude/context/status.md

```markdown
# Status

## Objective
[Infer from README, explore session, or ask if unclear]

## Current focus
[Infer from recent commits, open work, or conversation]

## Log

### [TODAY'S DATE]
- Bootstrap: Project context initialized
- State: [Brief description of current project state]
- Next: [Logical next steps based on analysis]
```

#### .claude/context/anti-patterns.md

```markdown
# Anti-patterns

Errors encountered and how to avoid them. Added via `/retro`.

<!-- Format:
### [Short title]
**Problem**: What went wrong
**Cause**: Why it happened
**Solution**: How to fix/avoid
**Date**: YYYY-MM-DD
-->
```

Keep empty for new projects. For existing projects, note any obvious issues spotted during analysis.

#### .claude/context/decisions.md

```markdown
# Decisions

Technical decisions and their context. Added via `/retro`.

[For existing projects: Add 3-5 key decisions inferred from codebase]
[For new projects: Add decisions from /explore session if any]
```

Format for inferred decisions:
```markdown
### [Decision title]
**Decision**: [What was chosen]
**Context**: [Inferred from codebase]
**Alternatives considered**: Unknown (inferred from existing code)
**Date**: Inferred
```

### 5. Create or update CLAUDE.md

#### If CLAUDE.md doesn't exist — CREATE

```markdown
# [Project Name]

## Commands
[Detect from Makefile, package.json, pyproject.toml, or ask]

## Stack
[Detect from config files and code]

## Conventions
[Infer from existing code style, or set defaults]

## Context
When relevant, read:
- Current work: `.claude/context/status.md`
- Past mistakes: `.claude/context/anti-patterns.md`
- Technical decisions: `.claude/context/decisions.md`
[ADD ANY OTHER CONTEXT FILES FOUND, e.g.:]
- Creative direction: `.claude/context/creative-direction.md`
- Architecture: `.claude/context/architecture.md`

## End of session
Run `/retro` before stopping to update context files.
```

Keep it under 40 lines. Be specific, not generic.
**List all context files found** — they exist for a reason.

#### If CLAUDE.md exists — APPEND

Only add the Context section if not present:

```markdown

## Context
When relevant, read:
- Current work: `.claude/context/status.md`
- Past mistakes: `.claude/context/anti-patterns.md`
- Technical decisions: `.claude/context/decisions.md`

## End of session
Run `/retro` before stopping to update context files.
```

### 6. Summary output

After creating files, output:

```
## Project bootstrapped

### Structure created
.claude/
└── context/
    ├── status.md
    ├── anti-patterns.md
    ├── decisions.md
    └── [other existing files preserved]

### Existing context found
[List pre-existing context files and their purpose, or "None"]

### Project analysis
- Type: [new/existing]
- Stack: [detected stack]
- State: [current state summary]

### Files populated
- CLAUDE.md: [created/updated]
- status.md: [objective and current focus]
- decisions.md: [X decisions inferred / empty]

### Next steps
[Contextual recommendations based on project state]

Ready to work. Run `/retro` at end of session.
```

## Important rules

- **Scan before creating**: Check `.claude/context/` for existing files first
- **Never overwrite context files**: Existing context files are preserved, only create missing standard files
- **Analyze before creating**: Read existing files to avoid overwriting useful content
- **Be specific**: Generic content is useless. Infer real details from the project.
- **Ask if unclear**: If you can't determine the objective or stack, ask rather than guess
- **Respect existing CLAUDE.md**: Only append, never overwrite existing content
- **Reference all context**: Any file in `.claude/context/` should be listed in CLAUDE.md
- **Use today's date**: For all log entries

---

$ARGUMENTS
