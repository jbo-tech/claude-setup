---
name: security-review
description: Security best practices for infrastructure and deployments. Activates when the user mentions "secrets", "permissions", "exposed port", "CVE", "hardening", "vulnerability", "scan", "credentials", "TLS", "firewall", "root access", "capabilities". Do NOT use for container configuration (use infra-containers) unless the issue is specifically security-related.
---

# Security Review

Guidance for infrastructure, container and deployment security.

## When this skill activates

- Security review of infrastructure configuration
- Secrets and credentials management
- Container or service hardening
- Questions about exposed ports or permissions
- Vulnerability scanning and CVEs
- TLS/SSL configuration

## Quick checklist

### Secrets & Credentials
- No hardcoded secrets in code or configuration
- Secrets injected via secret store or environment variables
- .env files excluded from versioning (.gitignore)
- Secret rotation documented
- No credentials in logs

### Containers
- Non-root user
- Capabilities dropped (no --privileged)
- Images scanned for vulnerabilities
- Exposed ports minimized
- Read-only filesystem when possible

### Network
- Ports exposed only when necessary
- TLS enabled for external communications
- Internal network isolated for internal services
- No debug port exposed in production

### Permissions
- Least privilege principle applied
- File permissions verified (no 777)
- Volume access restricted
- Service accounts with minimal permissions

### CI/CD
- Secrets via CI secret store (not plaintext in pipeline)
- Signed images if shared registry
- No root push to registry
- Vulnerability scanning in pipeline

## Key principles

1. **Least privilege** — Each component only accesses what it needs
2. **Defense in depth** — No single security layer
3. **Secrets = ephemeral** — Regular rotation, never hardcoded
4. **Audit trail** — Every sensitive action must be traceable

## Anti-patterns

- `--privileged` or `--cap-add=ALL` without justification
- Plaintext secrets in docker-compose.yml or CI environment variables
- Port 22 exposed on a container
- Base image never updated (accumulated CVEs)
- Wildcard permissions (chmod 777, 0.0.0.0 without restriction)
- Disabling TLS "because it's internal network"

## When to escalate to @infra-expert

Use the full agent for:
- Full security audit of a stack
- Vulnerability analysis and remediation plan
- Secure network architecture (isolation, segmentation)
- CI/CD chain review for supply chain risks
- When structured review format with criticality levels is needed
