---
name: infra-containers
description: Bonnes pratiques pour la conteneurisation, l'orchestration, le cloud storage et le déploiement. S'active quand l'utilisateur mentionne "Dockerfile", "docker compose", "podman", "kubernetes", "k8s", "container", "deploy", "healthcheck", "image", "orchestration", "systemd", "kestra", "CI/CD", "monitoring", "S3", "MinIO", "rclone", "homelab", "ZimaBoard", "Raspberry Pi". Ne PAS utiliser pour les questions de sécurité pure (utiliser security-review).
---

# Infrastructure & Containers

Guidance pour la conteneurisation, l'orchestration et le déploiement d'applications.

## Quand ce skill s'active

- Écriture ou revue de Dockerfile / Containerfile
- Configuration Docker Compose, Podman Compose ou Kubernetes
- Choix d'orchestration (Kestra, systemd, K8s)
- Optimisation d'images (taille, layers, build time)
- Mise en place de monitoring et healthchecks
- Configuration de stockage cloud (S3, MinIO, Rclone)
- Déploiement sur environnements contraints (homelab, edge)

## Checklist rapide

### Dockerfile / Containerfile
- Image de base minimale et versionnée (pas :latest)
- Multi-stage build si compilation nécessaire
- Utilisateur non-root défini
- HEALTHCHECK configuré
- .dockerignore / .containerignore présent et complet
- Ordre des layers optimisé (dépendances avant code)

### Compose (Docker / Podman)
- Politique de restart définie
- Limites mémoire/CPU si environnement contraint
- Volumes nommés pour les données persistantes
- Réseau dédié si multi-service
- Variables d'environnement externalisées (.env)

### Kubernetes
- Resources requests et limits définis
- Liveness et readiness probes configurées
- Pas de :latest dans les images
- Namespaces pour l'isolation
- ConfigMaps/Secrets pour la configuration

### Orchestration
- Tâches idempotentes avec timeout
- Gestion explicite des échecs
- Triggers avec timezone explicite
- Stratégie de rollback documentée

### Monitoring
- Endpoint /health sur chaque service
- Logs structurés (JSON) avec rotation
- Niveaux de log appropriés
- Alertes actionnables (pas de bruit)

### Cloud & Storage
- Buckets S3/MinIO avec policies d'accès minimales
- Lifecycle rules pour le nettoyage automatique
- Rclone avec cache local configuré et dimensionné
- Retry et timeout sur les opérations réseau
- Mode dégradé si stockage distant indisponible

### Environnements contraints (homelab, edge)
- Limites mémoire/CPU explicites sur chaque service
- Swap configuré mais limité
- Pas de tâches gourmandes en parallèle
- Monitoring mémoire avec alertes
- Cloud bursting pour les tâches lourdes (provisioning idempotent)

## Principes clés

1. **Immutable infrastructure** — Ne pas modifier un conteneur en cours, reconstruire
2. **Minimal par défaut** — Plus l'image est petite, moins la surface d'attaque est grande
3. **Healthcheck obligatoire** — Un conteneur sans healthcheck est une boîte noire
4. **Environnement contraint = contrainte explicite** — Limites mémoire/CPU toujours définies

## Anti-patterns

- Image basée sur :latest en production
- Secrets en dur dans le Dockerfile ou le compose
- Conteneur qui tourne en root sans raison
- Pas de healthcheck → restart en boucle sans diagnostic
- Volume bind-mount en production au lieu de volumes nommés
- Logs sur stdout sans rotation ni agrégation

## Quand escalader vers @infra-expert

Utiliser l'agent complet pour :
- Revue approfondie d'une stack Docker/Podman/K8s complète
- Audit de performance ou d'optimisation d'images
- Architecture d'orchestration complexe (Kestra, workflows multi-étapes)
- Déploiement sur environnements contraints (ZimaBoard, Raspberry Pi)
- Quand le format de revue structuré avec estimation des ressources est nécessaire
