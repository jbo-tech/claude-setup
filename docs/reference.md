# Reference — claude-setup

What the code actually does (public surface), with **intent-vs-reality drift** flagged. Intent is
read from `.claude/context/decisions.md` + `status.md`. See [`architecture.md`](architecture.md)
for the mental model.

> Note: `.claude/` is git-ignored, so the intent record (`decisions.md`) is local scratch, not
> tracked history.
>
> **This generation is the first with no open drift.** The three items that stood here on
> 2026-09-17 were all closed within a day, which is worth reading carefully rather than
> celebrating: all three had been found by comparing the *installed* tree and the recorded
> decisions against the repo — never by reading the repo alone — and none is structurally
> prevented from recurring. What the list now holds is **debt**: compromises the code carries on
> purpose, including four created this week by the very mechanisms meant to reduce it.

## Drift — to arbitrate

**Recorded but not applied**
- None open.

**Code diverged from a recorded decision**
- None open. *(The `document.md` self-contradiction closed 2026-09-17.)*

**Significant choices with no traced decision** (silent drift)
- None open. The two that stood here for weeks — five personal commands living outside the repo,
  and `delegate.yaml` diverging from its installed copy — both closed 2026-09-17, and both are now
  covered by a mechanical check ([`test-protocol.md`](test-protocol.md) §A.1 and §A.2). Neither is
  structurally prevented: the first recurs whenever a file is created directly in `~/.claude/`, the
  second whenever the copied config is edited on either side.

**Known debt**
- ⚠ **debt: `delegate.sh` reports its own exit code, not the backend's.** The wrapper returns 0
  while the backend exits **124**. Twice observed — 2026-07-11 (kimi-k2.7-code, 120s) and
  2026-09-17 (minimax-m3, 600s, ten minutes for zero files). The code is logged faithfully in
  `delegate-runs.jsonl`; nothing looks at it at the moment it matters. *Now countable:*
  `extract-defects.py` reports non-zero delegations. *Cost:* a timed-out delegation reads as a
  successful empty one until someone runs `git status`. → *File:* `claude/scripts/delegate.sh`.
  *Question:* propagate the backend's code, or keep the wrapper's and rely on the report?
- ⚠ **debt: Vibe `-p` is a no-op on this machine.** Vibe in programmatic mode returns 0 tokens and
  0 files without calling the model (likely auth or quota). The tracker logs the 0 faithfully, so
  the run looks "successful but empty". Not a tracking bug. → *File:* external (Vibe).
- ⚠ **debt: `settings.json` is shared by every project and this repo is public.** It is symlinked
  to `~/.claude/settings.json`, so anything written at user level lands here. On 2026-09-16 an
  `autoMode.environment` block describing another project arrived that way and was caught only by
  reading the diff before committing. §A.3 greps for foreign paths, but only when someone runs it.
  *Cost:* the next one is caught the same way, by a person who happens to look. → *File:*
  `claude/settings.json`. *Question:* a `pre-commit` refusing this file when it names a path
  outside the repo — rung 2 of the enforcement ladder — or keep relying on diff discipline? **This
  is the oldest open decision in the list.**
- ⚠ **debt: the briefing contract is unmeasured.** `orchestrator`/`builder`/`bootstrap`/the
  delegate skill now require every brief to carry a check command, reference files and the
  non-mechanical rules. Whether that actually reduces correction rates is unknown — the claim comes
  from a workshop REX, not from this repo. *Measurement:* defects per delegation, via
  `extract-defects.py`, over the next few sessions. → *Files:* `claude/agents/orchestrator.md`,
  `claude/agents/builder.md`.
- ⚠ **debt: `extract-defects.py` is a net, not a blanket.** It sees failed spawns, respawned tasks
  and non-zero delegations. A wrong answer accepted on the first try is invisible to it, and a
  background subagent leaves only a launch acknowledgement in the transcript. Documented in its own
  docstring. *Re-evaluate after three retros:* if it surfaces nothing usable, remove it rather than
  widen it. → *File:* `claude/scripts/extract-defects.py`.
