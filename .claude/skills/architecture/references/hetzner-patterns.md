# Hetzner Cloud Patterns Reference

## Why Hetzner

- **Price/performance:** 5-10x cheaper than AWS/GCP/Azure for equivalent compute
- **EU data residency:** Servers in Germany (NBG, FSN, HEL) and Finland (HEL)
- **Simple pricing:** flat monthly rates, no egress fees within Europe
- **S3-compatible storage:** Object Storage works with existing S3 SDKs
- **Best for:** startups, cost-sensitive workloads, EU-compliant projects, dev/staging

---

## Server Sizing

| Type | vCPU | RAM | Price/mo | Use case |
|------|------|-----|----------|----------|
| CX22 | 2 (shared) | 4 GB | ~€4.5 | Dev, small apps |
| CX32 | 4 (shared) | 8 GB | ~€8.5 | Staging, small prod |
| CX42 | 8 (shared) | 16 GB | ~€17 | Medium prod |
| CCX13 | 2 (dedicated) | 8 GB | ~€13 | Production DB |
| CCX23 | 4 (dedicated) | 16 GB | ~€24 | Production app |
| CCX33 | 8 (dedicated) | 32 GB | ~€48 | Heavy workloads |

**Rule:** Use CX (shared) for apps, CCX (dedicated) for databases and CPU-sensitive workloads.

---

## Terraform Provider

```hcl
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}
```

---

## Basic Web App (Docker Compose)

```
Internet
  │
  ▼
Hetzner Load Balancer (€6/mo)
  │
  ├── App Server 1 (CX32) — Docker Compose
  └── App Server 2 (CX32) — Docker Compose
        │
        ├── Managed PostgreSQL (€20/mo)
        ├── Managed Redis (€15/mo)
        └── Object Storage (€6/mo per TB)
```

**Total:** ~€55/mo for a highly available setup (vs ~$300+/mo on AWS)

---

## Server + Firewall Setup

```hcl
resource "hcloud_server" "app" {
  count       = var.app_count
  name        = "${var.project}-app-${count.index + 1}"
  server_type = "cx32"
  image       = "ubuntu-24.04"
  location    = "nbg1"  # nbg1, fsn1, hel1, ash (USA)
  ssh_keys    = [hcloud_ssh_key.main.id]
  network {
    network_id = hcloud_network.main.id
  }
  user_data = file("${path.module}/cloud-init.yml")
}

resource "hcloud_firewall" "app" {
  name = "${var.project}-app-fw"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = var.admin_ips  # SSH from known IPs only
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_firewall_attachment" "app" {
  firewall_id = hcloud_firewall.app.id
  server_ids  = hcloud_server.app[*].id
}
```

---

## Private Network

```hcl
resource "hcloud_network" "main" {
  name     = "${var.project}-network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "private" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}
```

---

## Load Balancer

```hcl
resource "hcloud_load_balancer" "main" {
  name               = "${var.project}-lb"
  load_balancer_type = "lb11"  # lb11 (€6), lb21, lb31
  location           = "nbg1"
  network_id         = hcloud_network.main.id
}

resource "hcloud_load_balancer_service" "http" {
  load_balancer_id = hcloud_load_balancer.main.id
  protocol         = "http"
  listen_port      = 80
  destination_port = 8080
  health_check {
    protocol = "http"
    port     = 8080
    interval = 15
    timeout  = 10
    http {
      path         = "/health"
      status_codes = ["200"]
    }
  }
}

resource "hcloud_load_balancer_target" "app" {
  count            = var.app_count
  type             = "server"
  load_balancer_id = hcloud_load_balancer.main.id
  server_id        = hcloud_server.app[count.index].id
  use_private_ip   = true
}
```

---

## Managed Databases

```hcl
resource "hcloud_managed_database" "postgres" {
  name     = "${var.project}-db"
  type     = "pg"
  plan     = "startup-4"  # startup-4, startup-8, business-4, premium-8
  location = "nbg1"
  version  = "16"
}

resource "hcloud_managed_database" "redis" {
  name     = "${var.project}-redis"
  type     = "redis"
  plan     = "startup-4"
  location = "nbg1"
}
```

---

## K3s Cluster Setup

```hcl
# 3-node K3s cluster
resource "hcloud_server" "k3s_master" {
  name        = "${var.project}-k3s-master"
  server_type = "cx32"
  image       = "ubuntu-24.04"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.main.id]
  network { network_id = hcloud_network.main.id }
}

resource "hcloud_server" "k3s_worker" {
  count       = 2
  name        = "${var.project}-k3s-worker-${count.index + 1}"
  server_type = "cx32"
  image       = "ubuntu-24.04"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.main.id]
  network { network_id = hcloud_network.main.id }
}
```

**K3s installation (cloud-init):**
```yaml
#cloud-config
package_update: true
packages: [curl, fail2ban, ufw]
runcmd:
  # Master
  - curl -sfL https://get.k3s.io | sh -s - --disable traefik --disable servicelb
  # Workers (use token from master: /var/lib/rancher/k3s/server/node-token)
  # - curl -sfL https://get.k3s.io | K3S_URL=https://MASTER_IP:6443 K3S_TOKEN=TOKEN sh -
```

**Required Helm charts for K3s on Hetzner:**
- `hcloud-cloud-controller-manager` — Hetzner Cloud integration
- `hcloud-csi-driver` — persistent volumes from Hetzner Volumes
- `cert-manager` — TLS certificates
- `ingress-nginx` or Traefik — ingress controller

---

## Object Storage (S3-compatible)

```bash
# Endpoint: https://<location>.your-objectstorage.com
# Location: nbg1, fsn1, hel1

# Configure in .env
S3_ENDPOINT=https://nbg1.your-objectstorage.com
S3_BUCKET=my-bucket
S3_KEY=access-key
S3_SECRET=secret-key
S3_REGION=eu-central-1  # any value works
```

```php
// Laravel filesystems.php
's3' => [
    'driver'   => 's3',
    'key'      => env('S3_KEY'),
    'secret'   => env('S3_SECRET'),
    'region'   => env('S3_REGION', 'eu-central-1'),
    'bucket'   => env('S3_BUCKET'),
    'endpoint' => env('S3_ENDPOINT'),
    'use_path_style_endpoint' => true,
],
```

---

## Cost Optimisation Tips

- **Snapshots:** €0.012/GB/mo — cheap for server snapshots before migrations
- **Floating IPs:** €1.19/mo — assign to load balancer, not individual servers
- **Volumes:** €0.052/GB/mo — attach to servers for persistent storage
- **Traffic:** first 20TB/mo free within Germany/Finland; €1.19/TB after
- Always use private network for inter-service communication (no egress cost)
- Use Hetzner DNS (free) — no need for external DNS provider
