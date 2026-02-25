---
name: security-review
description: Bonnes pratiques de sécurité pour l'infrastructure et les déploiements. S'active quand l'utilisateur mentionne "secrets", "permissions", "exposed port", "CVE", "hardening", "vulnerability", "scan", "credentials", "TLS", "firewall", "root access", "capabilities". Ne PAS utiliser pour la configuration de conteneurs (utiliser infra-containers) sauf si le problème est spécifiquement lié à la sécurité.
---

# Security Review

Guidance pour la sécurité de l'infrastructure, des conteneurs et des déploiements.

## Quand ce skill s'active

- Revue de sécurité d'une configuration d'infrastructure
- Gestion des secrets et credentials
- Hardening de conteneurs ou de services
- Questions sur les ports exposés ou les permissions
- Scan de vulnérabilités et CVE
- Configuration TLS/SSL

## Checklist rapide

### Secrets & Credentials
- Aucun secret en dur dans le code ou la configuration
- Secrets injectés via secret store ou variables d'environnement
- Fichiers .env exclus du versioning (.gitignore)
- Rotation des secrets documentée
- Pas de credentials dans les logs

### Conteneurs
- Utilisateur non-root
- Capabilities droppées (pas de --privileged)
- Images scannées pour les vulnérabilités
- Ports exposés minimisés
- Read-only filesystem quand possible

### Réseau
- Ports exposés uniquement si nécessaire
- TLS activé pour les communications externes
- Réseau interne isolé pour les services internes
- Pas de port de debug exposé en production

### Permissions
- Principe du moindre privilège appliqué
- Permissions fichiers vérifiées (pas de 777)
- Accès aux volumes restreint
- Service accounts avec permissions minimales

### CI/CD
- Secrets via le secret store du CI (pas en clair dans le pipeline)
- Images signées si registry partagé
- Pas de push en root sur le registry
- Scan de vulnérabilités dans le pipeline

## Principes clés

1. **Moindre privilège** — Chaque composant n'a accès qu'à ce dont il a besoin
2. **Défense en profondeur** — Pas de couche unique de sécurité
3. **Secrets = éphémères** — Rotation régulière, jamais en dur
4. **Audit trail** — Toute action sensible doit être traçable

## Anti-patterns

- `--privileged` ou `--cap-add=ALL` sans justification
- Secrets en clair dans docker-compose.yml ou les variables d'environnement du CI
- Port 22 exposé sur un conteneur
- Image de base jamais mise à jour (CVE accumulées)
- Wildcard dans les permissions (chmod 777, 0.0.0.0 sans restriction)
- Désactiver TLS "parce que c'est du réseau interne"

## Quand escalader vers @infra-expert

Utiliser l'agent complet pour :
- Audit de sécurité complet d'une stack
- Analyse de vulnérabilités et plan de remédiation
- Architecture réseau sécurisée (isolation, segmentation)
- Revue de la chaîne CI/CD pour les risques supply chain
- Quand le format de revue structuré avec niveaux de criticité est nécessaire