- ⚠ **debt: `storage` persistence across `execute_code` calls is unmeasured.**
  `verifyPersistence.js` carries its baseline between two calls through a `storage` object; nothing
  confirms that object survives. *Partly mitigated 2026-08-29:* part B now returns
  `baselineLost: true` with a stray count instead of a naive `revn > undefined` comparison.
  *Remaining cost:* unusable across two separated calls until confirmed with `penpot_api_info`;
  run part A and part B back to back meanwhile. → *File:*
  `claude/skills/safe-penpot-writes/scripts/verifyPersistence.js`.
- ⚠ **debt: failure mode #8 is reported, not measured.** `remove()` on a component descendant is
  said to hide rather than delete. The skill's contract is *"each measured on a real file"* and this
  one is not — it carries the label and a probe that settles it. → *File:*
  `claude/skills/safe-penpot-writes/SKILL.md` §8.
- ⚠ **debt: usage-tracking correlation is timestamp-based.** `delegate-parse-session.py` matches a
  run to a backend session by workdir plus "most recent session at or after run start". Concurrent
  delegations in the same directory can mis-attribute metrics. Acceptable sequentially, which is
  the normal case.
- ⚠ **debt: no automated tests.** The whole framework is verified by a person, per the v1 scope.
  *Cost:* a silently-ignored frontmatter field is exactly the class of bug that went unnoticed for
  six months — three times now. The steps live in [`test-protocol.md`](test-protocol.md).

**Also worth watching (not strict drift)**
- **A declaration that looks right and never runs — three instances, and the defining failure of
  this repo.** `allowed-tools:` on three agents (six months); five commands created directly in
  `~/.claude/` and never linked; and the `ruff` hook's matcher `Write(*.py)` — a path pattern in a
  field that matches **tool names** — which meant the hook had never fired once in two months,
  while `README.md` advertised automatic Python formatting and `install.sh` warned when `ruff` was
  absent. All three are fixed. The pattern is what matters: **this framework is prose describing
  behaviour, and prose cannot fail loudly.** The defence is not more care at writing time, it is
  executing the thing once and reading the result. `test-protocol.md` §A now covers hooks (§A.3b);
  anything else declarative should get its own step there.
- **`data-rag-expert` has no paired knowledge skill.** Every other reviewer pairs with one
  (`infra-expert` ↔ `infra-containers`, `data-ml-expert` ↔ `ml-review`), and this is described as
  the most-solicited profile. An agent must be invoked; a skill loads on the words of the subject.
  The trigger recorded 2026-08-29 still stands: if you want the knowledge inline rather than as a
  review pass, add the skill. The 2026-09-18 pruning strengthens the case — it deleted three
  commands *in favour of* skills, for exactly this reason.
- ⚠ **Acted on 2026-09-30, and still not under budget.** The listing went from **36 skills /
  15 067 characters (×1.9 over)** to **24 / 11 171 (×1.40)** — 974 est. tokens freed per session.
  Removed: the `delegate` skill (folded into its command), the four `~/.agents` symlinks (vercel ×3,
  tailwind — 1 lifetime use between them), and seven third-party directories moved to
  `~/.claude/skills-retirees-20260930/` (`ml-review`, `karpathy-guidelines`, and the Stitch/design
  cluster). **The remaining overflow is one decision away:** the 12 Penpot skills carry 6 932
  characters for zero uses in 431 startups. **Applied 2026-09-30, router excluded:** eleven of the
  twelve are `name-only` in `skillOverrides`; `penpot-router` keeps its full description because the
  always-loaded Penpot block in `CLAUDE.md` names it as the dispatcher, and `safe-penpot-writes`
  keeps its own because that block says it adds to whatever the router picked. Final state: **24
  skills, 4 792 effective characters — ×0.60, under budget with margin**, and 6 379 characters still
  invocable by name. Path: 15 067 (×1.9) → 11 171 (×1.40) → 4 792 (×0.60).
  *Maintenance, and it is the real risk:* a kit update that **adds or renames** a `penpot-*` skill
  escapes the map and takes a full description back, silently. → *Check:*
  [`test-protocol.md`](test-protocol.md) §A.3c, to be run after every kit update.
  **§B.3 can now finally be re-run meaningfully** — for the first time the skills under test have
  their descriptions inside the budget.
