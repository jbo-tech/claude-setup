# Learning Loop — Specification

> Boucle de capitalisation des apprentissages. Ferme le circuit
> `session → observation → promotion par portée+confiance → application`,
> avec purge symétrique pour éviter la dérive du contexte.
>
> Statut : **implémenté** depuis le 2026-06-04. Le contrat opérationnel vit dans
> `claude/commands/retro.md` §7 — c'est lui qui fait foi. Ce document conserve ce que le
> contrat ne porte pas : le raisonnement derrière les trois axes, la matrice de routage
> détaillée, les risques à valider empiriquement et le hors-scope.
> Curseur retenu : **conservateur**.

## 1. Objectif

Transformer les apprentissages d'une session en règles durables **au bon niveau**,
sans polluer le contexte. Le système n'a de valeur que s'il **élague autant qu'il ajoute**.

Principe directeur : une mémoire vue 3× n'est plus une note, c'est une règle —
mais seulement si elle est promue **là où elle s'applique** et **tant qu'elle reste vraie**.

## 2. État actuel (ce qui existe, ce qui manque)

`/retro` (`claude/commands/retro.md`) capture déjà en fin de session :

| Sortie | Mode | Portée |
|---|---|---|
| `.claude/context/status.md` | replace | projet |
| `.claude/context/anti-patterns.md` | append-only | projet |
| `.claude/context/decisions.md` | append-only | projet |
| `CLAUDE.md` | apply direct | projet (implicite) |
| `README.md` | apply direct | projet |

Le système `memory/` (`~/.claude/projects/<proj>/memory/` + `MEMORY.md` index) existe en
parallèle, avec un champ `type: user | feedback | project | reference` qui **encode déjà la portée**.

**Les 5 trous à combler :**

1. **Deux systèmes cloisonnés** — `/retro` écrit `.claude/context/*`, jamais `memory/`. Ils s'ignorent.
2. **Aucune détection de récurrence** — tout est `append`. `anti-patterns.md` ne fait que grossir.
3. **Aucun routage par portée** — tout atterrit en projet-local. Rien ne distingue cross-projet de projet-spécifique.
4. **Aucune purge** — règle explicite « never delete ». L'inverse de l'élagage.
5. **Critère de confiance flou** — « reusable learnings » est subjectif, pas la règle *explicite OU récurrence≥3*.

## 3. Le modèle — 3 axes orthogonaux

Une observation n'est pas qualifiée par un seul critère. Trois axes indépendants :

### Axe 1 — Confiance : *faut-il promouvoir ?*

Promotion déclenchée si **l'un** des éléments suivants est vrai :

- **Directive explicite** — l'utilisateur a dit « toujours / jamais / à partir de maintenant ».
  → **1 seule fois suffit**, pas d'attente.
- **Récurrence ≥ 3** — la même observation a été enregistrée 3 fois ou plus (voir §5, comptage).
- **Coût d'erreur élevé** — l'observation a évité (ou décrit) une faute coûteuse.
  → accélère la promotion, mais reste soumise à validation (curseur conservateur).

Sinon : l'observation reste en **staging** (§5), elle n'est pas promue.

### Axe 2 — Portée : *où ça s'applique ?* (le routage)

- **Cross-projet** — façon de travailler, indépendante de la stack.
- **Projet** — quirk, convention, contrainte propre à un repo.
- **Tech / pattern transférable** — récurrent sur plusieurs projets autour d'une même techno.

La portée se déduit en priorité du `type:` quand l'observation vient déjà de `memory/` ;
sinon elle est inférée à la promotion et **confirmée par l'utilisateur** (conservateur).

### Axe 3 — Pertinence / validité : *est-ce encore vrai ?*

La pertinence ne gate pas que la promotion — elle gate aussi la **rétention**.
Une règle promue peut devenir obsolète :

- le fichier / la fonction / le flag qu'elle nomme a disparu ;
- une décision plus récente la contredit ;
- elle n'a pas été « touchée » (confirmée ou réappliquée) depuis longtemps.

→ déclenche une **rétrogradation ou purge** (§6).

> **Insight clé : portée ≠ confiance.** Une directive explicite globale saute directement
> en `CLAUDE.md` global sans attendre la récurrence. Un pattern récurrent mais propre à un
> repo reste en `CLAUDE.md` projet — il ne doit **surtout pas** remonter en global.

## 4. Forme et destination

### 4.a — L'échelle d'application : la forme avant la destination

*Ajout du 2026-09-17, issu d'un REX sur l'industrialisation d'agents.*

