# Phase 1 — Plan de restructuration (consolidé)

> Branche : `audit-restructure`
> Précédé par : `.claude/context/audit.md` (Phase 0 baseline)
> Objectif : passer de 8 skills / 3 agents / 12 commandes à **5 skills / 2 agents / 7 commandes** (dont une famille `/audit-*`), sans perte de capacité.

## Décisions validées

### Skills : 8 → 5
| Skill | Décision | Raison |
|---|---|---|
| `creative-direction` | **Garde** | Pilier, lié à `creative-director` agent (7 inv/60j) |
| `agent-builder` | **Garde** | Pas d'équivalent public direct |
| `infra-containers` | **Garde + spécialise (open source)** | Recentrer sur Podman, Kestra, Docker Compose, K3s, MinIO — outils open. Les outils commerciaux (cloud-spécifiques) sont couverts par skills communautaires. |
| `data-engineering` | **Garde + spécialise (open source)** | Le plugin public `data-engineering` = `astronomer-data` (Airflow-only) → pas de collision. Recentrer sur DuckDB, parquet, Kestra, MinIO, ETL/ELT open. |
| `security-review` | **Garde** | Pas de skill public homonyme dans les plugins installés. |
| `ml-review` | **Retire (contenu → `/audit-ml`)** | Transformation skill → commande pour discoverabilité + invocation explicite. |
| `karpathy-guidelines` | **Retire** | Redondant avec CLAUDE.md (mêmes 4 sections). Diff avant suppression pour récupérer tout exemple absent. |
| `skill-factory` | **Retire** | `superpowers:writing-skills` couvre. |

### Agents : 3 → 2
| Agent | Décision | Raison |
|---|---|---|
| `creative-director` | **Garde** | 7 invocations / 60j |
| `infra-expert` | **Garde** | 3 invocations / 60j |
| `data-ml-expert` | **Retire** | 0 invocation / 60j (1 130 tokens) |

### Commandes : 12 → 7 (famille `/audit-*` incluse)
| Commande | Décision | Raison |
|---|---|---|
| `/retro` | **Garde** | 29 inv — pilier |
| `/git-commit` | **Garde** | 9 inv — workflow personnel |
| `/scope` | **Garde + câbler vers `/goal`** | 6 inv — différencié vs `superpowers:writing-plans` |
| `/bootstrap` | **Garde** | 5 inv |
| `/explore` | **Garde** | 3 inv — distinct de `superpowers:brainstorming` |
| `/audit` | **Garde + enrichir** | 0 inv (oublié) — refonte pour absorber sécurité (incl. secrets), optimisation, homogénéité (incl. design-system) |
| `/audit-ml` | **Nouveau** | Issu du contenu de `ml-review`, transformé en commande explicite |
| `/audit-accessibility` | **Nouveau** | Couvre WCAG / ARIA / RGAA. À écrire from scratch (pas de skill source) |
| `/decompose` | **Retire (sec)** | 0 inv ; pattern multi-worktree non utilisé. Si besoin, réémergence depuis git history. |
| `/decompose-run` | **Retire (sec)** | 0 inv ; même raison |
| `/tdd-loop` | **Retire (sec)** | `superpowers:test-driven-development` couvre intégralement |
| `/worktree-setup` | **Retire (sec)** | 0 inv ; pattern multi-worktree non utilisé |
| `/worktree-merge` | **Retire (sec)** | 0 inv ; idem |
| `/git-pr` | **Retire (sec) — secrets → axe sécurité de `/audit`** | `gh pr create` + `superpowers:finishing-a-development-branch` couvrent. La détection de secrets devient un point explicite de l'axe sécurité de `/audit`. |

**Note sur `/audit-design-system`** : pas de commande dédiée. Le design-system est intégré comme **axe interne de `/audit`** sous "homogeneity". Si le besoin se densifie, on extraira en commande séparée Phase 2+.

## Impact estimé

| Métrique | Avant | Après | Δ |
|---|---:|---:|---:|
| Skills | 8 | 5 | −38 % |
| Agents | 3 | 2 | −33 % |
| Commandes perso | 12 | 7 | −42 % |
| Tokens repo (approx.) | ~19 275 | ~11 000 | −43 % |
| Descriptions auto-chargées | ~610 tok | ~440 tok | −28 % |

## Tâches Phase 1 (3 commits groupés)

### Commit 1 — Foundation : baseline + /audit family + /scope→/goal
1. Figer baseline Phase 0 sur la branche (audit.md, phase1-plan.md, scope.md).
2. Enrichir `/audit` :
   - Axe **Sécurité** : injection, OWASP, secrets (.env, credentials, tokens dans commits) — récupère la logique de `/git-pr`.
   - Axe **Optimisation** étoffé : DB, I/O, allocations, complexité algorithmique.
   - Axe **Homogénéité** nommé : style, conventions, design-system (tokens, composants, naming).
   - Garder routage vers `@infra-expert` ; retirer `@data-ml-expert` (sera supprimé commit 2).
3. Créer `/audit-ml` : transformer le contenu de `ml-review` en commande (data leakage, train/test split, validation, etc.).
4. Créer `/audit-accessibility` : nouveau, WCAG 2.x + ARIA + mention RGAA.
5. Câbler `/scope` → `/goal` : ajouter une section "Goal condition" lisible par `/goal` natif + pointer en fin de `/scope`.

### Commit 2 — Removals : 6 commandes + 3 skills + 1 agent
1. **Pré-condition** : diff `karpathy-guidelines` vs `CLAUDE.md`, ajouter à CLAUDE.md tout exemple manquant utile.
2. `git rm` commandes : `decompose`, `decompose-run`, `tdd-loop`, `worktree-setup`, `worktree-merge`, `git-pr`.
3. `git rm` skills : `karpathy-guidelines`, `skill-factory`, `ml-review`.
4. `git rm` agent : `data-ml-expert` + nettoyer toute référence dans `/audit` ou ailleurs.

### Commit 3 — Specialization + docs
1. Spécialiser `data-engineering` sur open source (DuckDB, parquet, Kestra, MinIO, ETL/ELT générique). Update description frontmatter + exemples.
2. Spécialiser `infra-containers` sur open source (Podman, Kestra, Docker Compose, K3s, MinIO). Idem.
3. README + CLAUDE.md : documenter la philosophie de complémentarité avec le public (« voici ce qui est local et pourquoi, voici ce qu'on délègue »).
