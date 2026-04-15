output "resource_group_name" {
  value = var.resource_group_name
}

output "location" {
  value = var.location
}

output "vpn_gateway_id" {
  value       = azurerm_virtual_network_gateway.this.id
  description = "Resource ID of the VPN Gateway. Use 'az network vnet-gateway vpn-client generate' to download the VPN client config."
}


