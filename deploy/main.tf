terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  storage_use_azuread = true
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Get deployer IP to allow Key Vault access from your machine
data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}

data "azurerm_client_config" "current" {}

# Register EncryptionAtHost feature (required for VMs)
resource "azapi_update_resource" "allow_encryption_at_host" {
  resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.Compute/subscriptionFeatureRegistrations/EncryptionAtHost"
  type        = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = {
    properties = {}
  }
}

module "vm_sku" {
  source  = "Azure/avm-utl-sku-finder/azapi"
  version = "0.3.0"

  location      = var.location
  cache_results = true
  vm_filters = {
    cpu_architecture_type          = "x64"
    min_vcpus                      = 2
    max_vcpus                      = 2
    encryption_at_host_supported   = true
    accelerated_networking_enabled = true
    premium_io_supported           = true
  }
}

module "landing_zone" {
  source = "../"

  location            = var.location
  resource_group_name = var.resource_group_name
  name_prefix         = var.name_prefix
  tags                = var.tags
  enable_telemetry    = false

  # Standalone mode — no hub/spoke integration
  flag_platform_landing_zone = false

  # --- Networking (lightweight for PoC) ---
  vnet_definition = {
    address_space = ["192.168.0.0/20"] # Must be within 192.168.0.0/16 for Foundry capabilityHost injection
  }
  bastion_definition = {
    deploy = false # No portal access, so Bastion is not usable
  }
  firewall_definition = {
    deploy = false # Skip firewall for PoC (~$900/mo savings)
  }
  nat_gateway_definition = {
    deploy = true # Provides outbound internet without firewall
  }
  app_gateway_definition = {
    deploy = false
    # Required attributes even when deploy=false due to variable type constraints
    backend_address_pools = {
      default = { name = "default" }
    }
    backend_http_settings = {
      default = { name = "default", port = 80, protocol = "Http" }
    }
    frontend_ports = {
      default = { name = "default", port = 80 }
    }
    http_listeners = {
      default = { name = "default", frontend_port_name = "default" }
    }
    request_routing_rules = {
      default = {
        name                       = "default"
        rule_type                  = "Basic"
        http_listener_name         = "default"
        backend_address_pool_name  = "default"
        backend_http_settings_name = "default"
        priority                   = 100
      }
    }
  }
  use_internet_routing = true # Direct internet routing (no firewall)

  # --- AI Foundry ---
  ai_foundry_definition = {
    purge_on_destroy = true # Easy cleanup for PoC
    ai_foundry = {
      create_ai_agent_service       = true
      enable_diagnostic_settings    = false
      public_network_access_enabled = true
    }
    ai_model_deployments = {
      "gpt-4.1" = {
        name = "gpt-4.1"
        model = {
          format  = "OpenAI"
          name    = "gpt-4.1"
          version = "2025-04-14"
        }
        scale = {
          type     = "GlobalStandard"
          capacity = 1
        }
      }
    }
    ai_projects = {
      poc = {
        name                       = "poc-project"
        description                = "Proof of concept project"
        display_name               = "PoC Project"
        create_project_connections = true
        cosmos_db_connection = {
          new_resource_map_key = "this"
        }
        ai_search_connection = {
          new_resource_map_key = "this"
        }
        storage_account_connection = {
          new_resource_map_key = "this"
        }
      }
    }
    ai_search_definition = {
      this = {}
    }
    cosmosdb_definition = {
      this = {
        consistency_level = "Session"
      }
    }
    key_vault_definition = {
      this = {}
    }
    storage_account_definition = {
      this = {
        shared_access_key_enabled = true
        endpoints = {
          blob = {
            type = "blob"
          }
        }
      }
    }
    buildvm_definition = {
      sku = module.vm_sku.sku
    }
  }

  # --- APIM (disabled for PoC) ---
  apim_definition = {
    deploy          = false
    publisher_email = "noreply@example.com"
    publisher_name  = "PoC"
  }

  # --- GenAI supporting services ---
  genai_key_vault_definition = {
    public_network_access_enabled = true # Allow access from deployer machine
    network_acls = {
      bypass   = "AzureServices"
      ip_rules = ["${data.http.ip.response_body}/32"]
    }
  }
  genai_cosmosdb_definition = {
    consistency_level = "Session"
  }
  genai_container_registry_definition = {
    enable_diagnostic_settings = false
  }
  genai_app_configuration_definition = {
    enable_diagnostic_settings = false
  }
  genai_storage_account_definition = {}
  container_app_environment_definition = {
    enable_diagnostic_settings = false
  }

  # --- Knowledge sources ---
  ks_ai_search_definition = {
    enable_diagnostic_settings = false
  }

  # --- NSG rules: whitelist RDP from allowed IPs ---
  nsgs_definition = {
    security_rules = {
      allow_rdp_whitelisted = {
        name                       = "Allow-RDP-Whitelisted"
        access                     = "Allow"
        direction                  = "Inbound"
        priority                   = 100
        protocol                   = "Tcp"
        source_address_prefixes    = toset(var.allowed_ips)
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_range     = "3389"
      }
      deny_rdp_all = {
        name                       = "Deny-RDP-All"
        access                     = "Deny"
        direction                  = "Inbound"
        priority                   = 200
        protocol                   = "Tcp"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_range     = "3389"
      }
    }
  }

  # --- VMs ---
  jumpvm_definition = {
    deploy = false
    sku    = module.vm_sku.sku
  }
  buildvm_definition = {
    deploy = false # Skip build VM for PoC
  }
}


