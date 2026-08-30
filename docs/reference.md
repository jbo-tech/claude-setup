# Reference — claude-setup

What the code actually does (public surface), with **intent-vs-reality drift** flagged. Intent is
read from `.claude/context/decisions.md` + `status.md`. See [`architecture.md`](architecture.md)
for the mental model.

> Note: `.claude/` is git-ignored, so the intent record (`decisions.md`) is local scratch, not
> tracked history. Drift below is correct as of generation; much of it is simply **this session's
> work not yet captured by `/retro`** — running `/retro` should clear most "untraced" items.

## Drift — to arbitrate

**Recorded but not applied**
- None open. The `delegate.sh` permission — the oldest item here, carried unactioned across four
  generations of this doc — was **closed on 2026-08-30 by dropping it**, not by doing it. Three
  months of tolerating the approval prompt was taken as the answer. Now traced in `decisions.md`,
  so it does not return as untraced drift.

**Code diverged from a recorded decision**
- None open. `learning-loop-spec.md` declared itself *"pas encore implémentée"* while the loop had
  been running since 2026-06-04 (22 candidates in the ledger, last entry 2026-08-29). **Fixed
  2026-08-30:** its status line now says implemented, names `retro.md` §7 as authoritative, and
  states what the spec still carries that the command does not.

**Significant choices with no traced decision** (silent drift — likely pending `/retro`)
- None open. The per-task model mapping in `delegate.yaml` is now covered by the 2026-06-04
  *"Delegate provider : opencode-go"* decision, which records the tier ventilation explicitly.
  This item is **cleared**.

**Known debt**
- ⚠ **debt: `storage` persistence across `execute_code` calls is unmeasured.**
  `verifyPersistence.js` carries its baseline between two calls through a `storage` object. Nothing
  confirms that object survives. *Partly mitigated 2026-08-29:* the dependency line now lists the
  real five-function surface, and part B returns `baselineLost: true` with a stray count instead of
  the naive `revn > undefined` comparison, which reported a healthy session as unpersisted.
  *Remaining cost:* the pre-flight is unusable across two separated calls until the behaviour is
  confirmed with `penpot_api_info` — run part A and part B back to back meanwhile. → *File:*
  `claude/skills/safe-penpot-writes/scripts/verifyPersistence.js`.
- ⚠ **debt: the staleness flag is blind to uncommitted work.** `/retro` step 8 runs
  `git diff --stat <stamp>..HEAD -- . ':(exclude)docs/'`. Demonstrated on this run: the stamp equals
  `HEAD`, so the check reports **0 files changed** while five files sit dirty in the working tree —
  including the skill these docs describe. The mechanism is correct for its stated job (flagging
  drift across commits) and silently wrong for how this repo is actually used (a full session of
  work before a single commit). *Cost:* the one automated signal that these docs went stale is
  absent exactly when a long session makes them stale. → *Files:* `claude/commands/retro.md` §8,
  `docs/architecture.md` front-matter. *Question:* compare against the working tree
  (`git status --porcelain` alongside the commit diff), or accept the limit and rely on running
  `/document` deliberately?
- ⚠ **debt: failure mode #8 is reported, not measured.** `remove()` on a component descendant is
  said to hide rather than delete. It is documented with that caveat stated in the text and a probe
  (`scripts/verifyRemoval.js`) that settles it, but the skill's contract is *"each measured on a
  real file"* and this one is not. *Cost:* one entry in an eight-entry list carries a weaker
  warrant than the rest; leaving the label off would have been worse. → *File:*
  `claude/skills/safe-penpot-writes/SKILL.md` §8.
- ⚠ **debt: usage-tracking correlation is timestamp-based.** `delegate-parse-session.py` matches a
  run to a backend session by *workdir + "most recent session at/after run start"*. Concurrent
  delegations in the same directory can mis-attribute metrics. Acceptable for sequential use (the
  normal case); documented in `SKILL.md`. *Cost:* wrong cost line on a run under heavy parallel use.
