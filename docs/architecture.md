---
generated_from_commit: d0e4ff7
generated_on: 2026-06-13
---

# Architecture — claude-setup

> Orientation doc, not a README. For the maintainer who steers this framework and needs to see
> how it fits together. Usage/install lives in [`README.md`](../README.md).

## What & why

`claude-setup` is a **personal Claude Code framework**, packaged as a dotfiles-style repo. It
holds a curated set of slash commands, skills, agents, scripts and config, and an **installer
that symlinks them into `~/.claude/`** so the working copy *is* the repo — edit here, it's live
everywhere. The guiding tension throughout is **leverage vs. namespace cost**: every command/skill
added is paid for in a flat menu the maintainer has to scan, so the bar to add is deliberately high.

## Reading order

To understand the system, read in this order:

1. **`install.sh`** — the heart. It decides *what* gets linked where and *how* (symlink vs copy).
   Understand `FILE_DIRS`, `DIR_DIRS`, `ROOT_FILES`, and the manifest, and you understand the whole
   distribution model.
2. **`claude/CLAUDE.md`** — the always-loaded behavioral contract (preferences, delegation rules,
   role personalities). This is the only file loaded into *every* session's context.
3. **`claude/commands/`** — the slash commands (explicit, user-invoked workflows). Start with
   `delegate.md`, `retro.md`, `document.md` — they carry most of the design.
4. **`claude/skills/`** + **`claude/agents/`** — auto-routed expertise (loaded on relevance, not
   always). Lower priority for a first pass.
5. **`claude/config/delegate.yaml`** + **`claude/scripts/delegate.sh`** + the `delegate-*.py`
   helpers — the one subsystem with real runtime logic (backend routing **and** usage tracking).
   Worth reading together.

## The two surfaces (a key mental model)

Not everything costs the same in context. This distinction governs most design decisions here:

- **Always-loaded surface** — `CLAUDE.md` + the `description:` front-matter of every skill/agent.
  Cheap per item but paid *every session*. Kept lean on purpose.
- **On-demand surface** — command bodies, skill bodies, scripts. Loaded only when invoked/routed.
  Can be richer.
- **UX surface** — the flat slash-command namespace. A cost even when tokens are free: too many
  commands and the useful ones become invisible.

## Components

| Component | Responsibility |
|---|---|
| `install.sh` | Symlink commands/agents/scripts/skills + `CLAUDE.md`/`settings.json` into `~/.claude`; **copy** `delegate.yaml` into `~/.config/claude-code/`; record every link in a TSV manifest; back up conflicts. |
| `uninstall.sh` | Reverse the install using the manifest — remove only what we created, only if untouched. |
| `claude/CLAUDE.md` | Always-loaded global preferences: language, problem-solving, code style, **delegation rules**, role personalities. |
| `claude/commands/*.md` | Slash commands — explicit, user-invoked workflows (audit, delegate, retro, document, scope, …). |
| `claude/skills/*/` | Auto-routed domain expertise (data-engineering, security-review, infra-containers, agent-builder, creative-direction, delegate). |
| `claude/agents/*.md` | Horizontal-scope personas (creative-director, infra-expert). |
| `claude/scripts/` | Runtime helpers: `delegate.sh` (backend router + run logger), `delegate-parse-session.py` (reads a backend's native session log for cost/tokens), `delegate-status.py` (centralized usage dashboard), `statusline.py` (default status line), `context-bar.sh` (legacy status line). |
| `claude/config/delegate.yaml` | The one user-editable config — delegation backends + task→model routing. Copied, never symlinked. |
| `.claude/context/*` | **This repo's own** session memory (status, decisions, anti-patterns). Git-ignored — local scratch, project source of truth for retros. |
| `docs/` | Maintainer-facing docs (specs + these orientation docs). Tracked, unlike `.claude/`. |

## How it fits

```
        repo (source of truth)                    ~/.claude (live)
   ┌──────────────────────────┐   install.sh   ┌─────────────────────┐
   │ claude/CLAUDE.md          │ ─ symlink ───▶ │ CLAUDE.md           │
   │ claude/commands/*.md      │ ─ symlink ───▶ │ commands/*.md        │
   │ claude/skills/*/          │ ─ symlink ───▶ │ skills/*/            │
   │ claude/agents/*.md        │ ─ symlink ───▶ │ agents/*.md          │
   │ claude/scripts/*          │ ─ symlink ───▶ │ scripts/*            │
   │ claude/config/delegate.yaml│ ─ COPY ──┐    │ .claude-setup-manifest (TSV)
   └──────────────────────────┘           │    └─────────────────────┘
                                           └──▶ ~/.config/claude-code/delegate.yaml

   Runtime (a session):  CLAUDE.md (always) ──┐
                         skills/agents desc ──┼─▶ Claude Code context
                         /command invoked ────┘
                              │
              /delegate ──▶ delegate.sh ──reads──▶ delegate.yaml ──picks backend──▶ vibe | opencode(-go)
                              │                                                          │ writes native logs
                              │ after run                                                ▼
                              └─▶ delegate-parse-session.py ──reads──▶ ~/.vibe/logs | opencode export
                                        │ cost / tokens / session_id
                                        ▼
                              delegate-runs.jsonl ◀──aggregates── delegate-status.py ──▶ /delegate-status
```

## Boundaries & extension points

- **Add a command** → drop a `.md` in `claude/commands/`; `install.sh` globs `FILE_DIRS`, so a
  re-run (or a manual symlink) picks it up. Bar is high — see namespace cost above.
- **Add a skill** → a folder under `claude/skills/` with a `SKILL.md` (auto-routes on its
  `description`). Preferred over a command when it should trigger by relevance, not by name.
- **Change delegation models** → edit `claude/config/delegate.yaml`, then re-sync the installed
  copy at `~/.config/claude-code/delegate.yaml` (it's a copy, not a symlink — they can diverge).
- **Don't** put durable artifacts in `.claude/` — it's git-ignored scratch. Tracked docs go in `docs/`.
- **Config vs symlink rule**: things the *user edits at runtime* are copied (`delegate.yaml`);
  things the *repo owns* are symlinked. Respect this when adding new config.
- **Usage tracking is parse-only**: cost/tokens come from each backend's *own* session logs
  (Vibe `meta.json`, OpenCode `export`) — no pricing table is maintained here. To support a new
  backend's metrics, add a `parse_<backend>` branch in `delegate-parse-session.py`; if it can't be
  parsed, the run is still logged with `null` metrics. Monitoring is **passive** — no hard limits.
- **A new sibling script needs its own symlink.** `install.sh` links each *file* in `scripts/`
  individually, and `delegate.sh` resolves siblings via `readlink -f "$0"`. Adding a script to the
  repo isn't enough for the current session until it's symlinked (re-run `install.sh`).

See [`reference.md`](reference.md) for the per-component detail and current intent-vs-reality drift.
