resource "azurerm_resource_group" "this" {
  name = var.resource_group.name
  location = var.resource_group.location
  tags = local.tags
}

resource "azurerm_virtual_network" "this" {
  name                = var.virtual_network.name
  location            = var.virtual_network.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.virtual_network.address_space
}

module "vpn" {
  source = "../modules/virtual-vpn-gateway"
  location = var.resource_group.location
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  gateway_subnet_address_prefixes = var.vpn.address_space
  gateway = {
    name = var.vpn.name
    type = var.vpn.type
    vpn_type = var.vpn.vpn_type
    active_active = var.vpn.active_active
    enable_bgp = var.vpn.enable_bgp
    sku = var.vpn.sku
    generation = var.vpn.generation
    ip_configuration = {
      for k in var.vpn.ip_configuration.ipnames : k => {
        sku = var.vpn.ip_configuration.sku
        sku_tier = var.vpn.ip_configuration.sku_tier
        allocation_method = var.vpn.ip_configuration.allocation_method
        availability_zone = var.vpn.ip_configuration.availability_zone
      } 
    }
  }
}

resource "azurerm_local_network_gateway" "this" {
  name                = "onpremise"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.virtual_network.location
  gateway_address     = azurerm_public_ip.vm_strongswan.ip_address
  address_space       = var.virtual_network2.subnet.address_space
}

resource "azurerm_virtual_network_gateway_connection" "onpremise" {
  name                = "onpremise"
  location            = var.resource_group.location
  resource_group_name = azurerm_resource_group.this.name
  type                       = "IPsec"
  virtual_network_gateway_id = module.vpn.gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.this.id
  shared_key = var.vpn_connection.key
  ipsec_policy {
    dh_group =  var.vpn_connection.ipsec_policy.dh_group
    ike_encryption = var.vpn_connection.ipsec_policy.ike_encryption
    ike_integrity = var.vpn_connection.ipsec_policy.ike_integrity
    ipsec_encryption = var.vpn_connection.ipsec_policy.ipsec_encryption
    ipsec_integrity = var.vpn_connection.ipsec_policy.ipsec_integrity
    pfs_group = var.vpn_connection.ipsec_policy.pfs_group
  }
}

resource "azurerm_subnet" "subnet_client" {
  name = var.virtual_network.subnet.name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.virtual_network.subnet.address_space
}

resource "azurerm_public_ip" "vm_client" {
  name = var.vm_client.name
  location =  var.virtual_network.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method = "Static"
}

resource "azurerm_network_security_group" "vm_client" {
  name                = var.vm_client.name
  location            = var.virtual_network.location
  resource_group_name =  azurerm_resource_group.this.name
  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "ping"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "vm_client" {
  name = var.vm_client.name
  location = var.virtual_network.location
  resource_group_name = azurerm_resource_group.this.name
  enable_ip_forwarding = false
  ip_configuration {
    name = var.vm_client.name
    subnet_id = azurerm_subnet.subnet_client.id
    public_ip_address_id = azurerm_public_ip.vm_client.id
    private_ip_address_allocation = "Static"
    private_ip_address = cidrhost(var.virtual_network.subnet.address_space[0], 10)
  }
}

resource "azurerm_linux_virtual_machine" "vm_client" {
  name = var.vm_client.name
  admin_username = var.vm_user
  location = var.virtual_network.location
  resource_group_name = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.vm_client.id]
  size = var.vm_client.size
  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  os_disk {
    caching = "None"
    storage_account_type = "Standard_LRS"
  }
  admin_ssh_key {
    username   = var.vm_user
    public_key = file(var.vm_user_ssh_path)
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "hub-to-spoke"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.this.name
  remote_virtual_network_id = azurerm_virtual_network.vnet3.id
  allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "spoke-to-hub"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.vnet3.name
  remote_virtual_network_id = azurerm_virtual_network.this.id
  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = true
}
