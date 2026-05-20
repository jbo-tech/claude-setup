# Audit Phase 0 — Baseline

> Branche : `audit-restructure`
> Date : 2026-05-19
> Approximation token : `≈ chars / 4`

## 1. Baseline tokens

### Skills (`claude/skills/`)
| Fichier | Lignes | Chars | ~Tokens |
|---|---:|---:|---:|
| skill-factory | 134 | 4 064 | ~1 016 |
| infra-containers | 93 | 3 457 | ~864 |
| agent-builder | 91 | 2 702 | ~675 |
| security-review | 76 | 2 601 | ~650 |
| creative-direction | 76 | 2 538 | ~634 |
| karpathy-guidelines | 67 | 2 629 | ~657 |
| ml-review | 67 | 2 361 | ~590 |
| data-engineering | 65 | 2 153 | ~538 |
| **Total skills** | **669** | **22 505** | **~5 624** |

### Commands (`claude/commands/`)
| Fichier | Lignes | Chars | ~Tokens |
|---|---:|---:|---:|
| bootstrap | 206 | 5 457 | ~1 364 |
| scope | 162 | 3 676 | ~919 |
| worktree-merge | 160 | 3 418 | ~854 |
| decompose | 140 | 2 838 | ~709 |
| worktree-setup | 137 | 2 955 | ~738 |
| retro | 121 | 2 795 | ~698 |
| decompose-run | 117 | 3 917 | ~979 |
| git-pr | 114 | 2 452 | ~613 |
| git-commit | 99 | 2 288 | ~572 |
| tdd-loop | 90 | 2 812 | ~703 |
| audit | 68 | 1 587 | ~396 |
| explore | 55 | 1 648 | ~412 |
| **Total commands** | **1 469** | **35 843** | **~8 957** |

### Agents (`claude/agents/`)
| Fichier | Lignes | Chars | ~Tokens |
|---|---:|---:|---:|
| creative-director | 265 | 8 784 | ~2 196 |
| infra-expert | 184 | 5 472 | ~1 368 |
| data-ml-expert | 148 | 4 520 | ~1 130 |
| **Total agents** | **597** | **18 776** | **~4 694** |

### Total repo
**~19 275 tokens** sur 86 702 chars / 3 136 lignes de markdown.

### Coût "par défaut" (toujours en contexte)
Seuls les `description:` frontmatter sont auto-chargés ; les bodies sont **on-demand**. Donc le coût permanent du repo est **les descriptions** (≈ 50-80 tokens/skill + 50-80/agent + 0/command), soit **~600 tokens par défaut** — pas les ~19 275 mesurés. La friction principale n'est pas le poids du repo mais la **pollution du namespace de slash-commands** et la **densité de descriptions** qui rendent les bons choix moins visibles.

---

## 2. Usage réel (60 derniers jours, tous projets confondus)

Source : grep des `.jsonl` dans `~/.claude/projects/`.

### Commandes perso
| Commande | Invocations | Verdict initial |
|---|---:|---|
| `/retro` | 29 | **Pilier** — garde |
| `/git-commit` | 9 | **Utile** — garde |
| `/scope` | 6 | Garde, à clarifier vs `/goal` |
| `/bootstrap` | 5 | Garde |
| `/explore` | 3 | Garde |
| `/audit` | 0 | **Oublié, à réveiller** (cf. §3) |
| `/decompose` | 0 | Candidat retrait |
| `/decompose-run` | 0 | Candidat retrait |
| `/tdd-loop` | 0 | Candidat retrait (superpowers:test-driven-development couvre) |
| `/worktree-setup` | 0 | Candidat retrait (superpowers:using-git-worktrees couvre) |
| `/worktree-merge` | 0 | Candidat retrait |
| `/git-pr` | 0 | Candidat retrait |

### Agents perso
| Agent | Invocations |
|---|---:|
| `creative-director` | 7 |
| `infra-expert` | 3 |
| `data-ml-expert` | **0** |

### Skills perso (invocations explicites seulement — l'auto-trigger n'est pas tracké)
| Skill | Invocations explicites |
|---|---:|
| `data-engineering` | 1 |
| Tous les autres | 0 |