- ⚠ **debt: Vibe `-p` no-op on this machine.** Vibe in programmatic mode returns 0 tokens / 0 files
  without calling the model (likely auth/quota). The tracker faithfully logs the 0, so a Vibe
  delegation looks "successful but empty". *Cost:* silent no-work delegations until Vibe's `-p` path
  is fixed. Not a tracking bug — flagged so it isn't mistaken for one. → *File:* external (Vibe).
- ⚠ **debt: no automated tests.** The whole framework is validated manually (per the v1 scope's
  explicit "tests out of scope"). `install.sh`'s new `check_skill_deps` and the six agent frontmatters
  were validated by one live run and by reading the session's agent listing, not by a suite.
  *Cost:* a frontmatter field silently ignored is exactly the class of bug that went unnoticed for
  six months — and nothing but a human reading the listing catches it today.
- ⚠ **debt: `builder` and `orchestrator` are unexercised.** Both were written, installed and
  committed on 2026-08-29 without a real run. The contract (worktree containment, the five report
  headings, resumption at `maxTurns`) is documented and mechanically plausible, not observed.
  *Cost:* the first real delegation is also the first test. → *Files:* `claude/agents/builder.md`,
  `claude/agents/orchestrator.md`.

**Also worth watching (not strict drift)**
- **`data-rag-expert` has no paired knowledge skill.** Every other reviewer pairs with one
  (`infra-expert` ↔ `infra-containers`, `data-ml-expert` ↔ `ml-review`). It is also described as the
  most-solicited profile. An agent must be invoked; a skill loads on the words of the subject. The
  2026-08-29 decision records this as a watch item with a concrete trigger: if you find yourself
  wanting the knowledge inline rather than as a review pass, add the skill.
- **Namespace pressure is now on two axes.** Commands: **13** (early decisions targeted ~8); the
  four `delegate*` are one feature, so the real question is the long tail (`bootstrap`, `explore`,
  the `audit-*` trio). Agents: **6**, up from 2 — the family naming holds for now, but the
  anti-pattern note applies equally: *an artifact with 0 invocations in 60 days is a deletion
  candidate*.
- **`claude/CLAUDE.md` now carries vendored third-party content.** The Penpot AI kit block is
  installer-generated and rewritten in place through the symlink. It is committed on purpose, but it
  means `git diff` on that file can show changes nobody in this repo wrote.

**Docs inventory — does each doc earn its place?**
- `learning-loop-spec.md` → **keep** (complementary: 199 lines holding the reasoning behind the
  three axes, the detailed routing matrix, the risks to validate and the out-of-scope list; the
  40-line operational contract lives in `retro.md` §7 and is authoritative). Status line corrected
  2026-08-30. The overlap between the two is real: **the open option is pruning the spec down to
  reasoning + risks**, deferred until the duplication actually misleads someone.
- `architecture.md`, `reference.md` → owned/regenerated by `/document`.
- No redundant or orphaned docs found. Doc set is sharp; the only issue is one stale status line.

> **Cleared since the 2026-06-13 generation:** the `delegate.yaml` per-task model mapping (traced
> in the 2026-06-04 opencode-go decision), the `delegate.sh` permission (dropped 2026-08-30) and the
> `learning-loop-spec.md` status line (fixed 2026-08-30). **No drift is open today** — the list
> below is debt and watch items only.

---

## Components

### install.sh
- **Invocation:** `./install.sh [-n|--dry-run] [-y|--backup-all] [-h|--help]`
- **Target:** `$CLAUDE_HOME` or `~/.claude` (`TARGET`). Config copies go to `~/.config/claude-code/`.
- **What it links** (`claude/` → `~/.claude/`):
  - `ROOT_FILES=(CLAUDE.md settings.json)` — symlinked.
  - `FILE_DIRS=(commands agents scripts)` — each *file* symlinked individually (so new files are
    picked up on re-run).
  - `DIR_DIRS` (skills) — each *subfolder* symlinked atomically (one link per skill).
  - `config/delegate.yaml` — **copied** to `~/.config/claude-code/`, not symlinked (user edits it
    at runtime; a symlink would write back into the repo).
