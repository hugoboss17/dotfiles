---
name: deployments
metadata:
  compatible_agents: [claude-code]
  tags: [terraform, aws, docker, github-actions, ci-cd, deployment, devops]
description: >
  Deployment and infrastructure automation assistant. Scaffolds Terraform modules,
  generates GitHub Actions pipelines, sets up Docker, plans AWS environments,
  and designs rollback strategies. Stack: Terraform, AWS, Docker, GitHub Actions.
  Trigger with: "scaffold terraform", "create CI/CD pipeline", "write Dockerfile",
  "set up deployment", "create GitHub Actions workflow", "plan environments".
---

## Commands

| Command | Description |
|---------|-------------|
| `/deploy terraform` | Scaffold Terraform modules for AWS infrastructure |
| `/deploy pipeline` | Generate GitHub Actions CI/CD workflows |
| `/deploy docker` | Generate Dockerfile and docker-compose setup |
| `/deploy environments` | Plan environment strategy (dev/staging/prod) |
| `/deploy rollback` | Design a rollback strategy for a deployment |

---

## `/deploy terraform`

Scaffold Terraform modules for a described AWS workload.

**Interview:**
1. What AWS resources are needed? (or run `/arch aws` first)
2. What environments? (default: dev, staging, prod)
3. Remote state backend? (default: S3 + DynamoDB lock)
4. Existing VPC or create new?

**Output structure:**
```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── backend.tf
└── modules/
    ├── networking/     (VPC, subnets, SGs, NAT)
    ├── compute/        (ECS cluster, task definitions, ALB)
    ├── database/       (RDS, parameter groups, subnet group)
    └── storage/        (S3 buckets, policies)
```

**Rules:**
- All resources tagged with: `Environment`, `Project`, `ManagedBy = terraform`
- No hardcoded values — everything in `variables.tf` with sensible defaults
- Sensitive outputs marked `sensitive = true`
- State backend always uses S3 + DynamoDB locking
- Use `for_each` over `count` for resources that may need individual addressing
- Remote state data sources for cross-module references

**Module conventions:**
- Each module exposes its own `variables.tf` and `outputs.tf`
- Modules should be reusable across environments via variable injection
- `terraform/envs/[env]/` folder for environment-specific tfvars

---

## `/deploy pipeline`

Generate GitHub Actions workflows for CI and CD.

**Interview:**
1. What is the tech stack? (default: Laravel + Vue/TS)
2. What triggers CI? (default: push to any branch, PRs to main)
3. What triggers CD? (default: push to main → staging, tags → prod)
4. What is the deployment target? (ECS, EC2, Lambda, Laravel Cloud)
5. What secrets are needed?

**Output:** `.github/workflows/`

**CI workflow (`ci.yml`) includes:**
- PHP setup (correct version, extensions)
- Composer install (cached)
- Node install + build (cached)
- Run Pint (code style)
- Run PHPStan/Larastan
- Run Pest tests with coverage
- TypeScript type check (`tsc --noEmit`)
- ESLint

**CD workflow (`deploy.yml`) includes:**
- Build Docker image → push to ECR
- Run `terraform apply` (or use ECS deploy action)
- Zero-downtime deploy (ECS rolling update or blue/green)
- Post-deploy smoke test
- Slack/Discord notification on success/failure

**Rules:**
- CI must pass before CD can run
- Secrets referenced via `${{ secrets.NAME }}` — never hardcoded
- Cache dependencies (Composer, npm) by lockfile hash
- Separate jobs for lint, test, build — parallelise where possible
- Always pin action versions to a commit SHA, not `@latest`

---

## `/deploy docker`

Generate Dockerfile and docker-compose for local development and production.

**Input:** Stack description (default: Laravel + Vue/TS + PostgreSQL + Valkey).

**Output:**
- `Dockerfile` (multi-stage: build stage + production stage)
- `docker-compose.yml` (local dev with hot reload)
- `docker-compose.prod.yml` (production overrides)
- `.dockerignore`

**Multi-stage Dockerfile structure:**
1. `base` — PHP/Node base with extensions
2. `build` — Composer + npm install, asset build
3. `production` — final minimal image, no dev deps, non-root user

**Rules:**
- Production image runs as non-root user
- No `.env` file in image — inject at runtime via environment variables
- `COPY --chown` for correct file permissions
- Health check defined in Dockerfile
- `.dockerignore` excludes: `node_modules`, `.git`, `tests`, `*.md`, `.env*`

---

## `/deploy environments`

Plan a multi-environment strategy.

**Input:** Product description and team size.

**Output:**
- **Environment map:** dev → staging → prod (+ optional review apps per PR)
- **Config differences per environment:** instance sizes, replicas, feature flags
- **Promotion flow:** how code moves from dev to prod
- **Secret management strategy:** who can access what, rotation plan
- **Infrastructure cost estimate per environment**

**Rules:**
- Staging must mirror prod topology (not necessarily same size)
- No shared databases between environments
- Feature flags preferred over environment branches
- Review apps for PRs are high value — recommend if feasible

---

## `/deploy rollback`

Design a rollback strategy for a given deployment approach.

**Input:** Deployment target and current deploy process.

**Output:**
- **Rollback trigger criteria:** what metrics/errors indicate a rollback is needed
- **Rollback procedure:** step-by-step, with estimated time
- **Database migration rollback:** how to handle irreversible migrations
- **Rollback automation:** GitHub Actions job or script
- **Post-rollback checklist**

**Rules:**
- Every deploy must have a documented rollback path before going live
- Database migrations must be backward-compatible for one release cycle
- Rollback time target: < 5 minutes for application, document if DB is involved

---

## Trigger Phrases

`scaffold terraform`, `terraform module`, `create CI/CD`, `GitHub Actions pipeline`,
`write Dockerfile`, `docker setup`, `containerise`, `deployment pipeline`,
`set up environments`, `staging environment`, `rollback strategy`,
`zero-downtime deploy`, `ECS deploy`, `AWS deployment`

---

## Anti-Patterns

| Anti-Pattern | Correct Approach |
|---|---|
| Secrets hardcoded in workflow YAML | Always use `${{ secrets.NAME }}` |
| Single Dockerfile for dev and prod | Multi-stage: dev layer + prod layer |
| Running as root in container | Always specify non-root user in Dockerfile |
| Pinning actions to `@latest` | Pin to commit SHA for reproducibility |
| Terraform state in local files | Always use S3 + DynamoDB remote state |
| Deploying directly from dev branch | Enforce promotion flow: dev → staging → prod |
| No rollback plan before deploy | Define rollback before every production deploy |
| Irreversible DB migrations | Expand/contract pattern — always backward-compatible |

---

## References

| File | Purpose |
|------|---------|
| `references/terraform-patterns.md` | Terraform module structure, tagging conventions, state config |
| `references/github-actions.md` | Workflow templates for Laravel + Vue/TS CI/CD |
| `references/docker-patterns.md` | Multi-stage Dockerfile patterns, compose setup |

---

## Code Style

- Write human-readable code
- No comments unless absolutely necessary — code should be self-explanatory through naming and structure
- Never commit unless the user explicitly asks