La matrice ci-dessous répond à **où** ranger une règle. Elle ne répond pas à **sous quelle forme**,
et par défaut tout atterrit en prose — le niveau le plus faible. Une règle en prose se paie en
contexte à chaque session et n'est respectée que par bonne volonté ; c'est la leçon des trois
agents déclarés en `allowed-tools:` (champ ignoré) restés six mois sans contrainte réelle.

Avant de choisir une destination, descendre l'échelle et s'arrêter au premier barreau qui porte
la règle :

| Barreau | Forme | Chez nous |
|---|---|---|
| 1 | Contrainte d'outil | `orchestrator` sans `Write` ; `tools:` ; `isolation: worktree` |
| 2 | Hook / linter | le hook `ruff format` ; un refus en `pre-commit` |
| 3 | Vérification scriptée | `test-protocol.md` §A transformé en script |
| 4 | Prose | `CLAUDE.md`, `.claude/context/*`, une skill |

Ce que l'on sacrifie : une règle mécanique est plus lourde à écrire et plus rigide à retirer
qu'une phrase. Quand choisir autrement : une préférence de style ou de ton n'a pas de forme
mécanique — la prose est sa place, pas son échec. Comment surveiller : si la taille de
`CLAUDE.md` monte sans que le taux de respect monte, c'est qu'on promeut au mauvais barreau.

### 4.b — Matrice de routage

| Portée ↓ \ Confiance → | Faible (staging) | Confirmée (explicite OU récurrence≥3) |
|---|---|---|
| **Cross-projet** | candidate ledger | règle `~/.claude/CLAUDE.md` global + memory `type:feedback\|user` |
| **Projet** | candidate ledger | `.claude/context/*` (canonique) + `CLAUDE.md` projet |
| **Tech / pattern** | candidate ledger | **skill** réutilisable (via `skill-factory`) |

`reference` (URLs, dashboards) court-circuite la confiance : utile dès la 1ʳᵉ fois → memory `type:reference`.

> **Source de vérité (tranché).** `.claude/context/*` fait foi au **niveau projet** :
> un apprentissage projet est canonique là, pas dans `memory/`. `memory/` ne stocke que le
> **cross-projet / global** (`type:user|feedback|reference`) + l'index `MEMORY.md`.
> Le candidate ledger est un staging auxiliaire, jamais canonique. En cas de divergence sur
> un apprentissage projet, `.claude/context/*` gagne.

## 5. Mécanique — staging & comptage de récurrence

La récurrence se mesure **à travers les sessions**, donc il faut une mémoire des candidats
**avant** qu'ils atteignent le seuil. C'est le chaînon manquant.

### Source mécanique : les défauts

*Ajout du 2026-09-17.* Le comptage n'a de valeur que si son entrée est fiable. « Les observations
de la session » ne l'est pas : c'est ce dont on se souvient en fin de course. Une source mesurable
existe déjà, inexploitée — **les transcriptions de session**.

`claude/scripts/extract-defects.py` les lit et remonte deux signaux : les lancements de sous-agents
qui ont échoué, et les tâches relancées plusieurs fois. Chacun est un **défaut** : quelque chose que
l'usine a produit et qu'il a fallu refaire. Il arrive daté, dénombré, avec son message d'erreur —
pas comme une impression.

Premier cas réel (un autre projet, 2026-09-17) : une tâche de création de squelette de dépôt a
échoué sur `Cannot create agent worktree: not in a git repository` puis a demandé quatre
lancements. Cause racine : `builder` est isolé par worktree, et la tâche consistait justement à
créer le dépôt. Règle, barreau 1 de l'échelle §4.a. Rien de tout cela n'a atteint le ledger avant
cet ajout.

Le pas subjectif (directives, patterns, décisions) reste — **en plus**, pas à la place.

### Candidate ledger

Fichier append/update : `~/.claude/projects/<proj>/memory/_candidates.jsonl`
(un objet par ligne). Hors de `MEMORY.md` (pas chargé en contexte → coût nul).

```json
{
  "fingerprint": "kebab-slug-stable-de-l-observation",
  "summary": "une ligne",
  "scope_guess": "cross-project | project | tech",
  "count": 2,
  "first_seen": "2026-06-03",
  "last_seen": "2026-06-10",
  "explicit": false,
  "high_cost": false,
  "sessions": ["id1", "id2"]
}
```

### Identité d'une observation (fingerprint)

Le comptage exige une identité stable. Règle :
- slug kebab-case dérivé du **sens** de l'observation, pas du wording exact ;
- avant d'incrémenter, `/retro` cherche un candidat sémantiquement équivalent
  (même fingerprint OU summary proche) et **incrémente** au lieu de créer un doublon.

C'est le point le plus fragile : un fingerprint trop strict ne comptera jamais 3,
trop lâche fusionnera des observations distinctes. → à valider empiriquement (§8).

