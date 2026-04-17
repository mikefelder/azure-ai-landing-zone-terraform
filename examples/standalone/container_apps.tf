# --- Data sources for existing landing zone resources ---

data "azurerm_container_registry" "this" {
  name                = "genaicr${module.test.name_suffix}"
  resource_group_name = local.resource_group_name

  depends_on = [module.test]
}

data "azurerm_search_service" "this" {
  name                = "ai-alz-ks-ai-search-${module.test.name_suffix}"
  resource_group_name = local.resource_group_name

  depends_on = [module.test]
}

data "azurerm_storage_account" "this" {
  name                = "genaisa${module.test.name_suffix}"
  resource_group_name = local.resource_group_name

  depends_on = [module.test]
}

# --- Container App Environment data source ---

data "azurerm_container_app_environment" "this" {
  name                = "ai-alz-container-app-env-${module.test.name_suffix}"
  resource_group_name = local.resource_group_name

  depends_on = [module.test]
}

# --- Container Apps ---

locals {
  container_app_name_prefix = "ai-alz-ca-${module.test.name_suffix}"
}

# --- ACR AcrPull role assignment for Container Apps managed identities ---

resource "azurerm_container_app" "web" {
  name                         = "${local.container_app_name_prefix}-web"
  container_app_environment_id = data.azurerm_container_app_environment.this.id
  resource_group_name          = local.resource_group_name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  registry {
    server               = data.azurerm_container_registry.this.login_server
    identity             = "SystemAssigned"
  }

  secret {
    name  = "azure-openai-api-key"
    value = data.azurerm_cognitive_account.ai_services.primary_access_key
  }
  secret {
    name  = "azure-search-key"
    value = data.azurerm_search_service.this.primary_key
  }
  secret {
    name  = "azure-blob-account-key"
    value = data.azurerm_storage_account.this.primary_access_key
  }
  secret {
    name  = "appinsights-connection-string"
    value = module.application_insights.connection_string
  }

  template {
    min_replicas = 1
    max_replicas = 3

    container {
      name   = "web"
      image  = "mcr.microsoft.com/k8se/quickstart:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "AZURE_OPENAI_RESOURCE"
        value = module.test.ai_services_name
      }
      env {
        name        = "AZURE_OPENAI_API_KEY"
        secret_name = "azure-openai-api-key"
      }
      env {
        name  = "AZURE_SEARCH_SERVICE"
        value = data.azurerm_search_service.this.name
      }
      env {
        name        = "AZURE_SEARCH_KEY"
        secret_name = "azure-search-key"
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_NAME"
        value = data.azurerm_storage_account.this.name
      }
      env {
        name        = "AZURE_BLOB_ACCOUNT_KEY"
        secret_name = "azure-blob-account-key"
      }
      env {
        name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        secret_name = "appinsights-connection-string"
      }
      env {
        name  = "AZURE_POSTGRESQL_HOST_NAME"
        value = module.postgresql.fqdn
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  depends_on = [
    module.test,
    module.postgresql,
    module.application_insights,
  ]
}

resource "azurerm_container_app" "adminweb" {
  name                         = "${local.container_app_name_prefix}-adminweb"
  container_app_environment_id = data.azurerm_container_app_environment.this.id
  resource_group_name          = local.resource_group_name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  registry {
    server               = data.azurerm_container_registry.this.login_server
    identity             = "SystemAssigned"
  }

  secret {
    name  = "azure-openai-api-key"
    value = data.azurerm_cognitive_account.ai_services.primary_access_key
  }
  secret {
    name  = "azure-search-key"
    value = data.azurerm_search_service.this.primary_key
  }
  secret {
    name  = "azure-blob-account-key"
    value = data.azurerm_storage_account.this.primary_access_key
  }
  secret {
    name  = "appinsights-connection-string"
    value = module.application_insights.connection_string
  }

  template {
    min_replicas = 1
    max_replicas = 3

    container {
      name   = "adminweb"
      image  = "mcr.microsoft.com/k8se/quickstart:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "AZURE_OPENAI_RESOURCE"
        value = module.test.ai_services_name
      }
      env {
        name        = "AZURE_OPENAI_API_KEY"
        secret_name = "azure-openai-api-key"
      }
      env {
        name  = "AZURE_SEARCH_SERVICE"
        value = data.azurerm_search_service.this.name
      }
      env {
        name        = "AZURE_SEARCH_KEY"
        secret_name = "azure-search-key"
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_NAME"
        value = data.azurerm_storage_account.this.name
      }
      env {
        name        = "AZURE_BLOB_ACCOUNT_KEY"
        secret_name = "azure-blob-account-key"
      }
      env {
        name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        secret_name = "appinsights-connection-string"
      }
      env {
        name  = "AZURE_POSTGRESQL_HOST_NAME"
        value = module.postgresql.fqdn
      }
      env {
        name  = "BACKEND_URL"
        value = "https://${azurerm_container_app.function.ingress[0].fqdn}"
      }
      env {
        name  = "FUNCTION_KEY"
        value = "" # Set after deployment
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  depends_on = [
    module.test,
    module.postgresql,
    module.application_insights,
    azurerm_container_app.function,
  ]
}

resource "azurerm_container_app" "function" {
  name                         = "${local.container_app_name_prefix}-function"
  container_app_environment_id = data.azurerm_container_app_environment.this.id
  resource_group_name          = local.resource_group_name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  registry {
    server               = data.azurerm_container_registry.this.login_server
    identity             = "SystemAssigned"
  }

  secret {
    name  = "azure-openai-api-key"
    value = data.azurerm_cognitive_account.ai_services.primary_access_key
  }
  secret {
    name  = "azure-search-key"
    value = data.azurerm_search_service.this.primary_key
  }
  secret {
    name  = "azure-blob-account-key"
    value = data.azurerm_storage_account.this.primary_access_key
  }
  secret {
    name  = "appinsights-connection-string"
    value = module.application_insights.connection_string
  }
  secret {
    name  = "storage-connection-string"
    value = data.azurerm_storage_account.this.primary_connection_string
  }

  template {
    min_replicas = 1
    max_replicas = 3

    container {
      name   = "function"
      image  = "mcr.microsoft.com/azure-functions/python:4-python3.11"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "AZURE_OPENAI_RESOURCE"
        value = module.test.ai_services_name
      }
      env {
        name        = "AZURE_OPENAI_API_KEY"
        secret_name = "azure-openai-api-key"
      }
      env {
        name  = "AZURE_SEARCH_SERVICE"
        value = data.azurerm_search_service.this.name
      }
      env {
        name        = "AZURE_SEARCH_KEY"
        secret_name = "azure-search-key"
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_NAME"
        value = data.azurerm_storage_account.this.name
      }
      env {
        name        = "AZURE_BLOB_ACCOUNT_KEY"
        secret_name = "azure-blob-account-key"
      }
      env {
        name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        secret_name = "appinsights-connection-string"
      }
      env {
        name        = "AzureWebJobsStorage"
        secret_name = "storage-connection-string"
      }
      env {
        name  = "FUNCTIONS_WORKER_RUNTIME"
        value = "python"
      }
    }
  }

  ingress {
    external_enabled = false
    target_port      = 80
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  depends_on = [
    module.test,
    module.postgresql,
    module.application_insights,
  ]
}

# --- ACR Pull role assignments for each Container App's system-assigned identity ---

resource "azurerm_role_assignment" "web_acr_pull" {
  principal_id         = azurerm_container_app.web.identity[0].principal_id
  scope                = data.azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
}

resource "azurerm_role_assignment" "adminweb_acr_pull" {
  principal_id         = azurerm_container_app.adminweb.identity[0].principal_id
  scope                = data.azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
}

resource "azurerm_role_assignment" "function_acr_pull" {
  principal_id         = azurerm_container_app.function.identity[0].principal_id
  scope                = data.azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
}

# --- Key Vault access for each Container App ---

resource "azurerm_role_assignment" "web_kv_secrets_user" {
  principal_id         = azurerm_container_app.web.identity[0].principal_id
  scope                = module.test.genai_key_vault_id
  role_definition_name = "Key Vault Secrets User"
}

resource "azurerm_role_assignment" "adminweb_kv_secrets_user" {
  principal_id         = azurerm_container_app.adminweb.identity[0].principal_id
  scope                = module.test.genai_key_vault_id
  role_definition_name = "Key Vault Secrets User"
}

resource "azurerm_role_assignment" "function_kv_secrets_user" {
  principal_id         = azurerm_container_app.function.identity[0].principal_id
  scope                = module.test.genai_key_vault_id
  role_definition_name = "Key Vault Secrets User"
}

# --- Storage access for each Container App ---

resource "azurerm_role_assignment" "web_storage_blob_contributor" {
  principal_id         = azurerm_container_app.web.identity[0].principal_id
  scope                = data.azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
}

resource "azurerm_role_assignment" "adminweb_storage_blob_contributor" {
  principal_id         = azurerm_container_app.adminweb.identity[0].principal_id
  scope                = data.azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
}

resource "azurerm_role_assignment" "function_storage_blob_contributor" {
  principal_id         = azurerm_container_app.function.identity[0].principal_id
  scope                = data.azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
}

# --- AI Services (Cognitive Services) access for each Container App ---

resource "azurerm_role_assignment" "web_cognitive_services_user" {
  principal_id         = azurerm_container_app.web.identity[0].principal_id
  scope                = data.azurerm_cognitive_account.ai_services.id
  role_definition_name = "Cognitive Services OpenAI User"
}

resource "azurerm_role_assignment" "adminweb_cognitive_services_user" {
  principal_id         = azurerm_container_app.adminweb.identity[0].principal_id
  scope                = data.azurerm_cognitive_account.ai_services.id
  role_definition_name = "Cognitive Services OpenAI User"
}

resource "azurerm_role_assignment" "function_cognitive_services_user" {
  principal_id         = azurerm_container_app.function.identity[0].principal_id
  scope                = data.azurerm_cognitive_account.ai_services.id
  role_definition_name = "Cognitive Services OpenAI User"
}

# --- AI Search access for each Container App ---

resource "azurerm_role_assignment" "web_search_index_contributor" {
  principal_id         = azurerm_container_app.web.identity[0].principal_id
  scope                = data.azurerm_search_service.this.id
  role_definition_name = "Search Index Data Contributor"
}

resource "azurerm_role_assignment" "adminweb_search_index_contributor" {
  principal_id         = azurerm_container_app.adminweb.identity[0].principal_id
  scope                = data.azurerm_search_service.this.id
  role_definition_name = "Search Index Data Contributor"
}

resource "azurerm_role_assignment" "function_search_index_contributor" {
  principal_id         = azurerm_container_app.function.identity[0].principal_id
  scope                = data.azurerm_search_service.this.id
  role_definition_name = "Search Index Data Contributor"
}
