# Claude Setup

Personal configuration for Claude Code: commands, agents and skills.

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
# Install pipx if not already done
brew install pipx
pipx ensurepath

# Restart terminal or
source ~/.zshrc

# Install ruff globally
pipx install ruff

# Verify
which ruff
# → ~/.local/bin/ruff
```

**With uv (modern alternative)**

```bash
# Install uv if not already done
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install ruff as a global tool
uv tool install ruff

# Verify
which ruff
# → ~/.local/bin/ruff
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
| `/scope` | Entry point (what/why/how) |
| `/explore [tag]` | Exploration (tags: `technical`, `architecture`, `business`, `user`) |
| `/audit` | Code audit |
| `/decompose` | Decompose into parallelizable tasks |
| `/commit` | Git commit |
| `/pr` | Create PR |
| `/retro` | Session retrospective |
| `/worktree-setup` | Setup for git worktree parallelism |
| `/worktree-merge` | Merge worktrees |

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                       /bootstrap                            │
│                   (project context)                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                        /explore                             │
│                    (understanding)                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                         /scope                              │
│                    (what/why/how)                            │
└─────────────────────────────────────────────────────────────┘
                            ↓
              ┌─────────────┴─────────────┐
              ↓                           ↓
          Clear?                      Unclear?
              ↓                           ↓
    ┌─────────┴─────────┐             /explore
    ↓                   ↓                 ↓
  Small               Large          [clarify]
    ↓                   ↓                 ↓
  Code              /decompose      Back to /scope
    ↓                   ↓
 /commit            worktrees
    ↓                   ↓
 /retro               merge
                        ↓
                     /retro
```

## Agents

| Agent | Triggers |
|-------|----------|
| `data-ml-expert` | data leakage, preprocessing, cross-validation, pipeline, feature, training |
| `infra-expert` | container, dockerfile, compose, deploy, kubernetes, systemd |
| `creative-director` | brainstorm, naming, concept, creative, branding, vision |

## Skills

| Skill | Description |
|-------|-------------|
| `agent-builder` | Create specialized agents |
| `skill-factory` | Create skills |

## Configuration

### settings.json

- **Model**: opus
- **Permissions**: git, python, pytest, ruff, make, docker, uv, pip, npm, gh
- **Ruff hook**: automatic formatting of Python files after write

## License

MIT
