---
name: infra-containers
description: Best practices for containerization, orchestration, cloud storage and deployment. Activates when the user mentions "Dockerfile", "docker compose", "podman", "kubernetes", "k8s", "container", "deploy", "healthcheck", "image", "orchestration", "systemd", "kestra", "CI/CD", "monitoring", "S3", "MinIO", "rclone", "homelab", "ZimaBoard", "Raspberry Pi". Do NOT use for pure security questions (use security-review).
---

# Infrastructure & Containers

Guidance for containerization, orchestration and application deployment.

## When this skill activates

- Writing or reviewing Dockerfile / Containerfile
- Docker Compose, Podman Compose or Kubernetes configuration
- Orchestration choices (Kestra, systemd, K8s)
- Image optimization (size, layers, build time)
- Setting up monitoring and healthchecks
- Cloud storage configuration (S3, MinIO, Rclone)
- Deploying to constrained environments (homelab, edge)

## Quick checklist

### Dockerfile / Containerfile
- Minimal and versioned base image (not :latest)
- Multi-stage build if compilation needed
- Non-root user defined
- HEALTHCHECK configured
- .dockerignore / .containerignore present and complete
- Layer order optimized (dependencies before code)

### Compose (Docker / Podman)
- Restart policy defined
- Memory/CPU limits if constrained environment
- Named volumes for persistent data
- Dedicated network if multi-service
- Environment variables externalized (.env)

### Kubernetes
- Resource requests and limits defined
- Liveness and readiness probes configured
- No :latest in images
- Namespaces for isolation
- ConfigMaps/Secrets for configuration

### Orchestration
- Idempotent tasks with timeout
- Explicit failure handling
- Triggers with explicit timezone
- Documented rollback strategy

### Monitoring
- /health endpoint on each service
- Structured logs (JSON) with rotation
- Appropriate log levels
- Actionable alerts (no noise)

### Cloud & Storage
- S3/MinIO buckets with minimal access policies
- Lifecycle rules for automatic cleanup
- Rclone with local cache configured and sized
- Retry and timeout on network operations
- Degraded mode if remote storage unavailable

### Constrained environments (homelab, edge)
- Explicit memory/CPU limits on each service
- Swap configured but limited
- No concurrent resource-hungry tasks
- Memory monitoring with alerts
- Cloud bursting for heavy tasks (idempotent provisioning)

## Key principles

1. **Immutable infrastructure** — Don't modify a running container, rebuild it
2. **Minimal by default** — The smaller the image, the smaller the attack surface
3. **Mandatory healthcheck** — A container without healthcheck is a black box
4. **Constrained environment = explicit constraints** — Memory/CPU limits always defined

## Anti-patterns

- Image based on :latest in production
- Hardcoded secrets in Dockerfile or compose
- Container running as root without reason
- No healthcheck → restart loop without diagnosis
- Bind-mount volumes in production instead of named volumes
- Logs on stdout without rotation or aggregation

## When to escalate to @infra-expert

Use the full agent for:
- In-depth review of a full Docker/Podman/K8s stack
- Performance audit or image optimization
- Complex orchestration architecture (Kestra, multi-step workflows)
- Deploying to constrained environments (ZimaBoard, Raspberry Pi)
- When structured review format with resource estimation is needed
