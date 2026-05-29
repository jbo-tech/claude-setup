# Claude Setup

Personal configuration for Claude Code: commands, agents and skills. Designed to **complement** the public ecosystem (superpowers, astronomer-data, vercel-*, etc.) rather than duplicate it.

## Installation

```bash
# Clone the repo
git clone https://github.com/jbo-tech/claude-setup.git
cd claude-setup

# Preview what would be installed (no changes)
./install.sh --dry-run

# Install — creates symlinks from ~/.claude/ to this repo
./install.sh

# Auto-backup all conflicts without prompting
./install.sh -y
```

The installer uses **symlinks**, not copies. Editing files in the repo applies immediately to your `~/.claude/` setup — and `git pull` updates everything in place.

On conflict (existing file at a target path), the installer asks per file :
- `[v]iew diff` — show what differs
- `[b]ackup` — save the existing file, then symlink
- `backup-[a]ll` — backup this and all remaining conflicts without prompting
- `[s]kip` — leave the existing file alone
- `[q]uit` — stop the run, keep everything done so far

Backups are stored in `.backups/<timestamp>/` at the repo root (gitignored). A manifest is written at `~/.claude/.claude-setup-manifest` listing every symlink created. The installer never touches `~/.claude/plugins/` (third-party plugins) and never removes files not in the manifest.

### Uninstall

```bash
./uninstall.sh --dry-run    # preview
./uninstall.sh              # remove our symlinks
```

Safety: only symlinks that still point to this repo are removed. Anything you modified (replaced with a regular file, re-pointed elsewhere) is preserved with a warning. Backups under `.backups/` are never removed automatically.

### Custom install location

Set `CLAUDE_HOME` if your config lives elsewhere :

```bash
CLAUDE_HOME=/path/to/.claude ./install.sh
```

### Ruff (Python formatting hook)

The `settings.json` ships a hook that runs `ruff format` after Python file edits. The installer warns if `ruff` is not in `PATH`, but does not install it for you.

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
├── settings.json          # Permissions, hooks and status line
├── commands/              # Slash commands
├── agents/                # Specialized agents
├── skills/                # Skills with templates
└── scripts/               # Status line and utility scripts
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
| `/delegate [--task <type>]` | Delegate coding task to cheaper agent CLI |
| `/delegate-on` | Enable auto-delegation for project |
| `/delegate-off` | Disable auto-delegation |
| `/delegate-status` | Show delegation backend status |
| `/git-commit` | Git commit |
| `/retro` | Session retrospective |

### Delegate — task routing

`/delegate` routes to a specialized backend based on task type. Claude injects `--task` automatically — no manual flag needed.

| `--task` | Model | Best for |
|----------|-------|----------|
| `coding` | kimi-k2.6 (openrouter) | Simple edits in any language |
| `python` | qwen3.7-max (openrouter) | Python files, data scripts, ML code |
| `marketing` | deepseek-v4-pro | README, docs, copywriting |
| _(omit)_ | mistral-medium-3.5 (vibe) | Complex / multi-file / unclear |

Backend config lives in `~/.config/claude-code/delegate.yaml`. Add or swap models without touching the skill.

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
   └───┬───────────┘
       ↓
  delegate-auto? ──→ oui → /delegate (cheaper model)
       ↓
      non → code direct
       ↓
   /git-commit
       ↓
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
| Delegate to cheaper models | `/delegate` + `/delegate-on` | `vibe-skill` (Mistral Vibe) |

What this setup **adds** : the `/scope → /goal` handoff with structured success criteria, auto-delegation to task-specialized cheaper models via `/delegate` (5 backends, automatic `--task` routing), the `/audit-*` family, open-source-focused `data-engineering` and `infra-containers` skills, and the `creative-director` agent. Everything else is delegated.

### Recommended companions

Install these plugins and skills from within Claude Code to unlock the workflows listed above.

**Plugins** (via `/install-plugin`):

| Plugin | Source | Provides |
|--------|--------|----------|
| `superpowers` | `anthropics/claude-plugins-official` | TDD, plans, worktrees, branch finishing, brainstorming |
| `frontend-design` | `anthropics/claude-plugins-official` | UI/UX generation and design review |
| `remember` | `anthropics/claude-plugins-official` | Persistent memory across conversations |

**Third-party skills** (clone + symlink into `~/.claude/skills/`):

| Skill | Repo | Provides |
|-------|------|----------|
| `vibe-skill` | [`pcx-wave/vibe-skill`](https://github.com/pcx-wave/vibe-skill) | Delegate coding tasks to Mistral Vibe — saves tokens and context window |

All plugins from `anthropics/claude-plugins-official` can be browsed and installed interactively with `/install-plugin` inside Claude Code. Third-party skills require manual installation — see each repo's README for instructions.

## Status line

`statusline.py` displays context window usage, 5-hour and 7-day rate limit quotas with color-coded alerts (green/yellow/red) and remaining time. Requires Python 3.

```
Opus | project:main ● | ctx ▓░░░░░░░░░ 7% | 5h ░░░░░ 3% ~4h46 | 7d ▓▓░░░ 49% ~3d
```

The previous `context-bar.sh` (bash/jq) is still available — switch in `settings.json` :

```json
"statusLine": { "command": "~/.claude/scripts/context-bar.sh" }
```

## Configuration

### settings.json

- **Model**: opus
- **Permissions**: git, python, pytest, ruff, make, docker, uv, pip, npm, gh
- **Ruff hook**: automatic formatting of Python files after write
- **Status line**: `statusline.py` with 60s refresh interval

## License

MIT
