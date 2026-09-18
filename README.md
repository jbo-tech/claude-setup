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

Eleven commands, deliberately. Anything Claude Code now does natively was removed rather than
wrapped — see [What was removed, and where it went](#what-was-removed-and-where-it-went).

| Command | Description |
|---------|-------------|
| `/scope` | Entry point — what, why, and the success criteria |
| `/explore [tag]` | Exploration (tags: `technical`, `architecture`, `business`, `user`) |
| `/decompose` | Break a scope into vertical slices — thin foundation first, then parallel slices |
| `/bootstrap` | Initialize project context (`.claude/context/` + CLAUDE.md) |
| `/document` | Generate orientation docs (architecture + reference, plus a test protocol when warranted) |
| `/delegate [--task <type>]` | Delegate a coding task to a cheaper agent CLI |
| `/delegate-on` / `-off` / `-status` | Auto-delegation for this project, and the usage dashboard |
| `/git-commit [pr]` | Conventional commits — and open the pull request when the branch is done |
| `/retro` | End-of-session retrospective and learning loop |

### Delegate — task routing

`/delegate` routes to a specialized backend based on task type. Claude injects `--task` automatically — no manual flag needed. Models use the **opencode-go** provider, ventilated by difficulty tier.

| `--task` | Model (tier) | Best for |
|----------|-------|----------|
| `coding` | kimi-k2.7-code (easy) | Simple, bounded edits in any language |
| `python` | minimax-m3 (complex) | Python files, data scripts, ML code |
| `architecture` | glm-5.2 (complex) | Architecture and brainstorming work |
| `marketing` | deepseek-v4-pro (medium) | README, docs, copywriting |
| _(omit)_ | qwen3.7-max (opencode) / mistral-medium-3.5 (vibe) | Complex / multi-file / unclear |

Backend config lives in `~/.config/claude-code/delegate.yaml`. Add or swap models without touching the skill.

## Workflow

### The spine

Three commands carry every session. The rest are occasional.

```
/scope  ─────────▶  work  ─────────▶  /retro
  what & why      (delegate when         what the session
                   it pays)              taught the setup
```

A one-line fix needs none of them. A day of work needs all three. **`/retro` closes anything that
ran more than an hour** — it is the only step that makes the setup improve instead of just persist.

### By kind of session

| Session | Entry | Loop | Exit |
|---|---|---|---|
| **Quick fix** | none | code; `/code-review` if it touches anything sensitive | `/git-commit` |
| **A feature** | `/scope` | code, or `/delegate` when the task is bounded | `/git-commit` → `/retro` |
| **A new project** | `/scope` → `/decompose` | foundation in the main session, then slices in parallel | `/git-commit` → `/retro` |
| **Taking over an existing codebase** | `/document` to understand, then `/bootstrap` | whatever it turns up | `/retro` |
| **Exploration / R&D** | plan mode, or `/explore` | conversation, domain agents | `/retro` |
| **Data / ML** | `/scope` | the `data-engineering` and `ml-review` skills route themselves | `/retro` |
| **This framework** | — | `docs/test-protocol.md` §A | `/document` → `/retro` |

### The full run — orchestrator-driven

For a project big enough to decompose. Start the session in the pilot seat:

```bash
claude --agent orchestrator     # no Write/Edit — it cannot implement, by construction
```

```
 1. /scope                  what, why, success criteria as a checklist
 2. /explore                only if questions remain
 3. /decompose              thin shared foundation, then vertical slices
 4. foundation              in the main session — never a builder: a worktree
                            cannot be created in a directory that is not yet a repo
 5. per slice               builder (its own worktree, created and cleaned for you)
                            or /delegate (cheaper CLI, no worktree)
 6. read the diff           always, and never delegated
 7. /code-review            the diff; the security-review skill fires on its own when
                            the change touches input, auth or secrets
 8. /git-commit [pr]
 9. /document               only if the architecture actually moved
10. /retro                  defects → ledger → rules, at the right level
```

Steps 1-3 are the plan, 4-6 the build, 7-8 the validation, 10 the improvement of the setup itself.
The loop only pays from the second slice onward — that is what makes it a loop and not a checklist.

### What was removed, and where it went

Six commands were deleted once Claude Code covered them natively. Nothing was lost silently — this
is where each went:

| Removed | Use instead |
|---|---|
| `/audit` | `/code-review` (native) for bugs and cleanup; the **`security-review` skill** for the security axis, which `/code-review` does not cover |
| `/audit-ml` | the **`ml-review` skill** — same four checks (leakage, validation, reproducibility, serving), and it routes on the words of the subject instead of waiting to be named |
| `/audit-accessibility` | the `web-design-guidelines` and `impeccable` skills |
| `/worktree-setup`, `/worktree-merge` | `builder` runs under `isolation: worktree` — created, merged and cleaned automatically. `EnterWorktree` is native for a single session |
| `/history` | `claude --resume` |
| `/git-pr` | folded into `/git-commit pr` |

**How to run a domain audit now.** Three routes, in increasing weight:

- **A skill** — say what the subject is, and it loads itself: security, ML, data pipelines, infra,
  accessibility. Nothing to remember.
- **A reviewer agent** — `@data-ml-expert`, `@data-rag-expert`, `@infra-expert`. Read-only, returns
  a verdict. This is the deliberate audit pass.
- **`/code-review high`** (native) on the diff, for correctness and cleanup at depth.

A skill beats a command here for one reason: **a command has to be remembered, a skill fires on the
words you were already typing.**

## Agents

Agents are grouped by domain: `data-*` and `infra-*` review, `creative-director` is a role,
and `orchestrator`/`builder` run the work itself.

| Agent | Family | Triggers |
|-------|--------|----------|
| `data-ml-expert` | domain review | pipeline, model, data leakage, cross-validation, pytorch, tensorflow |
| `data-rag-expert` | domain review | hybrid search, reranking, MMR, golden set, recall@k / MRR / nDCG, Opik, eval in CI |
| `infra-expert` | domain review | container, dockerfile, compose, deploy, kubernetes, systemd |
| `creative-director` | role | brainstorm, naming, concept, creative, branding, vision |
| `orchestrator` | workflow | session pilot — delegates all implementation, never writes code |
| `builder` | workflow | implementation worker — one bounded task, isolated git worktree, reports what it verified |

`orchestrator` is meant for the pilot seat, not for delegation: start a session with
`claude --agent orchestrator`. It has no `Write`/`Edit`, which turns the delegation policy in
`CLAUDE.md` from a written rule into the shape of the agent. Its `Agent(...)` allowlist only
applies when it runs as the main thread — spawned as an ordinary subagent, the list is ignored.

Every agent declares `tools:` — the field a subagent definition actually reads. `allowed-tools:`
is the field for skills and slash commands; used on an agent it is ignored silently, and the agent
keeps every tool while its prompt claims otherwise. Check against the agent listing printed at the
start of a session: a restricted agent must not read `(Tools: All tools)`.

## Skills

| Skill | Description |
|-------|-------------|
| `agent-builder` | Create specialized agents |
| `creative-direction` | Naming, branding, creative direction workflow |
| `data-engineering` | Open-source data pipelines (DuckDB, Parquet, Kestra, MinIO) |
| `infra-containers` | Open-source containerization (Docker, Podman, K3s, Kestra) |
| `safe-penpot-writes` | Read-back discipline for the Penpot plugin API — the writes that fail silently ⚠ |
| `security-review` | Security best practices for code and infrastructure |

⚠ **External dependency.** `safe-penpot-writes` complements the [Penpot AI kit](https://github.com/penpot/penpot-ai-kit)
rather than duplicating it: the kit's `penpot-*` skills know *what* to build, this one knows *how a
write goes wrong*. It expects the kit installed (`~/.claude/skills/penpot-router`) and the Penpot MCP
reachable — `install.sh` warns if the kit is missing. Without it the skill still reads as
documentation, but its scripts cannot run: `penpotUtils` comes from the MCP plugin context.

Its name deliberately does **not** start with `penpot-`: the kit's installer offers a `--prune` flag
that removes any `penpot-*` skill it does not ship, and would take ours with it.

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
| Designing in Penpot | `safe-penpot-writes` (the write path only) | `penpot-ai-kit` (`penpot-*`, 12 skills) |
| Delegate to cheaper models | `/delegate` + `/delegate-on` | `vibe-skill` (Mistral Vibe) |

What this setup **adds** : the `/scope` → `/decompose` handoff with structured success criteria and vertical slicing, auto-delegation to task-specialized cheaper models via `/delegate` (5 backends, automatic `--task` routing), open-source-focused `data-engineering` and `infra-containers` skills, the `creative-director` agent, and `safe-penpot-writes` — the one Penpot concern the official kit
does not cover. Everything else is delegated.

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
