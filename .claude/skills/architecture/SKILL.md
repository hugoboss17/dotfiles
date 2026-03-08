---
name: architecture
metadata:
  compatible_agents: [claude-code]
  tags: [architecture, aws, gcp, azure, hetzner, hostinger, laravel, typescript, vue, api, adr, system-design, multi-cloud]
description: >
  System architecture assistant for CTOs and technical leads. Designs systems, creates ADRs,
  plans infrastructure across AWS, GCP, Azure, Hetzner, and Hostinger, designs APIs,
  and reviews existing architecture.
  Trigger with: "design the architecture", "create an ADR", "plan AWS infra", "plan GCP infra",
  "plan Azure infra", "Hetzner setup", "Hostinger setup", "design the API",
  "review this architecture", "how should we structure this".
---

## Commands

| Command | Description |
|---------|-------------|
| `/arch design` | Design system architecture for a product or feature |
| `/arch adr` | Create an Architecture Decision Record |
| `/arch aws` | Plan AWS infrastructure for a workload |
| `/arch gcp` | Plan GCP infrastructure for a workload |
| `/arch azure` | Plan Azure infrastructure for a workload |
| `/arch hetzner` | Plan Hetzner Cloud infrastructure for a workload |
| `/arch hostinger` | Plan Hostinger infrastructure for a workload |
| `/arch api` | Design a REST or GraphQL API |
| `/arch review` | Review and critique existing architecture |

---

## `/arch design`

Design a system architecture from a product description or PRD.

**Interview:**
1. What does the system do? (one sentence)
2. What is the expected scale? (users, requests/sec, data volume)
3. What is the tech stack preference or constraint?
4. What are the main integrations (third-party services, APIs)?
5. What are the critical non-functional requirements? (availability, latency, compliance)

**Output:**
- **System overview:** components, boundaries, responsibilities
- **Component diagram** (described in text/ASCII or Mermaid)
- **Data flow:** how data moves between components
- **Stack decisions:** backend, frontend, database, queue, cache, hosting
- **Trade-offs:** what this design optimises for and what it sacrifices
- **Open questions:** decisions that need more information

**Stack defaults (unless overridden):**
- Backend: Laravel (PHP 8.3+)
- Frontend: Vue 3 + TypeScript + Vite
- Database: PostgreSQL
- Queue: Valkey + Laravel Horizon
- Cache: Valkey
- Storage: S3 or compatible (GCS, Azure Blob, Hetzner Object Storage)
- Hosting: ask — AWS ECS / GCP Cloud Run / Azure ACI / Hetzner VPS
- CI/CD: GitHub Actions

---

## `/arch adr`

Create an Architecture Decision Record for a technical decision.

**Interview:**
1. What decision needs to be made?
2. What are the candidate options?
3. What are the constraints or drivers for this decision?
4. What was decided, and why?

**Output:** `docs/adr/ADR-[NNN]-[title].md` following `references/adr-template.md`

**Rules:**
- ADRs are immutable once accepted — create a new ADR to supersede
- Status must be one of: Proposed / Accepted / Deprecated / Superseded
- Every option must include pros and cons
- The "why" section must reference the actual drivers, not just the outcome

---

## `/arch aws`

Plan AWS infrastructure for a workload.

**Interview:**
1. What is the workload? (web app, API, batch job, event-driven, etc.)
2. What are the availability and latency requirements?
3. What is the expected traffic pattern? (steady, spiky, batch)
4. What compliance or data residency requirements exist?
5. What is the rough budget constraint?

**Output:**
- **Core services:** compute, database, storage, networking choices with justification
- **Architecture diagram** (Mermaid or described)
- **Networking:** VPC, subnets (public/private), security groups, NAT
- **IAM strategy:** roles, least privilege, service accounts
- **Cost estimate:** rough monthly breakdown
- **Terraform module structure:** suggested layout per `references/terraform-patterns.md`

**Common patterns:**
- Web app: ALB → ECS Fargate → RDS + ElastiCache + S3
- API-only: API Gateway → Lambda or ECS → RDS
- Async workload: SQS → Lambda/ECS worker → RDS/DynamoDB
- Static frontend: CloudFront → S3

---

## `/arch gcp`

Plan GCP infrastructure for a workload.

**Interview:**
1. What is the workload? (web app, API, background jobs, data pipeline, etc.)
2. What are the availability and latency requirements?
3. What is the expected traffic pattern?
4. Data residency requirements? (EU, US, multi-region)
5. Budget constraint?

**Output:**
- **Core services:** compute, database, storage, networking with justification
- **Architecture diagram** (Mermaid or described)
- **Networking:** VPC, subnets, firewall rules, Cloud NAT
- **IAM strategy:** service accounts, workload identity, least privilege
- **Cost estimate:** rough monthly breakdown
- **Terraform module structure:** using `hashicorp/google` provider

