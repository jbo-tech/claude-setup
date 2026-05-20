## Audit & restructuration du repo claude-setup

### Vision
Faire de `claude-setup` un setup Claude Code **maîtrisé, léger, auditable et partageable**. Le différentiateur n'est pas la quantité de skills/agents, mais l'enchaînement de workflows (plan → exécution autonome → retro) et la complémentarité — qui doit émerger naturellement — entre une stack personnelle resserrée et l'écosystème public.

### Problème
Le repo actuel a poussé organiquement et accumule de la friction :
- **Redondance** entre agents (`data-ml-expert`, `infra-expert`) et skills (`data-engineering`, `ml-review`, `infra-containers`, `security-review`) sans rôle clair.
- **Token budget non maîtrisé** : 8 skills (~669 lignes), 3 agents (~597 lignes), 12 commandes (~1469 lignes) — auquel s'ajoute un écosystème public chargé en parallèle (superpowers, astronomer-data, vercel, ui-ux-pro-max…).
- **Pas d'orchestration plan → exécution autonome**. `/scope` produit un plan mais rien ne le porte ensuite vers `/goal` natif. `/decompose-run` et `/tdd-loop` sont peu utilisés.
- **Audit code pas exploitable** pour les trois usages cités (optimisation, sécurité, homogénéité) — `/audit` existe mais à vérifier qu'il couvre ces axes.
- **Installation manuelle** (`cp -r`) non reproductible, et incompatible avec une cible multi-tool (Codex, opencode).

### User
- **JB** (toi), utilisateur unique en production. Veut **monter en compétence sur le workflow d'agent** — donc les artefacts doivent être pédagogiques.
- **Visiteurs GitHub** qui clonent. Surface publique : crédibilité du repo dépend de la cohérence et de la facilité d'install.