### Promotion (curseur conservateur)

À chaque `/retro` :
1. mettre à jour le ledger (incrément ou nouveau candidat) ;
2. détecter ceux qui franchissent le seuil (`explicit==true` OU `count>=3` OU `high_cost`) ;
3. **proposer** chaque promotion à l'utilisateur avec : observation, portée déduite, destination ;
4. sur validation → écrire à la destination (matrice §4), retirer du ledger,
   ajouter le pointeur dans `MEMORY.md` si c'est une memory ;
5. sur refus → marquer `dismissed` (ne plus reproposer).

> Conservateur = **rien n'atterrit en `CLAUDE.md` / skill sans validation explicite.**
> Le ledger, lui, se met à jour automatiquement (coût et risque nuls).

## 6. Purge / rétrogradation (axe 3)

Symétrique de la promotion. À chaque `/retro`, **proposer** (jamais auto en conservateur) :

- **Obsolète** — règle nommant un fichier/symbole/flag absent du repo → purge.
- **Contredite** — décision récente incompatible avec une règle antérieure → remplacer.
- **Dormante** — candidat non revu depuis > N sessions et `count` bas → expirer du ledger.
- **CLAUDE.md trop gros** — au-delà d'un seuil de taille, proposer les règles les moins
  « touchées » à fusionner/retirer.

`anti-patterns.md` / `decisions.md` passent de *append-only* à *append + purge proposée*.

## 7. Intégration dans `/retro`

Étapes ajoutées au flow existant (sans casser les sorties actuelles) :

```
/retro
 ├─ (existant) status.md / anti-patterns.md / decisions.md / CLAUDE.md / README.md
 ├─ NOUVEAU — Capitalisation
 │   1. extraire les observations de la session (directives, patterns, erreurs, décisions)
 │   2. mettre à jour _candidates.jsonl (fingerprint → incrément)
 │   3. proposer les promotions franchissant le seuil (matrice §4)   [validation]
 │   4. proposer les purges/rétrogradations (axe 3)                  [validation]
 └─ résumé : promus / refusés / purgés / candidats en attente (count)
```

Compat : les fichiers `.claude/context/*` restent. La memory et le ledger viennent **en plus**.
À terme, `anti-patterns.md`/`decisions.md` pourraient devenir des vues du ledger, mais hors scope ici.

### Contrainte de légèreté (non négociable)

L'ajout ne doit **pas alourdir** `/retro`. Règles :
- Mise à jour du ledger = simple lecture/écriture JSONL, pas d'analyse coûteuse.
- Propositions **groupées et rares** : un seul bloc « promotions / purges » en fin de retro,
  pas une interruption par observation.
- **Auditable** : chaque promotion/purge trace sa raison (axe déclencheur, count, portée) dans le
  résumé du retro. On doit pouvoir rejouer *pourquoi* une règle est montée ou tombée.
- Si le ledger ou les propositions deviennent bruyants, **durcir les seuils** avant d'ajouter de la mécanique.

## 8. Risques & points à valider empiriquement

- **Stabilité du fingerprint** — cœur du comptage. À tester sur des observations réelles avant
  de faire confiance au seuil ≥3. *Partiellement adressé 2026-09-17 :* un candidat issu d'un défaut
  (§5) porte une identité déjà stable — l'identifiant de tâche, le message d'erreur. Le risque ne
  subsiste que pour les candidats subjectifs.
- **L'extracteur lui-même n'est pas mesuré.** Il ne voit que ce que les transcriptions contiennent :
  échecs de lancement et relances. Une sortie d'agent fausse mais acceptée du premier coup lui
  échappe entièrement — c'est un filet, pas une couverture. À réévaluer après trois retros : s'il ne
  remonte rien d'exploitable, le retirer plutôt que l'élargir.
- **Fatigue de validation** — en conservateur, chaque `/retro` peut proposer plusieurs promotions.
  Garder les propositions groupées et rares ; si le bruit monte, durcir les seuils.
- **Inférence de portée** — un mauvais classement remonte un quirk en global. La validation
  utilisateur est le garde-fou ; ne jamais inférer la portée silencieusement.
- **Frontière context/ ↔ memory/** — tranché : `.claude/context/*` canonique au niveau projet,
  `memory/` réservé au cross-projet/global. Risque résiduel : un apprentissage mal classé
  (projet rangé en global, ou l'inverse). La validation utilisateur reste le garde-fou.

## 9. Hors scope

- Promotion/purge **automatiques sans validation** (= curseur agressif, écarté pour l'instant).
- Réécriture de `anti-patterns.md`/`decisions.md` en vues dérivées du ledger.
- Détection de récurrence par embeddings (on commence par le fingerprint sémantique simple).
