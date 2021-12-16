locals {
  tags = var.tags
  strongswan_sh = templatefile("${path.module}/templates/strongswan_sh.tpl", {
    HOST_SUBNET = var.virtual_network2.subnet.address_space[0]
    HOST_PUBLIC_IP = azurerm_public_ip.vm_strongswan.ip_address
    // it is necessary a better handle of ip1
    REMOTE_PUBLIC_IP = module.vpn.public_ip.ip1.public_ip
    REMOTE_SUBNET = var.virtual_network.address_space[0]
    REMOTE_SUBNET2 = var.virtual_network3.address_space[0]
    STRONGSWAN_PASSWORD = var.vpn_connection.key
  })
}

variable resource_group {
  default = {
    name = "ipsec-poc"
    location = "eastus"
  }
}

variable virtual_network {
  default = {
    name = "vnet1"
    location = "eastus"
    address_space = ["10.0.0.0/16"]
    subnet = {
      name =  "default"
      address_space = ["10.0.1.0/24"]
    }
  }
}

variable virtual_network2 {
  default = {
    name = "vnet2"
    location = "ukwest"
    address_space = ["11.0.0.0/16"]
    subnet = {
      name =  "default"
      address_space = ["11.0.0.0/24"]
    }
  }
}

variable virtual_network3 {
  default = {
    name = "vnet3"
    location = "eastus"
    address_space = ["12.0.0.0/16"]
    subnet = {
      name =  "default"
      address_space = ["12.0.0.0/24"]
    }
  }
}

variable vpn {
  default = {
    name = "vpngateway-poc"
    type = "Vpn"
    vpn_type = "RouteBased"
    active_active = true
    enable_bgp = false
    sku = "VpnGw1"
    generation = "Generation1"
    address_space = ["10.0.0.0/24"]
    ip_configuration = {
      ipnames = ["ip1", "ip2"]
      sku = "Basic"
      sku_tier = "Regional"
      allocation_method = "Dynamic"
      availability_zone = "No-Zone"
    }
  }
}

variable "vm_user" {
  default = "adminuser"
}

variable "vm_user_ssh_path" {
  default = "../../keys/key.pub"
}

variable "vm_user_ssh_private_key_path" {
  default = "../../keys/key"
}

variable vm_ipsec {
  default = {
    name = "strongswan"
    size = "Standard_B2s"
  }
}

variable vm_api {
  default = {
    name = "api"
    size = "Standard_B2s"
  }
}

variable vm_foreign_client {
  default = {
    name = "foreign-client"
    size = "Standard_B2s"
  }
}

variable vm_client {
  default = {
    name = "client"
    size = "Standard_B2s"
  }
}

variable "vpn_connection" {
  default = {
    key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
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

variable tags {
  default = {
    terraform = "true"
  }
}