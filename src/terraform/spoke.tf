resource "azurerm_virtual_network" "spoke" {
  name                = var.spoke_vnet.name
  location            = var.spoke_vnet.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.spoke_vnet.address_space
  tags              = local.tags
}

resource "azurerm_subnet" "spoke" {
  name = "spoke"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [local.spoke_subnet]
}

resource "azurerm_network_security_group" "spoke" {
  name                = azurerm_subnet.spoke.name
  location            = azurerm_virtual_network.spoke.location
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
  tags              = local.tags
}

resource "azurerm_subnet_network_security_group_association" "spoke" {
  subnet_id                 = azurerm_subnet.spoke.id
  network_security_group_id = azurerm_network_security_group.spoke.id
}

resource "azurerm_public_ip" "client" {
  name = var.vm_client_name
  location =  azurerm_virtual_network.spoke.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method = "Static"
  tags              = local.tags
}

resource "azurerm_network_interface" "client" {
  name = var.vm_client_name
  location = azurerm_virtual_network.spoke.location
  resource_group_name = azurerm_resource_group.this.name
  enable_ip_forwarding = false
  ip_configuration {
    name = var.vm_client_name
    subnet_id = azurerm_subnet.spoke.id
    public_ip_address_id = azurerm_public_ip.client.id
    private_ip_address_allocation = "Static"
    private_ip_address = cidrhost(local.spoke_subnet, 10)
  }
  tags              = local.tags
}

resource "azurerm_linux_virtual_machine" "client" {
  name = var.vm_client_name
  admin_username = var.vm_common_configuration.user
  location = azurerm_virtual_network.spoke.location
  resource_group_name = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.client.id]
  size = var.vm_common_configuration.size
  source_image_reference {
    publisher = var.vm_common_configuration.source_image_reference.publisher
    offer     = var.vm_common_configuration.source_image_reference.offer
    sku       = var.vm_common_configuration.source_image_reference.sku
    version   = var.vm_common_configuration.source_image_reference.version
  }
  os_disk {
    caching = var.vm_common_configuration.os_disk.caching
    storage_account_type = var.vm_common_configuration.os_disk.storage_account_type
  }
  admin_ssh_key {
    username   = var.vm_common_configuration.user
    public_key = file(var.vm_common_configuration.ssh.public_key_path)
  }
  tags              = local.tags
}