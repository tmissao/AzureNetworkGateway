output "foreign" {
  value       = {
    strongwan = {
      public_ip = azurerm_public_ip.strongswan.ip_address
      private_ip = azurerm_network_interface.strongswan.private_ip_address
    }
    api = {
      private_ip = azurerm_network_interface.api.private_ip_address
    }
  }
}

output "spoke" {
  value       = {
    client = {
      public_ip = azurerm_public_ip.client.ip_address
      private_ip = azurerm_network_interface.client.private_ip_address
    }
  }
}