- **Manifest:** `$TARGET/.claude-setup-manifest`, TSV `dst\tsrc\ttimestamp` — every link logged for
  a safe uninstall.
- **Conflict handling:** existing non-matching file → backup (interactive prompt, or `-y` for all).
  Idempotent: an existing correct symlink is a no-op.
- **Gotcha (resolved):** runs under `set -euo pipefail`; past silent deaths came from `read </dev/tty`
  without a TTY and from `[ ] && cmd` as a function's last statement. Use `if/then` at function tails.
- **Side checks:** warns if the `ruff` Python-format hook in `settings.json` can't run
  (`check_ruff`), and warns when a skill's **external dependency** is absent (`check_skill_deps`).
  The latter is table-driven — `SKILL_DEPS` holds `<skill>|<expected path>|<label>|<url>` rows and
  is skipped for any skill not present in the repo. Currently one row: `safe-penpot-writes` expects
  the Penpot AI kit at `~/.claude/skills/penpot-router`. It **warns, never fails**: without the kit
  the skill still reads as documentation, only its scripts can't run.

### uninstall.sh
- Reverses install from the manifest. Contract: **only removes what we created, only if untouched.**
  A link the user replaced/edited is left alone.

### claude/CLAUDE.md
- The only **always-loaded** file. Sections: language rules (French conversation default, English
  code), problem-solving, decision framework, code style, surgical-changes principles,
  **Delegation** (explicit `/delegate` overrides the gate; auto-mode via `.claude/delegate-auto`;
  skip criteria must be verifiable), role personalities.
- **Two trailing sections added 2026-08:** `## Penpot — local complement` (locally authored: declares
  `safe-penpot-writes` as an addition to whatever the Penpot router picked, since the router's rule 3
  says "pick exactly ONE"), then the vendored `<!-- penpot-ai-kit:begin/end -->` block.
- ⚠ **Gotcha:** the vendored block is rewritten in place by the kit's installer, which writes to
  `~/.claude/CLAUDE.md` — a symlink to this file. Edits between the markers are destroyed on the next
  install. Local rules go in an owning section *outside* them.

### claude/commands/ (13)
Explicit, user-invoked. The load-bearing ones:
- **`delegate.md`** + `delegate-on/off/status.md` — hand a bounded task to a cheaper backend; Claude
  decomposes + reviews the diff. `--task` routes to a specialized model. `delegate-status` shows the
  active backend **and** the centralized cost/token dashboard (via `delegate-status.py`).
- **`retro.md`** — end-of-session retrospective: rewrites `status.md`, appends `anti-patterns.md`/
  `decisions.md`, applies `CLAUDE.md`/`README.md`. Now also runs the **learning-loop** capitalization
  (step 7) and **flags doc staleness** (step 8, keys off `architecture.md` front-matter).
- **`document.md`** — this command: regenerates `architecture.md` + `reference.md` on demand.
- **`audit.md`** / `audit-ml.md` / `audit-accessibility.md` — review passes (security/optimization/
  homogeneity; ML; a11y).
- **`scope.md`**, `bootstrap.md`, `explore.md`, `git-commit.md`.

### claude/skills/ (8)
Auto-routed by `description`. `agent-builder`, `creative-direction`, `data-engineering`, `delegate`,
`infra-containers`, `provider-keys`, `safe-penpot-writes`, `security-review`. The `delegate` skill
mirrors the command logic for relevance-based triggering.

Two carry more than guidance:

- **`agent-builder`** — creates agents from two templates (`expert-template.md`,
  `creative-template.md`). **Step 5** is the load-bearing part: an agent's allowlist is `tools:`,
  never `allowed-tools:` (the field for skills and slash commands). An unrecognized key is ignored
  silently, so the agent keeps every tool while its body claims restraint. Also documents that
  `tools:` *replaces* the inherited pool (so `WebSearch`/`WebFetch`/`Skill` vanish unless listed),
  that each tool needs its own parenthesis — `Bash(docker:*), Bash(podman:*)`, not
  `Bash(docker:*, podman:*)` — and that `Agent(a, b)` only binds in the main thread.
