# Claude Setup

Configuration personnelle pour Claude Code : commandes, agents et skills.

## Installation

```bash
# Cloner le repo
git clone https://github.com/jbo-tech/claude-setup.git

# Copier le contenu vers ~/.claude/
cp -r claude-setup/claude/* ~/.claude/

# Installer ruff (requis pour le hook de formatage Python)
# Voir section "Installation de ruff" ci-dessous
```

### Installation de ruff

**Avec pipx (recommandé)**

```bash
# Installer pipx si pas déjà fait
brew install pipx
pipx ensurepath

# Redémarrer le terminal ou
source ~/.zshrc

# Installer ruff globalement
pipx install ruff

# Vérifier
which ruff
# → ~/.local/bin/ruff
```

**Avec uv (alternative moderne)**

```bash
# Installer uv si pas déjà fait
curl -LsSf https://astral.sh/uv/install.sh | sh

# Installer ruff comme outil global
uv tool install ruff

# Vérifier
which ruff
# → ~/.local/bin/ruff
```

**Avec pip**

```bash
pip install ruff
```

## Structure

```
claude/
├── CLAUDE.md              # Préférences globales
├── settings.json          # Permissions et hooks
├── commands/              # Slash commands
├── agents/                # Agents spécialisés
├── skills/                # Skills avec templates
└── scripts/               # Scripts utilitaires
```

## Commandes

| Commande | Description |
|----------|-------------|
| `/bootstrap` | Initialise le contexte projet |
| `/scope` | Point d'entrée (what/why/how) |
| `/explore [tag]` | Exploration (tags: `technical`, `architecture`, `business`, `user`) |
| `/audit` | Audit de code |
| `/decompose` | Décomposition en tâches parallélisables |
| `/commit` | Commit git |
| `/pr` | Création de PR |
| `/retro` | Rétrospective de session |
| `/worktree-setup` | Setup pour parallélisme git worktree |
| `/worktree-merge` | Merge des worktrees |

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                       /bootstrap                            │
│                   (contexte projet)                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                        /explore                             │
│                    (compréhension)                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                         /scope                              │
│                    (what/why/how)                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
              ┌─────────────┴─────────────┐
              ↓                           ↓
          Clair ?                      Flou ?
              ↓                           ↓
    ┌─────────┴─────────┐             /explore
    ↓                   ↓                 ↓
  Petit               Gros          [clarifier]
    ↓                   ↓                 ↓
  Code              /decompose      Retour /scope
    ↓                   ↓
 /commit            worktrees
    ↓                   ↓
 /retro               merge
                        ↓
                     /retro
```

## Agents

| Agent | Déclencheurs |
|-------|--------------|
| `data-ml-expert` | data leakage, preprocessing, cross-validation, pipeline, feature, training |
| `infra-expert` | container, dockerfile, compose, deploy, kubernetes, systemd |
| `creative-director` | brainstorm, naming, concept, creative, branding, vision |

## Skills

| Skill | Description |
|-------|-------------|
| `agent-builder` | Création d'agents spécialisés |
| `skill-factory` | Création de skills |

## Configuration

### settings.json

- **Modèle** : opus
- **Permissions** : git, python, pytest, ruff, make, docker, uv, pip, npm, gh
- **Hook ruff** : formatage automatique des fichiers Python après écriture

## License

MIT