### Success criteria
- [ ] Inventaire scoré (skills + commandes + agents) avec décision documentée (garde / spécialise / délègue / retire).
- [ ] Réduction mesurable du token budget par défaut (objectif indicatif : −30 % sur les skills auto-chargés).
- [ ] Workflow `/scope → /goal` opérationnel et documenté, avec artefact persistant lisible a posteriori.
- [ ] Commande d'audit code utilisable sur les 3 axes : optimisation, sécurité, homogénéité.
- [ ] Installation en **une commande** sur une machine neuve (Claude Code minimum).
- [ ] Document explicatif "comment ce setup se compose avec l'écosystème public" (quoi garder du public, pourquoi).
- [ ] Compréhension écrite du format plugin Claude Code officiel (pas forcément la migration, mais le mode d'emploi).

### Scope
**In** :
- Audit complet de `claude/skills/`, `claude/agents/`, `claude/commands/`.
- Mesure objective des tokens et des recouvrements avec skills publics.
- Restructuration : suppressions, fusions, spécialisations.
- Création/réécriture de la commande d'audit code (optimisation / sécurité / homogénéité).
- Câblage `/scope` → `/goal` (artefact + transition).
- Installeur (script `install.sh`) idempotent, avec option de cible.
- Documentation README à jour : nouvelle structure, philosophie de complémentarité avec le public.
- Étude (lecture) du format plugin Claude Code via un exemple existant (ex. `superpowers`).

**Out** :
- Migration effective au format plugin Claude Code (étudié, pas livré dans cette itération).
- Support complet Codex / opencode (préparer le terrain via markdown portables, pas les adaptateurs).
- Création de nouveaux agents au-delà du strict nécessaire (le défaut est de *réduire*, pas d'ajouter).
- Refonte des skills publics tiers (on les utilise tels quels ou on les laisse).

### Constraints
- **Temps** : pas de deadline externe, mais session resserrée — pas de yak-shaving.
- **Tech** : markdown + frontmatter comme source de vérité (portable). Pas de dépendance lourde dans l'installeur (bash, max).
- **Token budget** : tout ajout doit justifier son coût ; un skill auto-chargé doit avoir une `description:` chirurgicale.
- **Maîtrise** : préférence pour comprendre/réécrire un skill plutôt que dépendre d'un public non maintrisé. Le public n'est gardé que si valeur claire et risque acceptable.

### Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Supprimer un skill/agent qui est en réalité chargé passivement par une commande | Régression silencieuse | Grep cross-référence avant suppression ; phase de test sur 2-3 sessions |
| Trop déléguer au public → perte de maîtrise quand un skill public change | Comportement instable | Inventaire des dépendances publiques + décision explicite "je m'engage à suivre / je clone localement" |
| Format plugin Claude Code immature → choix prématuré | Refonte forcée plus tard | Étudier sans migrer ; livrer un installeur compatible aujourd'hui *et* compatible plugin demain |
| `/audit` actuel jugé insuffisant alors qu'il suffisait | Travail redondant | Phase 0 : test du `/audit` existant sur un cas concret avant d'écrire quoi que ce soit |
| Restructuration en place sur `master` → si bug, plus de setup utilisable | Friction quotidienne | Travailler en branche ; `worktree` ou copie locale `~/.claude/` snapshot avant install |

### Architecture

#### Overview
Trois couches isolées : (1) **source de vérité** en markdown portable dans le repo, (2) **installeur** qui pose les fichiers à la bonne destination selon la cible, (3) **doc de composition** qui explique quoi prendre du public et pourquoi. Le format plugin Claude Code est étudié comme évolution possible, pas comme livrable de cette itération.

#### Key decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Source de vérité | Markdown + frontmatter dans `claude/` | Portable, lisible, versionné, agnostique de l'outil |
| Mode d'install par défaut | Installeur `install.sh` idempotent | Pragmatique, marche aujourd'hui, n'exclut pas un plugin demain |
| Skills à conserver | Critère 4 colonnes (usage / artefact / couverture publique / token cost) | Décision documentée, pas arbitraire |
| Agents | Réduire à ce qui produit *vraiment* du contexte isolé utile | Skills + commandes couvrent souvent le besoin sans contexte dédié |
| Plan → exécution | `/scope` produit l'artefact, `/goal` natif l'exécute | Compose avec le natif, n'invente pas un orchestrateur maison |
| Complémentarité avec le public | Émerge de l'audit, n'est pas posée a priori | "Suggérer si pertinent" — pas de doctrine forcée |
| Multi-tool | Préparer (markdown portable), pas livrer | Évite la sur-ingénierie immédiate |

#### Components
- **Audit grid** (`.claude/context/audit.md`) : tableau scoré skills + commandes + agents, avec décision par ligne.
- **Installeur** (`install.sh` à la racine) : pose `claude/*` vers `~/.claude/`, idempotent, journalise les écrasements.
- **Commande d'audit code** : soit refonte de `/audit` existant, soit nouvelle commande spécialisée par axe — décision en phase d'audit après test du `/audit` actuel.
- **Workflow `/scope → /goal`** : `scope.md` (ce fichier) devient l'artefact dont `/goal` lit la condition de complétion ; éventuellement une convention "Success criteria → goal".
- **README + doc complémentarité** : qui fait quoi entre `claude-setup` et l'écosystème public.

#### Data flow
```
repo (markdown portable)
        │
        ├─→ install.sh ──→ ~/.claude/{commands,agents,skills}/
        │
        └─→ doc README ──→ utilisateur GitHub
```

### Open questions
- **`/audit` actuel suffit-il** pour optimisation / sécurité / homogénéité ? À tester avant de réécrire. *Candidat `/explore [technical]` si verdict ambigu.*
- **Quelle mesure objective des tokens** ? Lignes ≠ tokens. Approximation acceptable ou tokenizer réel ?
- **`/goal` natif lit-il un fichier d'objectif** ou attend-il une condition inline ? À vérifier dans la doc Claude Code pour câbler proprement le passage de relais depuis `/scope`.
- **Quels skills publics sont chargés *passivement* dans toutes mes sessions** (et coûtent du token "à vide") ? À distinguer de ceux invoqués explicitement.
- **Format plugin Claude Code** : namespace = nom du dossier ? Manifeste obligatoire ? Cohabite-t-il avec un install manuel pour le même setup ?

### Phasage proposé (post-scope)
1. **Phase 0 — Baseline** : mesurer tokens, lister usages réels via `.remember/`, tester `/audit` sur cas concret.
2. **Phase 1 — Audit grid** : remplir le tableau scoré, décider ligne par ligne.
3. **Phase 2 — Restructure** : supprimer, fusionner, spécialiser. En branche, pas sur master.
4. **Phase 3 — Commande audit code** : refonte ou création selon verdict phase 0.
5. **Phase 4 — Workflow plan → goal** : câblage et doc.
6. **Phase 5 — Installeur + README** : packaging pragmatique, doc complémentarité publique.
7. **Phase 6 — Étude plugin Claude Code** : compréhension écrite, pas migration.