- **`safe-penpot-writes`** — read-back discipline for the Penpot plugin API, whose write path fails
  silently. **Eight** failure modes — seven measured on a real file, #8 reported and explicitly
  labelled as unmeasured. Complements the external Penpot AI kit rather than duplicating it, and is
  deliberately **not** named `penpot-*` because the kit installer's `--prune` removes any `penpot-*`
  skill it does not ship. Five `execute_code` scripts: `inventoryConsumers.js` (baseline before),
  `verifyBindings.js` (the read-back), `rebuildCopy.js` (rebuild a component copy, replaying
  interactions), `verifyPersistence.js` (two-part pre-flight proving writes reach the *server*, not
  just the tab), `verifyRemoval.js` (proves a deletion inside a component removed rather than hid).
  ⚠ **debt:** two open items — see the drift summary.

### claude/agents/ (6)
Three families. All six declare `tools:` — the field a subagent definition actually reads.

| Agent | Family | `tools:` | Notes |
|---|---|---|---|
| `data-ml-expert` | domain review | `Read, Grep, Glob, Bash(python:*), Bash(pytest:*), Bash(duckdb:*)` | ETL, feature engineering, leakage, model validation, serving. |
| `data-rag-expert` | domain review | `Read, Grep, Glob, WebSearch, WebFetch` | Hybrid retrieval + RAG evaluation. **No Bash** — it cannot run an eval, only read one. |
| `infra-expert` | domain review | `Read, Grep, Glob, Bash(docker:*), Bash(podman:*), Bash(kubectl:*), Bash(systemctl status:*)` | Read-only by allowlist, not just by prompt. |
| `creative-director` | role | `Read, Write, Edit, Grep, Glob, WebSearch, WebFetch` | Produces artifacts; the web tools are needed to check a name is free. |
| `orchestrator` | workflow | `Agent(builder, data-ml-expert, data-rag-expert, infra-expert, creative-director, general-purpose, Explore, Plan), Read, Grep, Glob, Bash, Skill, TodoWrite` | Main-thread pilot. |
| `builder` | workflow | `Read, Grep, Glob, Edit, Write, Bash, TodoWrite, Skill` | Worker. |

**`orchestrator`** — start a session with `claude --agent orchestrator`. Has **no `Write`/`Edit`**,
which turns the delegation rule in `CLAUDE.md` from a paragraph into the shape of the agent.
- ⚠ **Gotcha:** the `Agent(a, b)` allowlist binds **only** when the agent runs as the main thread.
  Spawned as an ordinary subagent, the parenthesised list is ignored.
- ⚠ **Honest limit, stated in its own body:** `Bash` can still write (`sed -i`, a heredoc, a
  redirection). A redirection is a single command whose prefix is the reading command, so no
  `permissions.deny` prefix rule catches it, and the set of file writers is not enumerable —
  sandboxing, not deny rules, is the mechanism for that. The constraint is that writing is no longer
  the shortest path, not that it is impossible.

