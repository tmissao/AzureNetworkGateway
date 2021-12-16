output "strongswan_vm" {
  value       = {
    public_ip = azurerm_public_ip.vm_strongswan.ip_address
    private_ip = azurerm_network_interface.vm_strongswan.private_ip_address
  }
}

output "api_vm" {
  value       = {
    # public_ip = azurerm_public_ip.vm_api.ip_address
    private_ip = azurerm_network_interface.vm_api.private_ip_address
  }
}

output "foreign_vm" {
  value       = {
    public_ip = azurerm_public_ip.vm_foreign_client.ip_address
    private_ip = azurerm_network_interface.vm_foreign_client.private_ip_address
  }
}

output "client_vm" {
  value       = {
    public_ip = azurerm_public_ip.vm_client.ip_address
    private_ip = azurerm_network_interface.vm_client.private_ip_address
  }
}

output "vpn_gateway" {
  value = module.vpn
}