- ⚠ **Two skill descriptions did not parse as YAML, and `claude plugin validate` passed anyway.**
  Found 2026-09-30 while specialising: a `: ` inside a description value (`…deployment: healthchecks…`,
  `…agent: use it…`) makes the YAML a mapping and the block invalid. Per the documentation a skill
  whose frontmatter fails to parse **still loads, with every field dropped** — name falls back to the
  directory, description to the first line of the body, and `allowed-tools`/`model`/`paths` silently
  stop applying. Both were self-inflicted, both fixed the same minute, and all 24 loaded skills now
  parse under a strict YAML reader. *The finding that matters is the tool's:* `claude plugin validate`
  reported **✔ passed** on the broken file. It is not a sufficient check — the repo's characteristic
  failure has a new instance, in the very command meant to catch it. → *Check:*
  [`test-protocol.md`](test-protocol.md) §A should gain a strict YAML parse of every loaded SKILL.md.
- ⚠ ~~**Only 8 of the 36 skills in `~/.claude/skills/` are ours.**~~ Measured 2026-09-29: the 8 symlinked from this repo carry 3 299 characters of
  description — **22 %** of the listing; the remaining 78 % belongs to third parties. Of those, 5 are
  symlinks to `~/.agents/skills/` (a separate source) and **23 are plain directories dropped straight
  into `~/.claude/skills/`** — 12 from the Penpot kit, plus `impeccable`, `ml-review`,
  `karpathy-guidelines`, the `stitch-*` and design cluster, `skill-factory`, `find-skills`,
  `stop-slop`, and the `synced` folder from claude.ai. Those 23 are unversioned, invisible to
  `install.sh`, and lost on a machine change — **the stray-command failure repeating on the skills
  axis**, one layer over. They also set the priority of the listing by accident rather than by
  decision. *Two questions, and they are different:* which of the 28 are still wanted (a namespace and
  budget call, answerable with `/skill-doctor`), and which deserve versioning somewhere rather than
  living as loose directories. → *Check:* [`test-protocol.md`](test-protocol.md) §A.1 covers commands
  and agents only; it does not look at `skills/`, and it should.
- ⚠ **2026-09-29: skills do not fire — but the diagnosis was wrong, and the remedy is the opposite
  of deletion.** The documentation names a mechanism that explains every failed run: Claude Code
  loads a listing of skill names and descriptions capped at **1% of the context window**, and when it
  overflows it **drops descriptions — starting with the skills you invoke least**, which "removes the
  keywords Claude needs to match your request". Measured here: **36 personal skills, 15 067
  characters** of `description` + `when_to_use`, against a default budget of roughly 8 000 characters
  — **about twice over, before counting plugin and bundled skills.** The three skills that failed to
  trigger have almost certainly never been invoked, so they are first in line to lose their
  descriptions. **Claude may never have seen their keywords at all.** Eliminated as a cause:
  malformed frontmatter (`claude plugin validate ./claude/skills` passes; note that validating
  `~/.claude/skills` silently skips ours, because 13 entries there are symlinks and it does not
  follow them). *Authoritative numbers need a session:* `/doctor` reports the listing's context cost
  and its biggest contributors, `/context` the Skills row after the budget applies, `/skill-doctor`
  the unused skills. *Remedies, all documented:* raise `skillListingBudgetFraction`; set
  low-priority entries to `name-only` in `skillOverrides` (the 12 Penpot skills alone carry ~5 800
  characters and matter only during Penpot work); trim descriptions at the source; add `paths` globs
  so a skill activates only on matching files. **Deletion is suspended** — three skills were within
  one decision of being removed on a cause that is probably not theirs.
