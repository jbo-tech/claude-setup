---
name: provider-keys
description: Set up centralized LLM provider API key management for a project. Scaffolds the loading pattern (Python dotenv or shell source), .env.example, install.sh section, and README section. Triggers on "setup provider keys", "configure API keys", "add provider keys", "/provider-keys".
---

# Provider Keys

Scaffold centralized LLM provider API key management for the current project.

## Convention

All LLM provider API keys live in a single shared file:

```
~/.config/llm-provider-keys/providers.env    (chmod 600)
```

Projects load this file first, then override with a local `.env` for project-specific config (auth tokens, paths, ports — never provider keys).

### Naming

Use the name expected by each provider's official SDK — the key auto-detected when no explicit config is passed:

| Provider   | Variable             |
|------------|----------------------|
| OpenAI     | `OPENAI_API_KEY`     |
| Anthropic  | `ANTHROPIC_API_KEY`  |
| Mistral    | `MISTRAL_API_KEY`    |
| Google     | `GOOGLE_API_KEY`     |

For providers without a standard SDK name, follow the pattern `<PROVIDER>_API_KEY` (uppercase, underscores).

### Loading order

```
~/.config/llm-provider-keys/providers.env    ← provider keys (all)
          ↓ override
.env (project root)                           ← project-specific config only
```

### Key principle

The local `.env` and `.env.example` contain **zero provider API keys**. A contributor who clones the repo only needs to:
1. Run `install.sh` (creates the central store if absent)
2. Fill in `~/.config/llm-provider-keys/providers.env` once
3. Fill in `.env` with project-specific values (tokens, paths)

If they already have the central store from another project, step 2 is already done.

## What to scaffold

Detect the project stack and generate the appropriate pattern:

### Python (dotenv + pydantic-settings)

Add to the config/settings module, **before** any Settings class instantiation:

```python
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path.home() / ".config" / "llm-provider-keys" / "providers.env")
load_dotenv(Path(__file__).resolve().parent.parent / ".env", override=True)
```

Remove `env_file=".env"` from `SettingsConfigDict` if present (dotenv handles it now).

### Shell (POSIX sh / bash / zsh)

Source the central store before any provider-specific logic:

```sh
KEYS_FILE="${HOME}/.config/llm-provider-keys/providers.env"
[ -f "$KEYS_FILE" ] && . "$KEYS_FILE"

# Then source local .env for project overrides
[ -f .env ] && . .env
```

### install.sh section

Add or create an `install.sh` with this block:

```sh
KEYS_DIR="${HOME}/.config/llm-provider-keys"
mkdir -p "$KEYS_DIR"
chmod 700 "$KEYS_DIR"
if [ ! -f "$KEYS_DIR/providers.env" ]; then
    cp "$REPO_DIR/providers.env.example" "$KEYS_DIR/providers.env"
    chmod 600 "$KEYS_DIR/providers.env"
    echo "Created $KEYS_DIR/providers.env — fill in your API keys."
else
    echo "Central keys store already exists: $KEYS_DIR/providers.env"
fi
```

### providers.env.example

Create in the project root. List only the providers the project actually uses:

```
# Central LLM provider API keys — template
# Installed to: ~/.config/llm-provider-keys/providers.env (by install.sh)
# Permissions: 600
OPENAI_API_KEY=sk-...
MISTRAL_API_KEY=
# etc.
```

### .env.example

Strip all provider API keys. Keep only project-specific values:

```
# Project-specific config only.
# Provider API keys: ~/.config/llm-provider-keys/providers.env
AUTH_TOKEN=change-me
```

### README section

Add under Setup or Configuration:

```markdown
### API keys

API keys are loaded from a central store shared across projects:

    ~/.config/llm-provider-keys/providers.env

Run `install.sh` to create it from the template, or fill in an existing one.
The project `.env` contains only project-specific config (tokens, paths) — no API keys.
```

## Process

1. Detect stack (Python with dotenv/pydantic-settings, or shell)
2. Find the config/settings module where env vars are loaded
3. Add the dual-load pattern
4. Update `.env.example` (strip provider keys)
5. Create `providers.env.example` (provider keys template)
6. Add install.sh block (create or update)
7. Update README (setup section)
8. Verify: project works with central store + empty local .env

## Projects already using this pattern

- `llm-sparring` — Python, `server.py` loads via dotenv
- `jobset&match-v2` — Python, `app/config.py` loads via dotenv + pydantic-settings
- `claude-code-x` — Shell, standalone per-provider `.env` (optional integration)

## What this skill does NOT do

- Touch vibe CLI config (`~/.vibe/`) — uses its own auth
- Touch OpenCode credentials (`~/.local/share/opencode/auth.json`) — proprietary store
- Encrypt keys at rest — that's a separate concern (pass/age/sops)
- Manage per-environment configs (staging/prod) — this is for local dev