**Service mapping:**

| Need | GCP Service |
|------|------------|
| Container hosting | Cloud Run (serverless) or GKE (K8s) |
| VM compute | Compute Engine |
| Managed database | Cloud SQL (PostgreSQL/MySQL) |
| Cache (Valkey) | Memorystore for Valkey |
| Object storage | Cloud Storage (GCS) |
| CDN | Cloud CDN |
| Load balancer | Cloud Load Balancing |
| Message queue | Pub/Sub or Cloud Tasks |
| DNS | Cloud DNS |
| Secrets | Secret Manager |
| Registry | Artifact Registry |

**Common patterns:**
- Web app: Cloud Load Balancing → Cloud Run → Cloud SQL + Memorystore + GCS
- API-only: API Gateway → Cloud Run → Cloud SQL
- Async workload: Pub/Sub → Cloud Run Jobs → Cloud SQL
- Static frontend: Cloud CDN → GCS bucket

---

## `/arch azure`

Plan Azure infrastructure for a workload.

**Interview:**
1. What is the workload?
2. Availability and latency requirements?
3. Is there existing Microsoft/Azure ecosystem (AD, M365)?
4. Compliance requirements? (Azure has strong EU compliance)
5. Budget constraint?

**Output:**
- **Core services:** compute, database, storage, networking with justification
- **Architecture diagram** (Mermaid or described)
- **Networking:** VNet, subnets, NSGs, NAT Gateway
- **IAM strategy:** Azure AD / Entra ID, managed identities, RBAC
- **Cost estimate:** rough monthly breakdown
- **Terraform module structure:** using `hashicorp/azurerm` provider

**Service mapping:**

| Need | Azure Service |
|------|--------------|
| Container hosting | Azure Container Apps or AKS |
| VM compute | Azure Virtual Machines |
| Managed database | Azure Database for PostgreSQL / SQL |
| Redis cache | Azure Cache for Redis |
| Object storage | Azure Blob Storage |
| CDN | Azure CDN / Front Door |
| Load balancer | Azure Load Balancer / Application Gateway |
| Message queue | Azure Service Bus or Storage Queues |
| DNS | Azure DNS |
| Secrets | Azure Key Vault |
| Registry | Azure Container Registry |
| Identity | Azure AD / Entra ID |

**Common patterns:**
- Web app: Application Gateway → Container Apps → Azure DB + Redis + Blob
- API-only: API Management → Container Apps → Azure DB
- Enterprise (existing AD): leverage Entra ID for SSO + managed identities throughout

---

## `/arch hetzner`

Plan Hetzner Cloud infrastructure for a workload.

**Best for:** Budget-conscious projects, European data residency, dev/staging environments, self-hosted workloads, projects with predictable traffic.

**Interview:**
1. What is the workload and expected scale?
2. Need managed Kubernetes (Hetzner supports K3s) or Docker Compose?
3. Data residency? (Hetzner: Germany, Finland, USA)
4. Budget target?

**Output:**
- **Server sizing:** CX (shared) vs CCX (dedicated) instance types
- **Architecture diagram**
- **Networking:** private networks, firewalls, floating IPs
- **Cost estimate:** typically 5-10x cheaper than AWS/GCP for equivalent resources

**Service mapping:**

| Need | Hetzner Service |
|------|----------------|
| VMs | Cloud Servers (CX/CCX series) |
| Kubernetes | Self-managed K3s on Cloud Servers |
| Managed DB | Managed Databases (PostgreSQL, MySQL, Redis) |
| Object storage | Object Storage (S3-compatible) |
| Block storage | Volumes |
| Load balancer | Load Balancers |
| Firewall | Cloud Firewalls |
| DNS | Hetzner DNS (free) |
| Private network | Private Networks |

**Common patterns:**
- Small web app: Load Balancer → 2x CX servers (Docker Compose) → Managed PostgreSQL + Redis
- K3s cluster: 3x CCX servers + K3s + Hetzner CSI driver for volumes
- Cost-optimised staging: CX11 (€4/mo) + Managed DB starter

**Rules:**
- Use private networks for all inter-service communication
- Hetzner Object Storage is S3-compatible — use the same SDK
- For K8s: use Hetzner Cloud Controller Manager + CSI driver
- No managed K8s service — self-manage K3s or use Rancher

---

## `/arch hostinger`

Plan Hostinger infrastructure for a workload.

**Best for:** Small-to-medium PHP/WordPress sites, budget hosting, projects where managed simplicity outweighs control, early-stage products.

**Interview:**
1. What type of application? (PHP/Laravel, WordPress, Node.js, static)
2. Expected monthly traffic?
3. Database needs?
4. Budget target?

