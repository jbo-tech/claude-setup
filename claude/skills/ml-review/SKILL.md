---
name: ml-review
description: Bonnes pratiques pour le machine learning, deep learning et l'analyse de données. S'active quand l'utilisateur mentionne "model", "training", "features", "cross-validation", "accuracy", "overfitting", "data leakage", "preprocessing", "sklearn", "pytorch", "tensorflow", "neural network", "regression", "classification". Ne PAS utiliser pour les pipelines ETL ou la qualité des données (utiliser data-engineering).
---

# ML Review

Guidance pour la conception, la validation et le déploiement de modèles ML/DL.

## Quand ce skill s'active

- Revue de code ML ou deep learning
- Questions sur le feature engineering ou le preprocessing
- Validation de la méthodologie (cross-validation, métriques)
- Détection de data leakage
- Choix de modèle ou d'architecture
- Mise en production d'un modèle (serving, monitoring)

## Checklist rapide

### Data Leakage
- Scaling/encoding APRÈS le train/test split
- Pas de features dérivées de données futures
- Validation temporelle si données séquentielles
- Agrégations calculées sur le train set uniquement

### Validation
- Métrique alignée avec l'objectif métier
- Cross-validation stratifiée si données déséquilibrées
- Test set jamais touché pendant le tuning
- Baseline naïve documentée

### Reproductibilité
- Seeds fixés (numpy, random, framework)
- Versions des dépendances verrouillées
- Données d'entraînement versionnées
- Hyperparamètres trackés

### Serving
- Preprocessing identique entre entraînement et inférence
- Modèle packagé avec scaler/encoder
- Gestion des entrées malformées
- Logging des prédictions pour monitoring

## Principes clés

1. **Leakage = ennemi n°1** — Toujours vérifier la séparation temporelle et informationnelle
2. **Baseline d'abord** — Un modèle simple qui bat le hasard avant d'aller plus loin
3. **Métrique = décision métier** — L'accuracy n'est presque jamais la bonne métrique
4. **Reproductibilité non négociable** — Si on ne peut pas le reproduire, on ne peut pas le débugger

## Anti-patterns

- Fit le scaler sur tout le dataset avant le split
- Optimiser l'accuracy sur des classes déséquilibrées
- Pas de seed → résultats différents à chaque run
- Preprocessing différent entre train et inference
- Modèle en production sans monitoring de drift

## Quand escalader vers @data-ml-expert

Utiliser l'agent complet pour :
- Revue approfondie de code ML/DL avec checklists détaillées
- Audit complet d'un pipeline ML de bout en bout
- Choix d'architecture de modèle complexe
- Revue d'une mise en production (API, Streamlit, Gradio)
- Quand le format de revue structuré (critique/warning/positif) est nécessaire
