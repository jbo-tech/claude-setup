---
name: infra-containers
description: Best practices for open-source containerization, orchestration, storage and deployment. Activates when the user mentions "Dockerfile", "docker compose", "podman", "kubernetes", "k8s", "k3s", "container", "deploy", "healthcheck", "image", "orchestration", "systemd", "kestra", "CI/CD", "monitoring", "minio", "rclone", "homelab", "edge". Do NOT use for pure security questions (use security-review). For managed PaaS (Vercel, Render, Fly.io, AWS-specific services), defer to platform-specific skills.
---

# Infrastructure & Containers

Guidance for open-source containerization, orchestration and application deployment.

## Scope

**In scope** (open-source stack) :
- Docker, Podman, Buildah (image build & runtime)
- Docker Compose, Podman Compose
- Kubernetes (K3s, K8s vanilla), Nomad
- Kestra for workflow orchestration
- systemd units for non-containerized services
- MinIO for object storage, rclone for transfers
- Constrained/edge deployment (homelab, ARM boards, small VPS)

**Out of scope** — defer to specialized skills :
- Vercel deployments → `vercel-react-best-practices` family
- Managed cloud-specific resources (AWS Lambda, Cloud Run, App Engine, Azure-specific) → platform skills
- Pure security review (CVE, hardening, secrets at rest) → `security-review`

## When this skill activates

- Writing or reviewing Dockerfile / Containerfile
- Docker Compose, Podman Compose or Kubernetes manifest
- Orchestration choices (Kestra, systemd, K3s)
- Image optimization (size, layers, build time)
- Setting up monitoring and healthchecks
- Storage configuration (MinIO, rclone, bind mounts)
- Deploying to constrained environments (homelab, edge)

## Quick checklist

### Dockerfile / Containerfile
- Minimal and versioned base image (not `:latest`)
- Multi-stage build if compilation needed
- Non-root user defined
- `HEALTHCHECK` configured
- `.dockerignore` / `.containerignore` present and complete
- Layer order optimized (dependencies before code)

### Compose (Docker / Podman)
- Restart policy defined
- Memory / CPU limits if constrained environment
- Named volumes for persistent data
- Dedicated network if multi-service
- Environment variables externalized (`.env`)

### Kubernetes / K3s
- Resource requests and limits defined
- Liveness and readiness probes configured
- No `:latest` in images
- Namespaces for isolation
- ConfigMaps / Secrets for configuration
- For K3s on edge : check storage class, default LB compatibility

### Orchestration (Kestra / systemd)
- Idempotent tasks with timeout
- Explicit failure handling (retry, allowFailure)
- Triggers with explicit timezone
- Documented rollback strategy
- systemd : `Restart=on-failure`, dependencies declared

### Monitoring
- `/health` endpoint on each service
- Structured logs (JSON) with rotation
- Appropriate log levels
- Actionable alerts (no noise)

### Storage (MinIO / rclone)
- MinIO buckets with minimal access policies
- Lifecycle rules for automatic cleanup
- Rclone with local cache configured and sized
- Retry and timeout on network operations
- Degraded mode if remote storage unavailable

### Constrained environments (homelab, edge)
- Explicit memory / CPU limits on each service
- Swap configured but limited
- No concurrent resource-hungry tasks
- Memory monitoring with alerts
- Cloud bursting for heavy tasks (idempotent provisioning)

## Key principles

1. **Immutable infrastructure** — Don't modify a running container, rebuild it
2. **Minimal by default** — The smaller the image, the smaller the attack surface
3. **Mandatory healthcheck** — A container without healthcheck is a black box
4. **Constrained environment = explicit constraints** — Memory / CPU limits always defined
5. **Open source first** — Self-hostable tools before managed PaaS, unless cost / SLA argues otherwise

## Anti-patterns

- Image based on `:latest` in production
- Hardcoded secrets in Dockerfile or compose
- Container running as root without reason
- No healthcheck → restart loop without diagnosis
- Bind-mount volumes in production instead of named volumes
- Logs on stdout without rotation or aggregation

## When to escalate to @infra-expert

Use the full agent for :
- In-depth review of a full Docker / Podman / K8s stack
- Performance audit or image optimization
- Complex orchestration architecture (Kestra, multi-step workflows)
- Deploying to constrained environments
- When structured review format with resource estimation is needed
