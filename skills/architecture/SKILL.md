---
name: architecture
metadata:
  compatible_agents: [claude-code]
  tags: [architecture, aws, laravel, typescript, vue, api, adr, system-design]
description: >
  System architecture assistant for CTOs and technical leads working with
  Laravel, TypeScript, Vue, and AWS. Designs systems, creates ADRs, plans
  AWS infrastructure, designs APIs, and reviews existing architecture.
  Trigger with: "design the architecture", "create an ADR", "plan AWS infra",
  "design the API", "review this architecture", "how should we structure this".
---

## Commands

| Command | Description |
|---------|-------------|
| `/arch design` | Design system architecture for a product or feature |
| `/arch adr` | Create an Architecture Decision Record |
| `/arch aws` | Plan AWS infrastructure for a workload |
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
- **Stack decisions:** Laravel, Vue/TS, AWS services, databases, queues
- **Trade-offs:** what this design optimises for and what it sacrifices
- **Open questions:** decisions that need more information

**Stack defaults (unless overridden):**
- Backend: Laravel (PHP 8.3+)
- Frontend: Vue 3 + TypeScript + Vite
- Database: RDS PostgreSQL or MySQL
- Queue: SQS + Laravel Horizon
- Cache: ElastiCache Redis
- Storage: S3
- Hosting: ECS Fargate or EC2 + ALB
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
- **Terraform module structure:** suggested layout for `references/terraform-patterns.md`

**Common patterns:**
- Web app: ALB → ECS Fargate → RDS + ElastiCache + S3
- API-only: API Gateway → Lambda or ECS → RDS
- Async workload: SQS → Lambda/ECS worker → RDS/DynamoDB
- Static frontend: CloudFront → S3

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
`design the API`, `API structure`, `REST API design`, `GraphQL schema`,
`review this architecture`, `architecture critique`, `tech stack decision`

---

## Anti-Patterns

| Anti-Pattern | Correct Approach |
|---|---|
| Fat controllers with business logic | Controllers dispatch to Actions/Services |
| Single monolithic RDS for all workloads | Right-size storage per access pattern |
| Public subnets for databases | Databases always in private subnets |
| Hardcoded credentials in code | Secrets Manager or Parameter Store |
| No API versioning from day one | Always prefix with `/v1/` from launch |
| Synchronous calls for non-critical work | Offload to queues (SQS + Horizon) |
| ADR written after decision is irreversible | Write ADR at decision time, not after |

---

## References

| File | Purpose |
|------|---------|
| `references/adr-template.md` | ADR document structure and status lifecycle |
| `references/aws-patterns.md` | Common AWS architecture patterns for web/API workloads |
| `references/api-design.md` | REST API conventions, error formats, pagination patterns |
