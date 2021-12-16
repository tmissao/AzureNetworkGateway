resource "azurerm_subnet" "this" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = var.gateway_subnet_address_prefixes
}

resource "azurerm_public_ip" "this" {
  for_each = var.gateway.ip_configuration
  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  sku = each.value.sku
  sku_tier = each.value.sku_tier
  allocation_method = each.value.allocation_method
  availability_zone = each.value.availability_zone
  tags = var.tags
}

resource "azurerm_virtual_network_gateway" "this" {
  name = var.gateway.name
  location            = var.location
  resource_group_name  = var.resource_group_name
  type = var.gateway.type
  vpn_type = var.gateway.vpn_type
  active_active = var.gateway.active_active
  enable_bgp = var.gateway.enable_bgp
  sku = var.gateway.sku
  generation = var.gateway.generation
  dynamic "ip_configuration" {
    for_each = azurerm_public_ip.this
    content {
      name = ip_configuration.key
      private_ip_address_allocation = "Dynamic"
      subnet_id = azurerm_subnet.this.id
      public_ip_address_id  = ip_configuration.value.id
    }
  }
  tags = var.tags
}