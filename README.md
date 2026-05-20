# Claude Setup

Personal configuration for Claude Code: commands, agents and skills. Designed to **complement** the public ecosystem (superpowers, astronomer-data, vercel-*, etc.) rather than duplicate it.

## Installation

```bash
# Clone the repo
git clone https://github.com/jbo-tech/claude-setup.git

# Copy contents to ~/.claude/
cp -r claude-setup/claude/* ~/.claude/

# Install ruff (required for the Python formatting hook)
# See "Installing ruff" section below
```

### Installing ruff

**With pipx (recommended)**

```bash
brew install pipx
pipx ensurepath
source ~/.zshrc
pipx install ruff
which ruff   # → ~/.local/bin/ruff
```

**With uv (modern alternative)**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
uv tool install ruff
which ruff   # → ~/.local/bin/ruff
```

**With pip**

```bash
pip install ruff
```

## Structure

```
claude/
├── CLAUDE.md              # Global preferences
├── settings.json          # Permissions and hooks
├── commands/              # Slash commands
├── agents/                # Specialized agents
├── skills/                # Skills with templates
└── scripts/               # Utility scripts
```

## Commands

| Command | Description |
|---------|-------------|
| `/bootstrap` | Initialize project context |
| `/scope` | Entry point (what / why / how) — hands off to `/goal` |
| `/explore [tag]` | Exploration (tags: `technical`, `architecture`, `business`, `user`) |
| `/audit` | General code audit (security, optimization, homogeneity) |
| `/audit-ml` | Specialized ML / DL audit (leakage, validation, serving) |
| `/audit-accessibility` | Specialized accessibility audit (WCAG / ARIA / RGAA) |
| `/git-commit` | Git commit |
| `/retro` | Session retrospective |

## Workflow

```
┌─────────────┐
│ /bootstrap  │  (project context)
└─────────────┘
       ↓
┌─────────────┐
│  /explore   │  (understanding)
└─────────────┘
       ↓
┌─────────────┐
│   /scope    │  (what / why / how)
└─────────────┘
       ↓
   Clear? ──→ Unclear → /explore [tag] → back to /scope
       ↓
   ┌───────┴───────┐
   ↓               ↓
  Code         /goal (autonomous execution)
   ↓               ↓
/git-commit   /git-commit
   ↓               ↓
       /retro
```

Specialized audits (`/audit`, `/audit-ml`, `/audit-accessibility`) are called on demand throughout the flow.

## Agents

| Agent | Triggers |
|-------|----------|
| `infra-expert` | container, dockerfile, compose, deploy, kubernetes, systemd |
| `creative-director` | brainstorm, naming, concept, creative, branding, vision |

## Skills

| Skill | Description |
|-------|-------------|
| `agent-builder` | Create specialized agents |
| `creative-direction` | Naming, branding, creative direction workflow |
| `data-engineering` | Open-source data pipelines (DuckDB, Parquet, Kestra, MinIO) |
| `infra-containers` | Open-source containerization (Docker, Podman, K3s, Kestra) |
| `security-review` | Security best practices for code and infrastructure |

## Composition with the public ecosystem

This setup is **intentionally minimal**. Many workflows are already covered by public skills and plugins — duplicating them locally only adds noise.

| Need | This setup | Public coverage |
|------|------------|-----------------|
| TDD red/green/refactor | — | `superpowers:test-driven-development` |
| Plan a multi-step feature | — | `superpowers:writing-plans` |
| Execute a plan | `/goal` (native) | `superpowers:executing-plans` / `subagent-driven-development` |
| Worktrees / isolated workspace | — | `superpowers:using-git-worktrees` |
| Finish a branch (merge / PR) | — | `superpowers:finishing-a-development-branch` |
| Brainstorm / ideation | `creative-direction` skill | `superpowers:brainstorming` |
| Airflow / dbt / Snowflake | — | `astronomer-data:*` |
| Vercel / Next.js | — | `vercel-*` |
| Frontend design / UI generation | — | `frontend-design`, `taste-design`, `stitch-*` |

What this setup **adds** : the `/scope → /goal` handoff with a structured success-criteria block, the `/audit-*` family, open-source-focused `data-engineering` and `infra-containers` skills, and the `creative-director` agent. Everything else is delegated.

## Configuration

### settings.json

- **Model**: opus
- **Permissions**: git, python, pytest, ruff, make, docker, uv, pip, npm, gh
- **Ruff hook**: automatic formatting of Python files after write

## License

MIT