- ⚠ ~~**Settled 2026-09-29 over four valid runs: skills do not fire on relevance, and their content
  would have been a downgrade.**~~ *Superseded above; the measurement stands, the explanation does
  not.* `data-engineering` on `veilleuse` and on `s3dedup`,
  `infra-containers` on `veilleuse`, `security-review` on `groovekeeper` — trigger words present
  **verbatim** each time ("ingestion"; "docker compose"; "pipeline" + "duckdb" + "idempotent"; the
  subject named outright), correct terrain each time, **no skill loaded once.** And each answer found specific defects no checklist in those skills
  holds: a compose header contradicting its own README about an abandoned deployment procedure, a
  healthcheck proving the port rather than readiness, and two reproduced DuckDB bugs — `LIKE` with
  `_` as a wildcard deleting neighbouring keys from the index, and stale media metadata surviving an
  ETag change. The sessions investigated the repository and its own docs; general guidance would have
  produced less. **The criterion follows: a skill earns its place only when it holds knowledge the
  model does not already have** — measured facts, project quirks, a convention against the default.
  `safe-penpot-writes` and `agent-builder` qualify (eight measured failure modes of a silently
  failing API; the `tools:` vs `allowed-tools:` trap). `data-engineering`, `infra-containers` and
  `security-review` do not, on this evidence — and `security-review` was widened two days earlier
  *specifically* on the premise that just failed. *Caveats, and the second is load-bearing:* four samples, all on subjects the model handles well in
  documented repositories, so an obscure-knowledge skill may still be used; and **both security runs
  were negatives** — nothing shows a session *catching* a real vulnerability as well as a checklist
  would, only that it correctly clears clean code. `claude plugin eval` with its no-plugin baseline
  arm is the A/B that would settle it. *Decision pending.* The superseded earlier note follows.
- ⚠ ~~**Measured 2026-09-25: skills do not fire on relevance.**~~ Two valid runs of [`test-protocol.md`](test-protocol.md) §B.3, both **outcome 2**:
  no skill was loaded, and the session answered well anyway. The decisive one is
  `data-engineering` on `veilleuse`, where the trigger word `"ingestion"` appeared **verbatim**, in
  the right terrain, on a project carrying an explicit idempotence constraint. It still did not load.
  So the failure is not vocabulary — **matching the description is not sufficient.** A skill is
  loaded when the model judges it needs guidance, and on a subject it handles it does not reach for
  one; in `veilleuse` it read the project's own `IMPLEMENTATION.md` instead, which is more specific
  than any generic skill could be.
  This cuts both ways, and the second half is the more useful finding: both answers surfaced real
  defects that **neither skill's checklist contains** — an upsert leaving orphaned points when a
  document re-chunks into fewer fragments, and an unescaped `file:` URI in three places. The
  argument for the September pruning ("a skill fires by itself") is false; its *outcome* is fine for
  a reason nobody tested — there was little there to lose.
  **The criterion this suggests:** a skill earns its place when it holds knowledge the model does
  **not** already have — measured facts, project quirks, a convention that runs against the default.
  `safe-penpot-writes` is the clean case: eight failure modes of an API that fails silently, seven
  measured on a real file. A skill that restates general good practice will not be invoked, because
  nothing needs it. *Open:* run `infra-containers` on `veilleuse/deploy` for a third data point, then
  decide whether `security-review` and `data-engineering` are themselves deletion candidates by
  their own rule. *Note:* `security-review` was widened only days earlier *specifically* to carry the
  axis `/code-review` does not cover — that reasoning now needs re-examining, not defending.
- **The namespace is at 11 commands, and there is still no counter.** 18 → 11 on 2026-09-18, on the
  criterion "Claude Code does this natively now". The standing rule *an artifact with 0 invocations
  in 60 days is a deletion candidate* has never once been applied mechanically, because nothing
  counts invocations. This round was judgment. *Question:* build the counter (rung 3), or accept a
  prune by hand each quarter?
