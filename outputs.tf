#TODO: determine what a good set of outpus should be and update.
output "resource_id" {
  description = "Future resource ID output for the LZA."
  value       = "tbd"
}

output "ai_services_name" {
  description = "The name of the AI Services account."
  value       = module.foundry_ptn.ai_foundry_name
}

output "genai_key_vault_id" {
  description = "The resource ID of the GenAI Key Vault."
  value       = module.avm_res_keyvault_vault.resource_id
}

output "name_suffix" {
  description = "The random name suffix used for resource naming."
  value       = random_string.name_suffix.result
}
