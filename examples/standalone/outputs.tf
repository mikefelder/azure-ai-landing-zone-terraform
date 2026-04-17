# --- PostgreSQL Outputs ---

output "postgresql_host" {
  description = "FQDN of the PostgreSQL Flexible Server."
  value       = module.postgresql.fqdn
}

output "postgresql_database" {
  description = "The name of the PostgreSQL database."
  value       = "cwyd"
}

output "postgresql_admin_user" {
  description = "The PostgreSQL admin username."
  value       = "cwydsqladmin"
}

# --- Application Insights Outputs ---

output "appinsights_connection_string" {
  description = "The Application Insights connection string."
  value       = module.application_insights.connection_string
  sensitive   = true
}

# --- Content Safety Outputs ---

output "content_safety_endpoint" {
  description = "The Content Safety endpoint URL (AI Services endpoint)."
  value       = data.azurerm_cognitive_account.ai_services.endpoint
}

output "content_safety_key" {
  description = "The Content Safety key (AI Services primary key)."
  value       = data.azurerm_cognitive_account.ai_services.primary_access_key
  sensitive   = true
}

# --- Document Intelligence (Form Recognizer) Outputs ---

output "form_recognizer_endpoint" {
  description = "The Document Intelligence endpoint URL (AI Services endpoint)."
  value       = data.azurerm_cognitive_account.ai_services.endpoint
}

output "form_recognizer_key" {
  description = "The Document Intelligence key (AI Services primary key)."
  value       = data.azurerm_cognitive_account.ai_services.primary_access_key
  sensitive   = true
}

# --- Embedding Deployment Output ---

output "embedding_deployment_name" {
  description = "The name of the text-embedding-ada-002 model deployment."
  value       = "text-embedding-ada-002"
}

# --- Container App Outputs ---

output "SERVICE_WEB_RESOURCE_NAME" {
  description = "The name of the web Container App."
  value       = azurerm_container_app.web.name
}

output "SERVICE_ADMINWEB_RESOURCE_NAME" {
  description = "The name of the admin web Container App."
  value       = azurerm_container_app.adminweb.name
}

output "SERVICE_FUNCTION_RESOURCE_NAME" {
  description = "The name of the function Container App."
  value       = azurerm_container_app.function.name
}

output "AZURE_CONTAINER_REGISTRY_ENDPOINT" {
  description = "The ACR login server endpoint."
  value       = data.azurerm_container_registry.this.login_server
}
