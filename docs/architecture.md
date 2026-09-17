---
generated_from_commit: fa4cb00
generated_on: 2026-09-17
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
3. **`claude/agents/`** — six personas in three families. Read `orchestrator.md` and `builder.md`
   together: they are the one place where a rule in `CLAUDE.md` is turned into a *mechanism*.
4. **`claude/commands/`** — the slash commands (explicit, user-invoked workflows). Start with
   `delegate.md`, `retro.md`, `document.md` — they carry most of the design.
5. **`claude/skills/`** — auto-routed expertise (loaded on relevance, not by name).
6. **`claude/config/delegate.yaml`** + **`claude/scripts/delegate.sh`** + the `delegate-*.py`
   helpers — the one subsystem with real runtime logic (backend routing **and** usage tracking).
   Worth reading together.

## The two surfaces (a key mental model)

Not everything costs the same in context. This distinction governs most design decisions here:

- **Always-loaded surface** — `CLAUDE.md` + the `description:` front-matter of every skill/agent.
  Cheap per item but paid *every session*. Kept lean on purpose.
- **On-demand surface** — command bodies, skill bodies, agent bodies, scripts. Loaded only when
  invoked/routed. Can be richer.
- **UX surface** — the flat slash-command namespace. A cost even when tokens are free: too many
  commands and the useful ones become invisible.

## Advisory vs. mechanical (the second mental model)

Most of this framework is **advisory**: `CLAUDE.md` states rules, and a session follows them
because it is a well-behaved reader. That is enough for preferences and style. It is not enough
where the cost of a slip is real.

Three places make a rule **mechanical** — enforced by the harness, not by good faith:

| Rule | Advisory form | Mechanical form |
|---|---|---|
| "Delegate implementation" | a paragraph in `CLAUDE.md` | `orchestrator` has no `Write`/`Edit` |
| "Don't damage the working tree" | a careful prompt | `builder` runs under `isolation: worktree` |
| "This agent is read-only" | a sentence in its body | its `tools:` allowlist |

The third one is a repaired defect, and worth remembering: three agents declared `allowed-tools:`
— the field for *skills and slash commands*. A subagent definition reads `tools:`. An unrecognized
key is ignored silently, so the agents kept every tool while their bodies announced restraint.
**A capability stated only in a prompt is a wish.** Verify against the agent listing printed at the
start of a session.

## Components