- **A decision can be contradicted for two weeks before anything notices.** The 2026-08-28 decision
  keeps a model *alias* in `settings.json` rather than a pinned id; `883425e` pinned
  `claude-fable-5[1m]` three days later, and by the time it was caught (2026-09-17) Fable 5.1 had
  shipped, so the default had been pointing at the previous generation. Nothing detects this class
  except a `/document` run reading `decisions.md` against the code. The mechanism is *this
  document*, on demand, and nothing faster.
- **`claude/CLAUDE.md` carries vendored third-party content.** The Penpot AI kit block is
  installer-generated and rewritten in place through the symlink, so `git diff` on that file can
  show changes nobody here wrote. Committed on purpose.

**Docs inventory — does each doc earn its place?**
- `learning-loop-spec.md` → **keep** (complementary). It holds the reasoning the operational
  contract does not: the three axes, the enforcement ladder and what it costs, the mechanical
  defect source, the routing matrix, the risks to validate, the out-of-scope list. `retro.md` §7 is
  authoritative for behaviour. The overlap is real and the open option — pruning the spec to
  reasoning + risks only — stays deferred until it actually misleads someone.
- `architecture.md`, `reference.md`, `test-protocol.md` → owned and regenerated by `/document`.
  The protocol is the only one a reader is expected to *act* on, and the only one whose content
  changes without the code changing.
- No redundant or orphaned docs. The set is sharp.

> **Since the 2026-09-17 generation:** every drift item then open is now closed — the stray
> commands, the `delegate.yaml` divergence and the `document.md` contradiction. Nothing regressed.
> Of the nine debt items, **two were created by this week's own additions** — the briefing contract
> and the extractor — and both are the same shape: a mechanism shipped with a claim about its
> effect that nothing has yet measured. A third, `delegate.sh`'s exit code, is an old defect merely
> written down for the first time. The rest predate this week.

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

### claude/commands/ (12)
Explicit, user-invoked. **Twelve**: 18 → 11 on 2026-09-18 (six deleted as natively covered,
`/git-pr` folded into `/git-commit`), then **`/audit` restored on 2026-09-30**. The load-bearing ones:
- **`scope.md`** — the entry point: what, why, and success criteria as a machine-readable checklist.
  Sizes itself (micro / small / medium / large) so a bug fix does not get a ten-page treatment.
- **`decompose.md`** — turns a scope into **vertical slices**: a thin sequential foundation first
  (only what two or more slices share), then slices that each end in something observable, sized by
  counting data movements across the task boundary. Rewritten 2026-09-17 from a layer-based
  decomposition, because a layer has no observable outcome and therefore no criterion `builder` can
  verify. §6 carries the worktree precondition.
- **`delegate.md`** + `delegate-on/off/status.md` — hand a bounded task to a cheaper backend; Claude
  decomposes and reviews the diff. `--task` routes to one of five specialized backends.
  `delegate-status` shows the active backend **and** the centralized cost/token dashboard.
  The decompose step now requires the **briefing contract**: check command, reference files, and
  the rules no linter can express.
- **`audit.md`** — restored 2026-09-30, 68 lines where the deleted one had 98. Reviews **state**
  (a file, a module, a component) on the three axes native `/code-review` does not carry: security,
  homogeneity, maintainability. `/code-review` reviews a **change** for correctness and cleanup, and
  this command says so and defers rather than competing. It requires every finding to name a file
  and a line and to declare whether it was **reproduced** or **inferred**, and it tells the reader
  to read `CLAUDE.md` and `.claude/context/` — half the real findings of the September routing tests
  were contradictions between code and the project's own docs. For depth on security it names
  `/security-review` and states plainly that the skill will not load itself.
