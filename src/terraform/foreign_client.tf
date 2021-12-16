resource "azurerm_virtual_network" "vnet3" {
  name                = var.virtual_network3.name
  location            = var.virtual_network3.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.virtual_network3.address_space
}

resource "azurerm_subnet" "subnet_foreign_client" {
  name = var.virtual_network3.subnet.name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vnet3.name
  address_prefixes     = var.virtual_network3.subnet.address_space
}

resource "azurerm_public_ip" "vm_foreign_client" {
  name = var.vm_foreign_client.name
  location =  var.virtual_network3.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method = "Static"
}

resource "azurerm_network_security_group" "vm_foreign_client" {
  name                = var.vm_foreign_client.name
  location            = var.virtual_network3.location
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

resource "azurerm_network_interface" "vm_foreign_client" {
  name = var.vm_foreign_client.name
  location = var.virtual_network3.location
  resource_group_name = azurerm_resource_group.this.name
  enable_ip_forwarding = false
  ip_configuration {
    name = var.vm_foreign_client.name
    subnet_id = azurerm_subnet.subnet_foreign_client.id
    public_ip_address_id = azurerm_public_ip.vm_foreign_client.id
    private_ip_address_allocation = "Static"
    private_ip_address = cidrhost(var.virtual_network3.subnet.address_space[0], 10)
  }
}

resource "azurerm_network_interface_security_group_association" "vm_foreign_client" {
  network_interface_id      = azurerm_network_interface.vm_foreign_client.id
  network_security_group_id = azurerm_network_security_group.vm_foreign_client.id
}

resource "azurerm_linux_virtual_machine" "vm_foreign_client" {
  name = var.vm_foreign_client.name
  admin_username = var.vm_user
  location = var.virtual_network3.location
  resource_group_name = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.vm_foreign_client.id]
  size = var.vm_foreign_client.size
  # custom_data = data.template_cloudinit_config.vm_api.rendered
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