resource "azurerm_virtual_network" "vnet2" {
  name                = var.virtual_network2.name
  location            = var.virtual_network2.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.virtual_network2.address_space
}

resource "azurerm_subnet" "subnet" {
  name = var.virtual_network2.subnet.name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = var.virtual_network2.subnet.address_space
}

resource "azurerm_public_ip" "vm_strongswan" {
  name = var.vm_ipsec.name
  location =  var.virtual_network2.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method = "Static"
}

resource "azurerm_network_security_group" "vm_strongswan" {
  name                = var.vm_ipsec.name
  location            = var.virtual_network2.location
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
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "vm_strongswan" {
  name = var.vm_ipsec.name
  location = var.virtual_network2.location
  resource_group_name = azurerm_resource_group.this.name
  enable_ip_forwarding = true
  ip_configuration {
    name = var.vm_ipsec.name
    subnet_id = azurerm_subnet.subnet.id
    public_ip_address_id = azurerm_public_ip.vm_strongswan.id
    private_ip_address_allocation = "Static"
    private_ip_address = cidrhost(var.virtual_network2.subnet.address_space[0], 10)
  }
}

resource "azurerm_network_interface_security_group_association" "vm_strongswan" {
  network_interface_id      = azurerm_network_interface.vm_strongswan.id
  network_security_group_id = azurerm_network_security_group.vm_strongswan.id
}

resource "azurerm_linux_virtual_machine" "vm_strongswan" {
  name = var.vm_ipsec.name
  admin_username = var.vm_user
  location = var.virtual_network2.location
  resource_group_name = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.vm_strongswan.id]
  size = var.vm_ipsec.size
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

resource "null_resource" "setup_proxy" {
  triggers = {
    strongswan = filebase64sha256("${path.module}/templates/strongswan_sh.tpl")
  }
  connection {
    type     = "ssh"
    user     = var.vm_user
    host     = azurerm_public_ip.vm_strongswan.ip_address
    private_key = file(var.vm_user_ssh_private_key_path)
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
    azurerm_linux_virtual_machine.vm_strongswan,
    azurerm_virtual_network_gateway_connection.onpremise
  ]
}

resource "azurerm_network_interface" "vm_api" {
  name = var.vm_api.name
  location = var.virtual_network2.location
  resource_group_name = azurerm_resource_group.this.name
  enable_ip_forwarding = false
  ip_configuration {
    name = var.vm_api.name
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address = cidrhost(var.virtual_network2.subnet.address_space[0], 20)
  }
}

resource "azurerm_network_interface_security_group_association" "vm_api" {
  network_interface_id      = azurerm_network_interface.vm_api.id
  network_security_group_id = azurerm_network_security_group.vm_strongswan.id
}

data "template_file" "vm_api" {
  template = file("${path.module}/scripts/init.cfg")
}

data "template_file" "vm_api_shell-script" {
  template = file("${path.module}/scripts/setup-api.sh")
}

data "template_cloudinit_config" "vm_api" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.vm_api.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.vm_api_shell-script.rendered
  }
}

resource "azurerm_linux_virtual_machine" "vm_api" {
  name = var.vm_api.name
  admin_username = var.vm_user
  location = var.virtual_network2.location
  resource_group_name = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.vm_api.id]
  size = var.vm_ipsec.size
  custom_data = data.template_cloudinit_config.vm_api.rendered
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