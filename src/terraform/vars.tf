locals {
  tags = merge(
    var.tags,
    {
      subscription   = data.azurerm_subscription.current.display_name,
      resource_group = var.resource_group.name
    }
  )
  gateway_subnet = cidrsubnet(var.gateway_vnet.address_space[0], 8, 0)
  spoke_subnet = cidrsubnet(var.spoke_vnet.address_space[0], 8, 0)
  foreign_subnet = cidrsubnet(var.foreign_vnet.address_space[0], 8, 0)
  strongswan_sh = templatefile("${path.module}/templates/strongswan_sh.tpl", {
    HOST_SUBNET = local.foreign_subnet
    HOST_PUBLIC_IP = azurerm_public_ip.strongswan.ip_address
    REMOTE_PUBLIC_IP = values(module.vpn_gateway.public_ip)[0].public_ip
    REMOTE_SUBNET = local.spoke_subnet
    STRONGSWAN_PASSWORD = random_password.vpn_connection_shared_key.result
  })
}

data "azurerm_subscription" "current" {}

data "template_file" "init" {
  template = file("${path.module}/scripts/init.cfg")
}

data "template_file" "setup_api" {
  template = file("${path.module}/scripts/setup-api.sh")
}

data "template_cloudinit_config" "api" {
  gzip          = true
  base64_encode = true
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.init.rendered
  }
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.setup_api.rendered
  }
}

variable "resource_group" {
  type = object({
    name = string, location = string
  })
  default = {
    name     = "vpn-gateway"
    location = "westus2"
  }
}

variable "gateway_vnet" {
  type = object({
    name = string, address_space = list(string), location = string
  })
  default = {
    name = "vnet-gateway"
    location = "westus2"
    address_space = ["10.0.0.0/16"]
  }
}

variable "spoke_vnet" {
  type = object({
    name = string, address_space = list(string), location = string
  })
  default = {
    name = "vnet-spoken"
    location = "eastus"
    address_space = ["30.0.0.0/16"]
  }
}

variable "foreign_vnet" {
  type = object({
    name = string, address_space = list(string), location = string
  })
  default = {
    name = "vnet-foreign"
    location = "eastus2"
    address_space = ["20.0.0.0/16"]
  }
}

variable "vpn_gateway" {
  type = object({
    name       = string, type = string, vpn_type = string, active_active = bool,
    enable_bgp = bool, sku = string, generation = string,
    ip_configuration = object({
      ipnames           = list(string), sku = string, sku_tier = string,
      allocation_method = string, availability_zone = string
    })
  })
  default = {
    name = "vpn-gateway"
    type = "Vpn"
    vpn_type = "RouteBased"
    active_active = false
    enable_bgp = false
    sku = "VpnGw1"
    generation = "Generation1"
    ip_configuration = {
      ipnames = ["vpn-gateway-primary-ip"]
      sku = "Basic"
      sku_tier = "Regional"
      allocation_method = "Dynamic"
      availability_zone = "No-Zone"
    }
  }
}

variable "ipsec_connections" {
  type = map(object({
    local_gateway_address = string, local_gateway_address_space = list(string),
    shared_key            = string,
    ipsec_policy = object({
      dh_group         = string, ike_encryption = string, ike_integrity = string,
      ipsec_encryption = string, ipsec_integrity = string, pfs_group = string
    })
  }))
  default = {}
}

variable "vm_common_configuration" {
  default = {
    user = "adminuser"
    ssh = {
      private_key_path = "../../keys/key"
      public_key_path = "../../keys/key.pub"
    }
    os_disk = {
      caching = "None"
      storage_account_type = "Standard_LRS"
    }
    source_image_reference = {
      publisher = "canonical"
      offer     = "0001-com-ubuntu-server-focal"
      sku       = "20_04-lts"
      version   = "latest"
    }
    size = "Standard_B2s"
  }
}

variable "vm_strongswan_name" {
  type = string
  default = "strongswan"
}

variable "vm_api_name" {
  type = string
  default = "api"
}

variable "vm_client_name" {
  type = string
  default = "client"
}

variable tags {
  type = map(string)
  default = {
    "environment" = "poc"
  }
}
