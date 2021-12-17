resource "azurerm_virtual_network" "foreign" {
  name                = var.foreign_vnet.name
  location            = var.foreign_vnet.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.foreign_vnet.address_space
  tags              = local.tags
}

resource "azurerm_subnet" "foreign" {
  name = "foreign"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.foreign.name
  address_prefixes     = [local.foreign_subnet]
}

resource "azurerm_network_security_group" "foreign" {
  name                = azurerm_subnet.foreign.name
  location            = azurerm_virtual_network.foreign.location
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
  security_rule {
    name                       = "api"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags              = local.tags
}

resource "azurerm_subnet_network_security_group_association" "foreign" {
  subnet_id                 = azurerm_subnet.foreign.id
  network_security_group_id = azurerm_network_security_group.foreign.id
}

resource "azurerm_public_ip" "strongswan" {
  name = var.vm_strongswan_name
  location =  azurerm_virtual_network.foreign.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method = "Static"
  tags              = local.tags
}

resource "azurerm_network_interface" "strongswan" {
  name = var.vm_strongswan_name
  location = azurerm_virtual_network.foreign.location
  resource_group_name = azurerm_resource_group.this.name
  enable_ip_forwarding = true
  ip_configuration {
    name = var.vm_strongswan_name
    subnet_id = azurerm_subnet.foreign.id
    public_ip_address_id = azurerm_public_ip.strongswan.id
    private_ip_address_allocation = "Static"
    private_ip_address = cidrhost(local.foreign_subnet, 10)
  }
  tags              = local.tags
}

resource "azurerm_linux_virtual_machine" "strongswan" {
  name = var.vm_strongswan_name
  admin_username = var.vm_common_configuration.user
  location = azurerm_virtual_network.foreign.location
  resource_group_name = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.strongswan.id]
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

resource "null_resource" "setup_vpn" {
  triggers = {
    strongswan_sh = sha256(local.strongswan_sh)
  }
  connection {
    type     = "ssh"
    user     = var.vm_common_configuration.user
    host     = azurerm_public_ip.strongswan.ip_address
    private_key = file(var.vm_common_configuration.ssh.private_key_path)
  }
  provisioner "file" {
    content = local.strongswan_sh
    destination = "strongswan.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod 700 strongswan.sh",
      "./strongswan.sh",
    ]
  }
  depends_on = [ 
    azurerm_linux_virtual_machine.strongswan,
     module.vpn_gateway
  ]
}

resource "azurerm_network_interface" "api" {
  name = var.vm_api_name
  location = azurerm_virtual_network.foreign.location
  resource_group_name = azurerm_resource_group.this.name
  enable_ip_forwarding = false
  ip_configuration {
    name = var.vm_api_name
    subnet_id = azurerm_subnet.foreign.id
    private_ip_address_allocation = "Static"
    private_ip_address = cidrhost(local.foreign_subnet, 20)
  }
  tags              = local.tags
}

resource "azurerm_linux_virtual_machine" "api" {
  name = var.vm_api_name
  admin_username = var.vm_common_configuration.user
  location = azurerm_virtual_network.foreign.location
  resource_group_name = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.api.id]
  size = var.vm_common_configuration.size
  custom_data = data.template_cloudinit_config.api.rendered
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