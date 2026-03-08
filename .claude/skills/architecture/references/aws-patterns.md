# AWS Architecture Patterns

## Web Application (Standard)

```
Internet → Route 53 → CloudFront → ALB → ECS Fargate (Laravel)
                                         ↓
                                    ElastiCache (Redis)
                                    RDS PostgreSQL (private subnet)
                                    S3 (assets/uploads)
                                    SQS → ECS Worker (Horizon)
```

**Use when:** Laravel monolith or API + Vue SPA.

---

## Networking Baseline

```
VPC (10.0.0.0/16)
├── Public Subnets (10.0.1.0/24, 10.0.2.0/24)  — ALB, NAT Gateway
├── Private Subnets (10.0.3.0/24, 10.0.4.0/24) — ECS, RDS, ElastiCache
└── AZs: minimum 2 for HA
```

**Rules:**
- Databases always in private subnets
- ECS tasks in private subnets, outbound via NAT
- ALB in public subnets only
- Security groups: least privilege, no `0.0.0.0/0` on private resources

---

## ECS Fargate Task Sizing

| Workload | CPU | Memory |
|----------|-----|--------|
| Laravel web (low) | 256 | 512 MB |
| Laravel web (med) | 512 | 1 GB |
| Laravel web (high) | 1024 | 2 GB |
| Horizon worker | 512 | 1 GB |
| Scheduler | 256 | 512 MB |

---

## RDS Sizing

| Environment | Instance | Multi-AZ |
|-------------|----------|----------|
| dev | db.t3.micro | No |
| staging | db.t3.small | No |
| prod | db.t3.medium+ | Yes |

---

## S3 Bucket Policy Pattern

- Public assets: CloudFront Origin Access Control → S3 (block all public access)
- User uploads: presigned URLs, never public
- Terraform state: versioning + server-side encryption + block public access

---

## IAM Least Privilege Pattern

ECS Task Role — only what the app needs:
```json
{
  "Effect": "Allow",
  "Action": ["s3:GetObject", "s3:PutObject"],
  "Resource": "arn:aws:s3:::my-bucket/*"
}
```

Never use `*` actions or `*` resources in task roles.

---

## Secrets Management

- App secrets: AWS Secrets Manager (injected as env vars into ECS)
- Config values: SSM Parameter Store (SecureString for sensitive)
- Never store secrets in: `.env` committed to git, SSM plaintext, ECS task definition env literals

---

## Cost Optimisation

- Dev/staging: schedule scale-down outside business hours
- Use Spot for non-critical workers (Horizon, batch jobs)
- CloudFront in front of everything — reduces origin load
- RDS: use `db.t4g` (Graviton) instances — same perf, ~20% cheaper