- **`retro.md`** — end-of-session retrospective: rewrites `status.md`, appends `anti-patterns.md`/
  `decisions.md`, applies `CLAUDE.md`/`README.md`. §7 runs the **learning loop**, which since
  2026-09-17 starts with a *mechanical* read of session defects (`extract-defects.py`) before the
  subjective pass, and picks the **form** of a rule down a four-rung enforcement ladder before
  picking its destination. §8 flags doc staleness on **both** channels — the commit diff since the
  `generated_from_commit` stamp, and `git status --porcelain` for work never committed.
- **`document.md`** — this command: regenerates `architecture.md` + `reference.md` on demand, plus
  `test-protocol.md` **when the project has verification paths a test suite cannot cover** (this one
  does — it has no test suite at all). The first two are descriptive and terminal; the protocol is
  prescriptive and cyclical, self-contained by contract, and closes its own loop by re-reading its
  previous version and the traces its steps declare. `/retro` is not involved.
- **`git-commit.md`** — conventional commits, and since 2026-09-18 the pull request too
  (`/git-commit pr`), absorbed from the deleted `/git-pr`: refuses on `main`, warns on secrets in
  the diff, supports `draft` and an alternate base.
- **`bootstrap.md`**, **`explore.md`** — project context scaffolding, and tagged exploration. Kept
  deliberately: `bootstrap` does more than the native `/init` (it scaffolds `.claude/context/`), and
  its `## Conventions` section now produces the briefing contract's three items instead of a
  placeholder.

### claude/skills/ (7)
`agent-builder`, `creative-direction`, `data-engineering`, `infra-containers`, `provider-keys`,
`safe-penpot-writes`, `security-review`. All seven symlinked and verified 2026-09-30 (repo,
installed tree and manifest agree).

**Treat a skill as a library, not as something that arrives.** The September reasoning was
"a command has to be remembered, a skill fires on the words already being typed" — **measured false
on this machine.** Four valid routing tests failed with trigger words present verbatim, and the
lifetime counters explain why in one line: across 431 startups, every skill with real usage is one
typed as `/name`, while the ones only a model could reach sit at zero. So the skills stay, as depth
an invocable command points at — `/audit` names `security-review` explicitly and says plainly that
it will not load itself.

**Two are scoped rather than broad** (2026-09-30). `infra-containers` carries a `paths` glob
(`**/Dockerfile*`, `**/docker-compose*.y*ml`, `**/k8s/**`, `**/*.service`) so it activates only on
those file types. `data-engineering` could **not** be scoped that way — pipeline code is ordinary
Python under any layout, and a glob would have silenced it rather than sharpened it — so its
description was narrowed instead, to the one failure it genuinely knows: a step that is not safe to
replay. Descriptions shrank 512→355 and 502→278 characters, which also buys listing budget.

**`delegate` was folded into its command** the same day. It existed only for relevance-triggering;
its 150-line body — task routing, usage tracking, the briefing contract, the scope-lock rule —
moved into `/delegate` (the 45-line command it duplicated), and the directory was archived to
`~/.claude/skills-retirees-20260930/`.

Three carry more than guidance:

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
- ⚠ **debt:** exercised 2026-09-18 (ten spawns, worktrees created/merged/cleaned), but the
  `maxTurns: 40` resumption claim is still unobserved, and the report contract was not checked
  heading by heading. See the drift summary.

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
- **`extract-defects.py`** — `extract-defects.py [PATH ...] [--project PATH] [--days N]`.
  Read-only; it never writes. Reads Claude Code session transcripts (`~/.claude/projects/<slug>/
  *.jsonl`, the slug being the project's absolute path with `/` → `-`) plus the delegation log, and
  reports three defect signals: **failed subagent spawns**, **tasks respawned more than once**
  (grouped by a task id such as `T0.2a` when present, else the first three words), and
  **delegations that exited non-zero**. Positional paths bypass `--project`/`--days`. Exit 1 only on
  a missing positional path; otherwise always 0, so it is safe as a `/retro` step. Feeds `/retro`
  §7 step 1. ⚠ **debt:** it is a net, not a blanket — see the summary.
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
