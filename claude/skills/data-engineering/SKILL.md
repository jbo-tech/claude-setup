---
name: data-engineering
description: Bonnes pratiques pour les pipelines de données, ETL/ELT, qualité des données et stockage. S'active quand l'utilisateur mentionne "pipeline", "ETL", "data quality", "parquet", "duckdb", "ingestion", "orchestration", "data pipeline", "schema validation", "idempotent". Ne PAS utiliser pour du machine learning ou de l'analyse statistique (utiliser ml-review).
---

# Data Engineering

Guidance pour la conception et la revue de pipelines de données.

## Quand ce skill s'active

- Conception ou revue de pipelines ETL/ELT
- Questions sur la qualité des données ou la validation de schémas
- Choix de formats de stockage (Parquet, DuckDB, CSV)
- Configuration d'orchestrateurs (Kestra, Airflow, Prefect)
- Problèmes d'idempotence ou de reprise sur erreur

## Checklist rapide

Avant de valider un pipeline, vérifier :

### Ingestion
- Validation du schéma au point d'entrée
- Gestion des erreurs API (retry, backoff, timeout)
- Stratégie de backfill documentée

### Transformation
- Opérations idempotentes
- Pas de dépendance à l'ordre d'exécution
- Gestion explicite des valeurs nulles
- Partitionnement aligné sur les patterns de requêtes

### Stockage
- Format adapté au cas d'usage (ligne vs colonne)
- Compression activée
- Métadonnées versionnées
- Stratégie de rétention définie

### Orchestration
- Tâches idempotentes avec timeout
- Gestion explicite des échecs (retry, allowFailure)
- Triggers avec timezone explicite
- Stratégie de backfill si applicable

## Principes clés

1. **Idempotence partout** — Rejouer un pipeline ne doit jamais corrompre les données
2. **Schéma en premier** — Valider la structure avant de traiter le contenu
3. **Fail loud** — Logger les anomalies, pas seulement les erreurs
4. **Partition intelligemment** — Aligner sur les patterns de lecture, pas d'écriture

## Anti-patterns

- Pipeline qui dépend de l'heure d'exécution pour sa logique
- Transformation qui lit et écrit dans la même table
- Schéma implicite ("ça marche parce que le CSV a toujours 5 colonnes")
- Aucune stratégie de reprise après crash

## Quand escalader vers @data-ml-expert

Utiliser l'agent complet pour :
- Revue approfondie d'un pipeline complexe
- Audit de qualité des données sur un système existant
- Choix d'architecture de données (batch vs streaming, lac vs warehouse)
- Quand les checklists détaillées et le format de revue structuré sont nécessaires
