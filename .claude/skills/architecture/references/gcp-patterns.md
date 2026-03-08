# GCP Patterns Reference

## Service Equivalents (AWS → GCP)

| AWS | GCP | Notes |
|-----|-----|-------|
| EC2 | Compute Engine | Similar VM offering |
| ECS Fargate | Cloud Run | Serverless containers, pay-per-request |
| EKS | GKE | Managed Kubernetes — GKE is more mature |
| Lambda | Cloud Functions | Serverless functions |
| RDS | Cloud SQL | PostgreSQL, MySQL, SQL Server |
| ElastiCache | Memorystore | Valkey (preferred) or Memcached |
| S3 | Cloud Storage (GCS) | S3-compatible API available |
| CloudFront | Cloud CDN | Integrated with Cloud Load Balancing |
| ALB | Cloud Load Balancing | Global HTTP(S) LB |
| SQS | Pub/Sub or Cloud Tasks | Pub/Sub = fan-out; Tasks = task queue |
| Route 53 | Cloud DNS | |
| Secrets Manager | Secret Manager | |
| ECR | Artifact Registry | Also supports Maven, npm, etc. |
| IAM | IAM + Service Accounts | Service accounts for workload identity |
| CloudWatch | Cloud Monitoring + Logging | |
| VPC | VPC | Auto-mode vs custom-mode VPC |

---

## Web App Architecture (Cloud Run)

```
Internet
  │
  ▼
Cloud Load Balancing (HTTPS + SSL cert)
  │
  ▼
Cloud Run (Laravel app — auto-scales to zero)
  │
  ├── Cloud SQL (PostgreSQL — private IP)
  ├── Memorystore for Valkey (private IP)
  └── Cloud Storage (GCS) ← static assets, uploads
```

**Terraform provider:**
```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
```

---

## Cloud Run Setup

```hcl
resource "google_cloud_run_v2_service" "app" {
  name     = "${var.project}-app"
  location = var.region

  template {
    service_account = google_service_account.app.email

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repo}/app:${var.image_tag}"

      env {
        name  = "APP_ENV"
        value = "production"
      }
      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }
  }
}
```

---

## GKE Setup (for larger workloads)

```hcl
resource "google_container_cluster" "primary" {
  name     = "${var.project}-cluster"
  location = var.region

  # Use autopilot for managed node pools
  enable_autopilot = true

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}
```

---

## Networking Baseline

```hcl
resource "google_compute_network" "vpc" {
  name                    = "${var.project}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private" {
  name          = "${var.project}-private"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id

  private_ip_google_access = true  # access GCP APIs without public IP
}

resource "google_compute_router" "router" {
  name    = "${var.project}-router"
  network = google_compute_network.vpc.id
  region  = var.region
}

resource "google_compute_router_nat" "nat" {
  name   = "${var.project}-nat"
  router = google_compute_router.router.name
  region = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
```

---

## IAM — Service Accounts (Least Privilege)

```hcl
# App service account
resource "google_service_account" "app" {
  account_id   = "${var.project}-app"
  display_name = "Application Service Account"
}

# Grant only what the app needs
resource "google_project_iam_member" "app_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.app.email}"
}

resource "google_project_iam_member" "app_storage" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.app.email}"
}

resource "google_project_iam_member" "app_secrets" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.app.email}"
}

# Workload identity — link K8s SA to GCP SA
resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = google_service_account.app.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace}/${var.k8s_sa}]"
}
```

---

## Cloud SQL

```hcl
resource "google_sql_database_instance" "primary" {
  name             = "${var.project}-db"
  database_version = "POSTGRES_16"
  region           = var.region

  settings {
    tier              = var.db_tier  # "db-f1-micro" → "db-custom-4-16384"
    availability_type = var.env == "prod" ? "REGIONAL" : "ZONAL"
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled    = false  # no public IP
      private_network = google_compute_network.vpc.id
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7
      }
    }

    insights_config {
      query_insights_enabled = true
    }
  }

  deletion_protection = var.env == "prod"
}
```

---

## Cost Optimisation Tips

- **Cloud Run** scales to zero — ideal for low-traffic apps, pay only for requests
- **Preemptible/Spot VMs** for batch workloads — up to 91% cheaper
- **Committed use discounts** — 1 or 3 year for predictable workloads (up to 57% off)
- **Cloud Storage** classes: Standard → Nearline → Coldline → Archive as access frequency drops
- **GKE Autopilot** vs Standard: Autopilot charges per pod, not per node — better for variable workloads
- Use `europe-west4` (Netherlands) or `europe-west3` (Frankfurt) for EU data residency
