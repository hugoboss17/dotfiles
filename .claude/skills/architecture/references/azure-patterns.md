# Azure Patterns Reference

## Service Equivalents (AWS → Azure)

| AWS | Azure | Notes |
|-----|-------|-------|
| EC2 | Azure Virtual Machines | |
| ECS Fargate | Azure Container Apps | Serverless containers |
| EKS | AKS (Azure Kubernetes Service) | |
| Lambda | Azure Functions | |
| RDS | Azure Database for PostgreSQL/MySQL | Flexible Server preferred |
| ElastiCache | Azure Cache for Redis | |
| S3 | Azure Blob Storage | |
| CloudFront | Azure CDN / Azure Front Door | Front Door = global + WAF |
| ALB | Application Gateway | |
| SQS | Azure Service Bus | Service Bus = enterprise; Storage Queues = simple |
| Route 53 | Azure DNS | |
| Secrets Manager | Azure Key Vault | |
| ECR | Azure Container Registry (ACR) | |
| IAM | Azure RBAC + Entra ID | |
| CloudWatch | Azure Monitor + Log Analytics | |
| VPC | Virtual Network (VNet) | |

---

## Web App Architecture (Container Apps)

```
Internet
  │
  ▼
Azure Front Door (global CDN + WAF + SSL)
  │
  ▼
Azure Container Apps (Laravel app — auto-scales)
  │
  ├── Azure Database for PostgreSQL Flexible Server (private endpoint)
  ├── Azure Cache for Redis (private endpoint)
  └── Azure Blob Storage ← static assets, uploads
```

**Terraform provider:**
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
```

---

## Resource Group and Naming

```hcl
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.env}"
  location = var.location  # "westeurope", "northeurope", "eastus2"

  tags = {
    Environment = var.env
    Project     = var.project
    ManagedBy   = "terraform"
  }
}
```

**Naming convention:** `{type}-{project}-{env}-{region}`
- Resource group: `rg-myapp-prod-we`
- Container App: `ca-myapp-prod`
- Key Vault: `kv-myapp-prod` (max 24 chars)

---

## Azure Container Apps

```hcl
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.project}-${var.env}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}

resource "azurerm_container_app" "app" {
  name                         = "ca-${var.project}-${var.env}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "app"
      image  = "${azurerm_container_registry.main.login_server}/app:${var.image_tag}"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }
    }

    min_replicas = 1
    max_replicas = 10

    http_scale_rule {
      name                = "http-rule"
      concurrent_requests = 100
    }
  }

  secret {
    name  = "db-password"
    value = azurerm_key_vault_secret.db_password.value
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
```

---

## AKS (for larger workloads)

```hcl
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.project}-${var.env}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.project}-${var.env}"

  default_node_pool {
    name           = "system"
    node_count     = 2
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  workload_identity_enabled         = true
  oidc_issuer_enabled               = true
}
```

---

## IAM — Managed Identity (Least Privilege)

```hcl
# Assign Key Vault access to Container App
resource "azurerm_role_assignment" "app_keyvault" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_container_app.app.identity[0].principal_id
}

# Assign Blob Storage access
resource "azurerm_role_assignment" "app_storage" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_container_app.app.identity[0].principal_id
}

# Assign ACR pull access
resource "azurerm_role_assignment" "app_acr" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app.app.identity[0].principal_id
}
```

---

## Key Vault

```hcl
resource "azurerm_key_vault" "main" {
  name                = "kv-${var.project}-${var.env}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enable_rbac_authorization = true  # use RBAC, not access policies
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.env == "prod"
}
```

---

## Networking (VNet + Private Endpoints)

```hcl
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project}-${var.env}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "private" {
  name                 = "snet-private"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  private_endpoint_network_policies = "Disabled"
}
```

---

## Cost Optimisation Tips

- **Azure Container Apps** — pay per vCPU-second and GiB-second; scales to zero for dev
- **Reserved Instances** — 1 or 3 year for VMs/AKS nodes: up to 72% savings
- **Spot VMs** for batch/interruptible workloads — up to 90% cheaper
- **Azure Hybrid Benefit** — use existing Windows Server / SQL Server licences
- **Flexible Server PostgreSQL** — cheaper than Single Server, supports stop/start for dev
- Use `westeurope` (Netherlands) or `northeurope` (Ireland) for EU data residency
- Set budget alerts in Azure Cost Management — mandatory for every subscription