| Component | Responsibility |
|---|---|
| `install.sh` | Symlink commands/agents/scripts/skills + `CLAUDE.md`/`settings.json` into `~/.claude`; **copy** `delegate.yaml` into `~/.config/claude-code/`; warn on missing external skill dependencies; record every link in a TSV manifest; back up conflicts. |
| `uninstall.sh` | Reverse the install using the manifest — remove only what we created, only if untouched. |
| `claude/CLAUDE.md` | Always-loaded global preferences: language, problem-solving, code style, **delegation rules**, role personalities, plus the vendored Penpot AI kit block (installer-generated — never edit between its markers). |
| `claude/commands/*.md` (14) | Slash commands — explicit, user-invoked workflows (audit trio, delegate quartet, retro, document, scope, explore, bootstrap, git-commit). |
| `claude/skills/*/` (8) | Auto-routed domain expertise (agent-builder, creative-direction, data-engineering, delegate, infra-containers, provider-keys, safe-penpot-writes, security-review). |
| `claude/agents/*.md` (6) | Personas in three families — see below. |
| `claude/scripts/` | Runtime helpers: `delegate.sh` (backend router + run logger), `delegate-parse-session.py` (reads a backend's native session log for cost/tokens), `delegate-status.py` (centralized usage dashboard), `statusline.py` (default status line), `context-bar.sh` (legacy status line), `extract-defects.py` (read-only defect report feeding `/retro` §7). |
| `claude/config/delegate.yaml` | The one user-editable config — delegation backends + task→model routing. Copied, never symlinked. |
| `.claude/context/*` | **This repo's own** session memory (status, decisions, anti-patterns). Git-ignored — local scratch, project source of truth for retros. |
| `docs/` | Maintainer-facing docs: specs, these orientation docs, and the manual test protocol. Tracked, unlike `.claude/`. |

### The three agent families

| Family | Agents | Shape |
|---|---|---|
| Domain review | `data-ml-expert`, `data-rag-expert`, `infra-expert` | Read-only reviewers. Named `<domain>-<specialty>-expert`, so the `data-*` family is visible at a glance. |
| Role | `creative-director` | A stance, not a reviewer — it produces artifacts and argues back. |
| Workflow | `orchestrator`, `builder` | The pair that runs the work: one decides and never writes, the other writes and never decides. |

Reviewer agents pair with a knowledge skill (`infra-expert` ↔ `infra-containers`, `data-ml-expert`
↔ `ml-review`). `data-rag-expert` is currently the exception — see the drift summary in
[`reference.md`](reference.md).

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

Two delegation chains coexist, and they are not interchangeable:

```
   claude --agent orchestrator
            │  no Write/Edit — cannot implement, by construction
            │
            ├──▶ builder (subagent)          in-process, Claude-native
            │      isolation: worktree ──▶ throwaway copy of the repo
            │      returns Done / Verified / Not done / Assumptions / Noticed
            │
            ├──▶ data-* | infra-expert       read-only review, results return
            │
            └──▶ /delegate ──▶ external CLI  cheaper, out-of-process, no worktree
                                             review the diff yourself
```

`builder` is chosen when the task is Claude-native and must be contained; `/delegate` when the task
is cheap enough that an external model earns the round trip. Both end at the same place: the
orchestrator reads the diff.

## Boundaries & extension points

- **Add a command** → drop a `.md` in `claude/commands/`; `install.sh` globs `FILE_DIRS`, so a
  re-run (or a manual symlink) picks it up. Bar is high — see namespace cost above.
- **Add a skill** → a folder under `claude/skills/` with a `SKILL.md` (auto-routes on its
  `description`). Preferred over a command when it should trigger by relevance, not by name.
- **Add an agent** → a `.md` in `claude/agents/`, then **re-run `install.sh`** — an agent created
  directly in `~/.claude/agents/` is unversioned and lost on a machine change (this happened to
  `data-ml-expert` for six months). Use `tools:`, never `allowed-tools:`, and check the result
  against the session's agent listing. `/agent-builder` step 5 covers the traps.
- **Add an external-dependency skill** → register it in `install.sh`'s `SKILL_DEPS` table so the
  installer warns when the dependency is absent, instead of the skill failing at use time.
- **Change delegation models** → edit `claude/config/delegate.yaml`, then re-sync the installed
  copy at `~/.config/claude-code/delegate.yaml` (it's a copy, not a symlink — they can diverge).
- **Don't** put durable artifacts in `.claude/` — it's git-ignored scratch. Tracked docs go in `docs/`.
- **Don't** edit between an external installer's markers (the `<!-- penpot-ai-kit:begin/end -->`
  block in `CLAUDE.md`). It is rewritten in place on every install, through the symlink, so edits
  there are destroyed and reappear as diffs nobody authored. Put local rules in an owning section
  outside the markers.
- **Config vs symlink rule**: things the *user edits at runtime* are copied (`delegate.yaml`);
  things the *repo owns* are symlinked. Respect this when adding new config.
- **Usage tracking is parse-only**: cost/tokens come from each backend's *own* session logs — this
  repo never re-implements pricing. See [`reference.md`](reference.md) for the correlation caveat.
- **The installed tree is not a mirror — check it, both directions.** The symlink model makes the
  repo authoritative *for what it contains*, and says nothing about what else lives in `~/.claude/`.
  Two ways they diverge, both live today: an artifact created directly in `~/.claude/` is a plain
  file the installer never links and git never sees (four commands are in that state — see
  [`reference.md`](reference.md)); and `delegate.yaml`, being a **copy**, drifts on the installed
  side, where it is currently *ahead* of the repo. A fresh install on a new machine loses the first
  and regresses the second. The check is mechanical and belongs to
  [`test-protocol.md`](test-protocol.md) §A.
- **Docs freshness is commit-based, and that is a real limit**: `/retro` compares this file's
  `generated_from_commit` stamp to `HEAD`. It cannot see uncommitted work. A session that writes all
  day without committing leaves these docs describing a tree that has moved, while the check reports
  them fresh. `/document` regenerates from the working tree, so running it is the answer — the flag
  is a reminder, not a guarantee.

## Related docs

- [`learning-loop-spec.md`](learning-loop-spec.md) — the specification behind `/retro`'s
  capitalization step. Complementary, not superseded by these two files.
- [`reference.md`](reference.md) — the public surface of each component, plus the drift and debt
  the owner has to arbitrate.
- [`test-protocol.md`](test-protocol.md) — what only a person can verify in this framework, and how.
  This repo has no test suite, so that document is the whole verification layer.
