terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116, < 5.0"
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
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.2"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

# Get the deployer IP address to allow for public write to the key vault. This is to make sure the tests run.
# In practice your deployer machine will be on a private network and this will not be required.
data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}

locals {
  location            = var.location
  resource_group_name = "ai-lz-rg-standalone-${substr(module.naming.unique-seed, 0, 5)}"
}

data "azurerm_client_config" "current" {}

module "vm_sku" {
  source  = "Azure/avm-utl-sku-finder/azapi"
  version = "0.3.0"

  location      = local.location
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

module "test" {
  source = "../../"

  location            = local.location
  resource_group_name = local.resource_group_name
  #resource_group_name = "ai-lz-rg-default-ivrhi-3"
  vnet_definition = {
    name          = "ai-lz-vnet-standalone"
    address_space = ["192.168.0.0/20"] # has to be out of 192.168.0.0/16 currently. Other RFC1918 not supported for foundry capabilityHost injection.
  }
  ai_foundry_definition = {
    create_private_endpoints = false
    purge_on_destroy         = true
    ai_foundry = {
      create_ai_agent_service    = true
      enable_diagnostic_settings = false
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
      "text-embedding-ada-002" = {
        name = "text-embedding-ada-002"
        model = {
          format  = "OpenAI"
          name    = "text-embedding-ada-002"
          version = "2"
        }
        scale = {
          type     = "Standard"
          capacity = 120
        }
      }
    }

    ai_projects = {
      project_1 = {
        name                       = "project-1"
        description                = "Project 1 description"
        display_name               = "Project 1 Display Name"
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
      this = {
      }
    }

    buildvm_definition = {
      sku = module.vm_sku.sku
    }

    cosmosdb_definition = {
      this = {
        consistency_level             = "Session"
        public_network_access_enabled = true
      }
    }

    key_vault_definition = {
      this = {
      }
    }

    storage_account_definition = {
      this = {
        shared_access_key_enabled = true #configured for testing
        endpoints = {
          blob = {
            type = "blob"
          }
        }
      }
    }
  }
  apim_definition = {
    publisher_email = "DoNotReply@exampleEmail.com"
    publisher_name  = "Azure API Management"
  }
  app_gateway_definition = {
    backend_address_pools = {
      example_pool = {
        name = "example-backend-pool"
      }
    }

    backend_http_settings = {
      example_http_settings = {
        name     = "example-http-settings"
        port     = 80
        protocol = "Http"
      }
    }

    frontend_ports = {
      example_frontend_port = {
        name = "example-frontend-port"
        port = 80
      }
    }

    http_listeners = {
      example_listener = {
        name               = "example-listener"
        frontend_port_name = "example-frontend-port"
      }
    }

    request_routing_rules = {
      example_rule = {
        name                       = "example-rule"
        rule_type                  = "Basic"
        http_listener_name         = "example-listener"
        backend_address_pool_name  = "example-backend-pool"
        backend_http_settings_name = "example-http-settings"
        priority                   = 100
      }
    }
  }
  bastion_definition = {
    deploy = false
  }
  container_app_environment_definition = {
    enable_diagnostic_settings = false
  }
  enable_telemetry           = var.enable_telemetry
  flag_platform_landing_zone = false
  jumpvm_definition = {
    deploy = false
    sku    = module.vm_sku.sku
  }
  nat_gateway_definition = {
    deploy = true
  }
  genai_app_configuration_definition = {
    enable_diagnostic_settings    = false
    public_network_access_enabled = true
  }
  genai_container_registry_definition = {
    enable_diagnostic_settings    = false
    public_network_access_enabled = true
  }
  genai_cosmosdb_definition = {
    consistency_level             = "Session"
    public_network_access_enabled = true
  }
  genai_key_vault_definition = {
    public_network_access_enabled = true
    network_acls = {
      bypass   = "AzureServices"
      ip_rules = ["${data.http.ip.response_body}/32"]
    }
  }
  genai_storage_account_definition = {
    public_network_access_enabled = true
  }
  ks_ai_search_definition = {
    enable_diagnostic_settings    = false
    public_network_access_enabled = true
  }
}

# --- Data sources for existing resources ---

data "azurerm_cognitive_account" "ai_services" {
  name                = module.test.ai_services_name
  resource_group_name = local.resource_group_name
}

# --- PostgreSQL Flexible Server ---

resource "random_password" "postgresql" {
  length  = 32
  special = true
}

module "postgresql" {
  source  = "Azure/avm-res-dbforpostgresql-flexibleserver/azurerm"
  version = "0.2.2"

  name                = "ai-alz-pg-${module.test.name_suffix}"
  location            = local.location
  resource_group_name = local.resource_group_name

  server_version = "16"
  sku_name       = "B_Standard_B2ms"
  storage_mb     = 32768

  administrator_login    = "cwydsqladmin"
  administrator_password = random_password.postgresql.result

  high_availability             = null
  public_network_access_enabled = true

  databases = {
    cwyd = {
      name      = "cwyd"
      charset   = "UTF8"
      collation = "en_US.utf8"
    }
  }

  authentication = {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  firewall_rules = {
    allow_azure_services = {
      name             = "AllowAzureServices"
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
  }

  server_configuration = {
    azure_extensions = {
      name   = "azure.extensions"
      config = "vector"
    }
  }

  enable_telemetry = var.enable_telemetry

  depends_on = [module.test]
}

# --- Application Insights ---

module "application_insights" {
  source  = "Azure/avm-res-insights-component/azurerm"
  version = "0.3.0"

  name                = "ai-alz-appinsights-${module.test.name_suffix}"
  location            = local.location
  resource_group_name = local.resource_group_name
  workspace_id        = module.test.log_analytics_workspace_id
  application_type    = "web"
  enable_telemetry    = var.enable_telemetry

  depends_on = [module.test]
}

# --- Key Vault Secrets ---

resource "azurerm_key_vault_secret" "postgresql_password" {
  name         = "postgresql-password"
  value        = random_password.postgresql.result
  key_vault_id = module.test.genai_key_vault_id

  depends_on = [module.test]
}

resource "azurerm_key_vault_secret" "appinsights_connection_string" {
  name         = "appinsights-connection-string"
  value        = module.application_insights.connection_string
  key_vault_id = module.test.genai_key_vault_id

  depends_on = [module.test]
}
