# Terraform Patterns

## Directory Structure

```
terraform/
├── providers.tf          # AWS provider, versions
├── backend.tf            # S3 + DynamoDB state
├── main.tf               # Root module: calls child modules
├── variables.tf          # Input variables
├── outputs.tf            # Outputs
├── locals.tf             # Computed locals (tags, name prefixes)
│
├── modules/
│   ├── networking/       # VPC, subnets, SGs, NAT, IGW
│   ├── compute/          # ECS cluster, task defs, ALB, auto-scaling
│   ├── database/         # RDS, param group, subnet group, SG
│   ├── cache/            # ElastiCache Redis
│   └── storage/          # S3 buckets, policies, CloudFront
│
└── envs/
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

---

## Backend Configuration

```hcl
terraform {
  backend "s3" {
    bucket         = "[project]-terraform-state"
    key            = "[env]/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "[project]-terraform-locks"
    encrypt        = true
  }
}
```

---

## Tagging Strategy (locals.tf)

```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
  }
}
```

Apply to every resource: `tags = local.common_tags`

---

## Module Interface Pattern

Each module exposes:

```hcl
# modules/networking/variables.tf
variable "project_name" { type = string }
variable "environment"  { type = string }
variable "vpc_cidr"     { type = string, default = "10.0.0.0/16" }

# modules/networking/outputs.tf
output "vpc_id"             { value = aws_vpc.main.id }
output "private_subnet_ids" { value = aws_subnet.private[*].id }
output "public_subnet_ids"  { value = aws_subnet.public[*].id }
```

---

## ECS Task Definition Pattern

```hcl
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "app"
    image = var.container_image
    portMappings = [{ containerPort = 80, protocol = "tcp" }]
    secrets = [
      { name = "APP_KEY", valueFrom = aws_secretsmanager_secret.app_key.arn }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"  = "/ecs/${var.project_name}-${var.environment}"
        "awslogs-region" = var.aws_region
      }
    }
  }])
}
```

---

## Common Rules

- Use `for_each` over `count` when resources have individual identity
- Never use `terraform destroy` in CI — only `apply`
- Sensitive outputs: `sensitive = true`
- Remote state cross-references: `data "terraform_remote_state"`
- Lock provider versions: `version = "~> 5.0"` — never `>=`