**Output:**
- **Plan recommendation:** Shared / Cloud / VPS / Business
- **Architecture overview**
- **Deployment approach**
- **Limitations to be aware of**

**Service mapping:**

| Need | Hostinger Option |
|------|----------------|
| PHP hosting | Shared / Cloud Hosting plans |
| Custom stack | KVM VPS (root access, Docker supported) |
| Database | MySQL/MariaDB (managed, included) |
| Object storage | Not native — use Cloudflare R2 or Backblaze B2 |
| CDN | Cloudflare (free tier) in front of Hostinger |
| Email | Hostinger Email or external (Postmark, SES) |
| SSL | Free Let's Encrypt via hPanel |
| DNS | Hostinger DNS or Cloudflare |

**Common patterns:**
- Laravel app: KVM VPS + Docker Compose + Cloudflare CDN + external S3-compatible storage
- WordPress: Shared/Cloud Hosting plan + Hostinger MySQL + Cloudflare
- Static site: Shared hosting or use Cloudflare Pages instead

**Limitations vs full cloud:**
- No native object storage — must use external provider
- No managed Kubernetes
- VPS requires self-management (updates, monitoring, backups)
- Not suited for auto-scaling or high-availability multi-region setups

**Rules:**
- Always put Cloudflare in front for CDN, DDoS protection, and SSL management
- Use KVM VPS (not OpenVZ) for Docker support
- Set up automated backups — Hostinger backups are not a substitute for a backup strategy
- For production Laravel: use queue workers via `supervisor` on VPS

---

## `/arch api`

Design a REST or GraphQL API.

**Interview:**
1. What resources does the API expose?
2. Who are the consumers? (internal frontend, mobile, third-party)
3. REST or GraphQL? (default: REST unless clear benefit to GraphQL)
4. Authentication method? (Sanctum, Passport, JWT, API key)
5. Any versioning requirements?

**Output:**
- Resource list with CRUD operations
- Endpoint table: `METHOD /path` → description → request/response shape
- Auth strategy and middleware
- Error response format (consistent across all endpoints)
- Versioning strategy (URL prefix `/v1/` default)
- Pagination approach (cursor-based default for large collections)

**Rules:**
- Use nouns for resources, never verbs in URLs
- Consistent error envelope: `{ message, errors, code }`
- 422 for validation, 401 for unauthenticated, 403 for unauthorised
- No business logic in controllers — delegate to Actions/Services

---

## `/arch review`

Review and critique an existing architecture.

**Input:** Description, diagram, or codebase path.

**Output:**
- **Strengths:** what the current design does well
- **Risks:** scalability, security, maintainability concerns
- **Single points of failure:** components with no redundancy
- **Coupling issues:** tight coupling that limits change
- **Recommendations:** prioritised list of improvements with effort/impact

---

## Trigger Phrases

`design the architecture`, `system design`, `how should we structure this`,
`create an ADR`, `architecture decision`, `plan AWS infra`, `AWS setup`,
`plan GCP infra`, `GCP setup`, `Google Cloud`, `Cloud Run`, `GKE`,
`plan Azure infra`, `Azure setup`, `AKS`, `Container Apps`,
`Hetzner setup`, `Hetzner Cloud`, `K3s`, `budget hosting`,
`Hostinger setup`, `Hostinger VPS`,
`design the API`, `API structure`, `REST API design`, `GraphQL schema`,
`review this architecture`, `architecture critique`, `tech stack decision`

---

## Anti-Patterns

| Anti-Pattern | Correct Approach |
|---|---|
| Fat controllers with business logic | Controllers dispatch to Actions/Services |
| Single monolithic DB for all workloads | Right-size storage per access pattern |
| Public subnets for databases | Databases always in private subnets / private networks |
| Hardcoded credentials in code | Secrets Manager / Key Vault / Secret Manager |
| No API versioning from day one | Always prefix with `/v1/` from launch |
| Synchronous calls for non-critical work | Offload to queues |
| ADR written after decision is irreversible | Write ADR at decision time, not after |
| Choosing AWS by default | Evaluate Hetzner/Hostinger for cost-sensitive or EU workloads |
| Over-engineering for scale that doesn't exist | Start simple (VPS + managed DB), scale when needed |

---

## References

| File | Purpose |
|------|---------|
| `references/adr-template.md` | ADR document structure and status lifecycle |
| `references/aws-patterns.md` | AWS architecture patterns for web/API workloads |
| `references/gcp-patterns.md` | GCP service mapping, Cloud Run and GKE patterns |
| `references/azure-patterns.md` | Azure service mapping, AKS and Container Apps patterns |
| `references/hetzner-patterns.md` | Hetzner Cloud setup, K3s, cost optimisation |
| `references/hostinger-patterns.md` | Hostinger VPS and shared hosting deployment patterns |
| `references/api-design.md` | REST API conventions, error formats, pagination patterns |