**`builder`** — the worker `orchestrator` cannot be. Containment is mechanical:
- `isolation: worktree` — changes land in a temporary git worktree branched from the **default
  branch** (not the parent's `HEAD`), auto-cleaned if nothing changed. Bash is confined to it, and a
  command redirecting git into the main checkout is refused.
- `permissionMode: acceptEdits`, `maxTurns: 40`, `model: sonnet`. At the turn limit the output is
  marked **partial** and the agent can be messaged to resume — a budget, not a wall.
- No `Agent` (the delegation tree stays flat), no web tools (it implements against a spec).
- `background` is deliberately **unset** so the caller chooses: background to walk away, foreground
  to watch. Its result then arrives as a completion notification in a later turn.
- **Report contract:** five headings — `Done`, `Verified`, `Not done`, `Assumptions`,
  `Noticed, not touched`. The last four are mandatory; an empty one is information, a missing one
  reads as a claim.
- ⚠ **debt:** never run. See the drift summary.

### claude/scripts/
- **`delegate.sh`** — `delegate.sh [--backend <name>] [--task <type>] <workdir> <prompt> [timeout]`.
  Parses flags position-independently, picks a backend from `delegate.yaml` (by `--backend`, else by
  `--task` tag with fallback to untagged, else first generalist in PATH), writes the prompt to a temp
  file (no shell injection), runs with a timeout (PTY via `script` for vibe), then **calls
  `delegate-parse-session.py`** to pull real cost/tokens, and logs one enriched JSONL line to
  `~/.local/share/claude-code/delegate-runs.jsonl`. Reports backend/model/exit/duration,
  `git status --short`, and a `[delegate] Usage: $cost | N tokens` line.
  - **Gotcha:** the parser is located via `readlink -f "$0"` — invoked through the `~/.claude/scripts`
    symlink, a plain `dirname "$0"` would point at the symlink dir (where siblings don't exist).
  - **Injection safety:** the run facts + parsed metrics are passed to the logging Python via
    **environment variables**, never interpolated into the source string.
- **`delegate-parse-session.py`** — `delegate-parse-session.py <backend> <workdir> <run_start_epoch>`.
  Reads a backend's *native* session log and prints a JSON dict of metrics (`input_tokens`,
  `output_tokens`, `total_tokens`, `cost`, `steps`, `session_id`, `session_dir`) — only keys it
  resolved. **Best-effort:** prints `{}` and exits 0 on any failure. Backends:
  - `vibe*` → newest `~/.vibe/logs/session/session_*/meta.json` whose mtime ≥ run start (5s slack),
    reads `stats.session_cost` / prompt+completion tokens / `steps`.
  - `opencode*` → `opencode session list --format json` to find the newest session in this workdir
    at/after run start, then `opencode export <id>` for `info.cost` / `info.tokens`.
- **`delegate-status.py`** — `delegate-status.py [--log <path>] [--days N]`. Read-only aggregator of
  the JSONL: total/today cost, total tokens, error count, per-`backend · model` breakdown. Tolerates
  legacy lines missing metric fields (counted as "untracked", contribute $0). Surfaced by
  `/delegate-status`.
- **`statusline.py`** — default status line: context usage, 5h/7d rate-limit quotas, minimal git.
- **`context-bar.sh`** — legacy bash status line (theme color configurable).

**Delegate JSONL schema** (one line per run): `timestamp, backend, model, task, duration_secs,
exit_code, files_changed, workdir` (v1) + `input_tokens, output_tokens, total_tokens, cost, steps,
session_id, session_dir` (phase 2; `null` when the backend exposed nothing).

### claude/config/delegate.yaml
- **Backends** (each: `command`, `args`, `workdir_flag`, `model`, optional `task`, `priority`,
  `needs_pty`). Selection: lowest `priority` whose `command` is in PATH, filtered by `task` when set.
- **Generalists (no task):** `vibe` (`mistral-medium-3.5`, priority 1, PTY) → `opencode`
  (`opencode-go/deepseek-v4-pro`, priority 2).
- **Task-specialized:** `coding`→`opencode-go/deepseek-v4-flash` (easy), `python`→`opencode-go/minimax-m3`
  (complex, alt `glm-5.1`), `marketing`→`opencode-go/deepseek-v4-pro` (medium).
- **Settings:** `default_timeout: 120`, `log_file`.
- **Gotcha:** this file is a **copy** in `~/.config/claude-code/` — editing the repo doesn't update
  the live one until re-synced.

### docs / specs
- `docs/learning-loop-spec.md` — full spec of the `/retro` capitalization loop (3 axes, candidate
  ledger, conservative cursor). `.claude/context/*` is the project-level source of truth.
  ⚠ **drift:** its status line still says *"pas encore implémentée"*. It is implemented and running.
- `docs/architecture.md`, `docs/reference.md` — these orientation docs.
