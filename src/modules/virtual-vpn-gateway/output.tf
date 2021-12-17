output "public_ip" {
  value = {
    for k, v in azurerm_public_ip.this : k => {
      id        = v.id
      public_ip = v.ip_address
    }
  }
}

output "id" {
  value = azurerm_virtual_network_gateway.this.id
}
