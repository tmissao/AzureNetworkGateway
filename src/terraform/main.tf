resource "azurerm_resource_group" "this" {
  name     = var.resource_group.name
  location = var.resource_group.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "gateway" {
  name                = var.gateway_vnet.name
  location            = var.gateway_vnet.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.gateway_vnet.address_space
  tags              = local.tags
}

resource "random_password" "vpn_connection_shared_key" {
  length           = 32
  special          = true
  override_special = "_%@"
}

module "vpn_gateway" {
  source                          = "../modules/virtual-vpn-gateway"
  location                        = azurerm_virtual_network.gateway.location
  resource_group_name             = azurerm_resource_group.this.name
  virtual_network_name            = azurerm_virtual_network.gateway.name
  gateway_subnet_address_prefixes = [local.gateway_subnet]
  gateway = {
    name          = var.vpn_gateway.name
    type          = var.vpn_gateway.type
    vpn_type      = var.vpn_gateway.vpn_type
    active_active = var.vpn_gateway.active_active
    enable_bgp    = var.vpn_gateway.enable_bgp
    sku           = var.vpn_gateway.sku
    generation    = var.vpn_gateway.generation
    ip_configuration = {
      for k in var.vpn_gateway.ip_configuration.ipnames : k => {
        sku               = var.vpn_gateway.ip_configuration.sku
        sku_tier          = var.vpn_gateway.ip_configuration.sku_tier
        allocation_method = var.vpn_gateway.ip_configuration.allocation_method
        availability_zone = var.vpn_gateway.ip_configuration.availability_zone
      }
    }
  }
  ipsec_connections = {
    foreign = {
      local_gateway_address = azurerm_public_ip.strongswan.ip_address
      local_gateway_address_space = azurerm_subnet.foreign.address_prefixes
      shared_key = random_password.vpn_connection_shared_key.result
      ipsec_policy = {
        dh_group =  "DHGroup14"
        ike_encryption = "AES256"
        ike_integrity = "SHA256"
        ipsec_encryption = "AES256"
        ipsec_integrity = "SHA256"
        pfs_group = "PFS2048"
      }
    }
  }
  tags              = local.tags
}

resource "azurerm_virtual_network_peering" "gateway_to_spoke" {
  name                      = "gateway-to-spoke"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.gateway.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic   = false
  allow_gateway_transit     = true
  use_remote_gateways       = false
  depends_on = [ module.vpn_gateway ]
}

resource "azurerm_virtual_network_peering" "spoke_to_gateway" {
  name                      = "spoke-to-gateway"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.gateway.id
  allow_virtual_network_access = true
  allow_forwarded_traffic = false
  allow_gateway_transit   = false
  use_remote_gateways     = true
  depends_on = [ module.vpn_gateway ]
}