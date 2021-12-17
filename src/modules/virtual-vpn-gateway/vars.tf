variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "virtual_network_name" {
  type = string
}
variable "gateway_subnet_address_prefixes" {
  type = list(string)
}
variable "gateway" {
  type = object({
    name          = string
    type          = string
    vpn_type      = string
    active_active = bool
    enable_bgp    = bool
    sku           = string
    generation    = string
    ip_configuration = map(object({
      sku               = string
      sku_tier          = string
      allocation_method = string
      availability_zone = string
    }))
  })
}
variable "ipsec_connections" {
  type = map(object({
    local_gateway_address = string, local_gateway_address_space = list(string)
    shared_key            = string,
    ipsec_policy = object({
      dh_group         = string, ike_encryption = string, ike_integrity = string,
      ipsec_encryption = string, ipsec_integrity = string, pfs_group = string
    })
  }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
