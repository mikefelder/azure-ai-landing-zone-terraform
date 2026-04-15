variable "location" {
  type        = string
  default     = "swedencentral"
  description = "Azure region for all resources."
}

variable "resource_group_name" {
  type        = string
  default     = "rg-aiml-poc"
  description = "Name of the resource group."
}

variable "name_prefix" {
  type        = string
  default     = "poc"
  description = "Prefix for resource names (lowercase alphanumeric, max 10 chars)."
}

variable "tags" {
  type = map(string)
  default = {
    environment = "poc"
    purpose     = "ai-ml-proof-of-concept"
  }
  description = "Tags applied to all resources."
}

variable "deploy_bastion" {
  type        = bool
  default     = false
  description = "Whether to deploy Azure Bastion (requires portal access). Disabled by default."
}

variable "allowed_ips" {
  type        = list(string)
  description = "List of IP addresses (CIDR) allowed to RDP into the jump VM. Example: [\"203.0.113.10/32\", \"198.51.100.0/24\"]"

  validation {
    condition     = length(var.allowed_ips) > 0
    error_message = "At least one IP address must be specified in allowed_ips."
  }
}