**Lecture** : l'absence d'invocation explicite ne signifie pas "non utilisé" (les skills s'auto-déclenchent sur trigger words). Mais combinée à l'absence d'agent invoquant ces skills, le signal "data-ml-expert + ml-review + data-engineering" est faible.

### Commandes publiques fréquemment utilisées (à conserver dans le mental model)
| Commande publique | Invocations | Origine probable |
|---|---:|---|
| `/brainstorm` | 7 | `superpowers:brainstorming` |
| `/debrief` | 4 | (à identifier) |
| `/done` | 2 | `superpowers:finishing-a-development-branch` |
| `/init` | 2 | Claude Code natif |
| `/effort` | 2 | Natif |
| `/simplify` | 1 | `code-simplifier` plugin |
| `/find-skills` | 1 | `find-skills` skill |
| `/goal` | 1 | Natif (récent) |

---

## 3. Verdict `/audit` existant

**État** : commande générique de code review (68 lignes, ~396 tokens). Couvre Readability / Robustness / Maintainability / Performance / Surgical check.

**Vs les 3 axes demandés** :
- **Optimisation** : couverte *superficiellement* par la section Performance (2 questions seulement).
- **Sécurité** : **non couverte** explicitement. Skill `security-review` existe mais `/audit` ne le route pas.
- **Homogénéité** : couverte indirectement via Readability + Surgical check ("Matches existing code style"), pas en axe nommé.

**Verdict** : **à enrichir, pas à refondre**. Ajouter :
1. Un axe **Sécurité** explicite + routage vers `@security-review` ou skill équivalent.
2. Un axe **Optimisation** plus charnu (DB, I/O, allocations, complexité algorithmique).
3. Un axe **Homogénéité** nommé (style, conventions, patterns du repo).
4. Garder le pattern de routage existant (`@data-ml-expert`, `@infra-expert`).

**Cause racine de l'oubli** : la commande est noyée parmi 12. Solution structurelle = réduction du nombre de commandes (cf. §2).

---

## 4. Recouvrements avec l'écosystème public

### Plugins installés et actifs
- `superpowers` v5.1.0 (skills TDD, debugging, plans, brainstorming, worktrees, etc.)
- `data-engineering` v0.1.0 (**collision directe** avec mon skill local)
- `code-simplifier` v1.0.0
- `remember` v0.7.2
- `frontend-design`, `ai-firstify`, `ui-ux-pro-max`, `github`
- Plus une longue liste de skills via marketplace `anthropic-agent-skills` (vercel-*, astronomer-data, taste-design…)

### Mes 8 skills vs public
| Skill perso | Couverture publique | Recommandation |
|---|---|---|
| **skill-factory** | `superpowers:writing-skills` (couvre méta-skill) | **Délègue** (mais vérifier le scope exact) |
| **agent-builder** | Pas d'équivalent direct dans superpowers (`writing-skills` ≠ agent) | **Garde** |
| **data-engineering** | Plugin `data-engineering` officiel installé + `astronomer-data:*` (très riche) | **Délègue ou spécialise sur ma stack** (Kestra, DuckDB, MinIO, ZimaBoard) |
| **infra-containers** | Pas d'équivalent direct (les `vercel-*` ne couvrent pas containers) | **Garde et spécialise** (homelab, Podman, ZimaBoard) |
| **security-review** | Skill public `security-review` existe (même nom — origine à confirmer) | **Délègue ou justifier la divergence** |
| **karpathy-guidelines** | `superpowers:verification-before-completion` + CLAUDE.md (déjà rédigée dans cet esprit) | **Délègue ou retire** (CLAUDE.md suffit probablement) |
| **ml-review** | Pas d'équivalent direct dans les plugins installés | **Garde** |
| **creative-direction** | Pas d'équivalent — spécifique | **Garde** (pilier, lié à `creative-director` agent) |

### Mes 3 agents vs public
| Agent | Verdict |
|---|---|
| **creative-director** | 7 invocations / 60j → **Pilier**. Garde. |
| **infra-expert** | 3 invocations / 60j → Garde, peut-être à fusionner avec skill `infra-containers` |
| **data-ml-expert** | 0 invocation / 60j → **Candidat retrait**. Ses 1 130 tokens ne sont pas justifiés. |

### Mes 12 commandes vs public
| Commande perso | Couverture publique | Recommandation |
|---|---|---|
| `/retro` (29 use) | `remember:remember` proche mais différent | **Pilier** |
| `/git-commit` (9) | Natif `git commit` + `/done` | Garde (workflow personnel) |
| `/scope` (6) | `superpowers:writing-plans` proche | Garde, **câbler vers `/goal`** |
| `/bootstrap` (5) | `/init` natif proche mais différent | Garde |
| `/explore` (3) | `superpowers:brainstorming` (mode différent) | Garde, distinguer "explore" (questions) vs "brainstorm" (idéation) |
| `/audit` (0) | — | **Enrichir** (cf. §3) |
| `/decompose` (0) | `superpowers:writing-plans` + `dispatching-parallel-agents` | **Retire** (couvert + non utilisé) |
| `/decompose-run` (0) | `superpowers:subagent-driven-development` | **Retire** |
| `/tdd-loop` (0) | `superpowers:test-driven-development` | **Retire** (couvert + non utilisé) |
| `/worktree-setup` (0) | `superpowers:using-git-worktrees` | **Retire** |
| `/worktree-merge` (0) | `superpowers:finishing-a-development-branch` | **Retire** |
| `/git-pr` (0) | Natif `gh pr create` + `/done` | **Retire** |

---

## 5. Bonus : packaging multi-tool (étude format plugin)

Le plugin `superpowers` (référence cible) embarque **plusieurs manifests** :
```
.claude-plugin/plugin.json     ← Claude Code
.codex-plugin/plugin.json      ← OpenAI Codex
.cursor-plugin/                ← Cursor
.opencode/                     ← opencode
```

Donc le pattern multi-tool n'est pas théorique : il existe et marche. Pour `claude-setup` :
- Source de vérité = `claude/{skills,commands,agents}/` (markdown portable, déjà le cas).
- Ajouter un `.claude-plugin/plugin.json` à terme = direct.
- L'installeur reste valide en parallèle (compatible Claude Code sans passer par le marketplace).

---

## 6. Synthèse & recommandation Phase 1

### Ce qu'on a appris
1. **Le coût "par défaut" est exagéré dans nos craintes** — ce sont les descriptions (~600 tokens) qui pèsent, pas les bodies. Le vrai problème est **la pollution du namespace de commandes** et la **densité de skills publics** qui noient les choix utiles.
2. **5 commandes sur 12 ont 0 usage en 60 jours** (decompose, decompose-run, tdd-loop, worktree-setup, worktree-merge, git-pr). Toutes ont un équivalent public maintenu — décision facile.
3. **1 agent sur 3 a 0 usage** (data-ml-expert). Décision facile.
4. **`/audit` n'est pas mauvais** — il est *oublié*. Le réveiller via enrichissement (sécurité, optimisation, homogénéité) + réduction du nombre de commandes le rendra visible.
5. **Le pattern multi-tool est viable** via plusieurs manifests dans un même repo (superpowers le fait déjà).
6. **`karpathy-guidelines` est largement redondant avec ma CLAUDE.md** — la CLAUDE.md est *déjà* rédigée dans cet esprit ("Simplicity first", "Surgical changes"…). Candidat retrait.

### Grille de décision Phase 1 (proposition)

**Skills — passer de 8 → 4**
- **Garde** : `agent-builder`, `creative-direction`, `infra-containers` (spécialisé homelab), `ml-review`
- **Spécialise** : `data-engineering` → recentré sur ma stack (Kestra/DuckDB/MinIO/ZimaBoard) OU délègue au plugin officiel
- **Délègue** : `skill-factory` (→ `superpowers:writing-skills`), `security-review` (→ public homonyme à confirmer), `karpathy-guidelines` (→ CLAUDE.md + `superpowers:verification-before-completion`)

**Agents — passer de 3 → 2**
- **Garde** : `creative-director`, `infra-expert`
- **Retire** : `data-ml-expert` (0 usage)

**Commands — passer de 12 → 6**
- **Garde** : `/retro`, `/git-commit`, `/scope`, `/bootstrap`, `/explore`, `/audit` (enrichi)
- **Retire** : `/decompose`, `/decompose-run`, `/tdd-loop`, `/worktree-setup`, `/worktree-merge`, `/git-pr`

**Impact estimé** :
- Tokens repo : ~19 275 → ~9 500 (-50 %)
- Slash-commands perso visibles : 12 → 6 (-50 %), les bons remontent
- Surface de maintenance : -50 %

### Tâches Phase 1 (à créer après validation)
1. Enrichir `/audit` (axes sécurité + optimisation + homogénéité).
2. Câbler `/scope` vers `/goal` (artefact + condition de complétion lue depuis success criteria).
3. Retirer les 6 commandes non utilisées (git rm + grep cross-references).
4. Retirer `data-ml-expert` agent + mettre à jour les routages dans `/audit`.
5. Décider skill par skill (4 retraits / 1 spécialisation) — un PR par décision pour traçabilité.
6. Mettre à jour CLAUDE.md / README pour documenter la philosophie de complémentarité publique.

### Tâches Phase 2+
- Phase 2 : installeur `install.sh` (idempotent, journalisé).
- Phase 3 : étude format plugin Claude Code (`.claude-plugin/plugin.json`) — préparer la migration sans la livrer.

---

## Open questions pour validation utilisateur

1. **`karpathy-guidelines`** : retire complètement, ou je garde une version réduite spécifique (les éléments absents de la CLAUDE.md) ?
2. **`data-engineering`** : délègue au plugin public, ou je spécialise sur ma stack (homelab) ?
3. **`security-review`** : à confirmer — est-ce que le skill public homonyme est *exactement* le même contenu que le mien (à vérifier en diffant) ?
4. **6 commandes à retirer** : je supprime sec, ou je les déplace dans un dossier `archive/` avec un README expliquant pourquoi ?
5. **`/audit` enrichi** : tu préfères une seule commande étoffée, ou je découpe en `/audit`, `/audit-security`, `/audit-perf` ? (Recommandation : une seule, avec sections claires.)
