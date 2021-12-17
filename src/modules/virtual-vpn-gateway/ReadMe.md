# Virtual VPN Gateway

This project intends to provision an Azure Vpn Gateway and its basic resources like Public Ips and GatewaySubnet

## How to Use ?
---

```
module "backend" {
  source                = "../modules/virtual-vpn-gateway"
  resource_group_name   = "my-resource-group"
  location              = "eastus"
  gateway_subnet_address_prefixes = ["10.10.254.254"]
  gateway               = {
                            name = "myvpngateway"
                            vpn_type = "RouteBased"
                            active_active = false
                            enable_bgp = false
                            sku = "VpnGw1"
                            generation = "Generation1"
                            ip_configuration = {
                              "ip-1" = {
                                sku = "Basic"
                                sku_tier = "Regional"
                                allocation_method = "Dynamic"
                                availability_zone = "No-Zone"
                              }
                            }
                          }
  tags                  = { createdBy = "Missão" }
}
```

## Arguments
---
- `resource_group_name` - (Required) Name of the resource group to be created.

- `location` - (Required) Location where the resources will provisioned.

- `virtual_network_name` - (Required) Virtual Network Name where the Gateway will be provisioned.

- `gateway_subnet_address_prefixes` - (Required) List of string representing the Subnets' CIDR that will be associated with the GatewaySubnet.

- `gateway` - (Required) Virtual VPN Gateway Configuration.

  - `name` - (Required) Name of the Virtual Network Gateway.

  - `type` - (Required) The type of the Virtual Network Gateway. Valid options are `Vpn` or `ExpressRoute`.

  - `vpn_type` - (Required) The routing type of the Virtual Network Gateway. Valid options are `RouteBased` or `PolicyBased`.

  - `active_active` - (Required) If `true`, an active-active Virtual Network Gateway will be created. If `false`, an active-standby gateway will be created

  - `enable_bgp` - (Required) If true, BGP (Border Gateway Protocol) will be enabled for this Virtual Network Gateway.

  - `sku` - (Required) Configuration of the size and capacity of the virtual network gateway.

  - `generation` - (Required) The Generation of the Virtual Network gateway. Possible values include `Generation1`, `Generation2` or `None`.

  - `ip_configuration` - (Required) A map of Virtual Network Gateway Ip Configuration. Which the key represents the ip's name, and the value its configuration

    - `sku` - (Required) he SKU of the Public IP. Accepted values are `Basic` and `Standard`.

    - `sku_tier` - (Required) The SKU Tier that should be used for the Public IP. Possible values are `Regional` and `Global`.

    - `availability_zone` - (Required) The availability zone to allocate the Public IP in. Possible values are `Zone-Redundant`, `1`, `2`, `3`, and `No-Zone`.

    - `allocation_method` - (Required) Defines the allocation method for this IP address. Possible values are `Static` or `Dynamic`.

- `ipsec_connections` - (Optional) A map of Virtual Network Gateway Connections. Which the key represents the connection's name, and the value its configuration

  - `local_gateway_address` - (Required) The gateway IP address to connect with.

  - `local_gateway_address_space` - (Required) The list of string CIDRs representing the address spaces the gateway exposes.

  - `shared_key` - (Required) The shared IPSec key.

  - `ipsec_policy` - (Required) An object representing the ipsec policy used in the connection

    - `dh_group` - (Required) The DH group used in IKE phase 1 for initial SA. Valid options are `DHGroup1`, `DHGroup14`, `DHGroup2`, `DHGroup2048`, `DHGroup24`, `ECP256`, `ECP384`, or `None`.

    - `ike_encryption` - (Required) The IKE encryption algorithm. Valid options are `AES128`, `AES192`, `AES256`, `DES`, `DES3`, `GCMAES128`, or `GCMAES256`.

    - `ike_integrity` - (Required)  The IKE integrity algorithm. Valid options are `GCMAES128`, `GCMAES256`, `MD5`, `SHA1`, `SHA256`, or `SHA384`.

    - `ipsec_encryption` - (Required) The IPSec encryption algorithm. Valid options are `AES128`, `AES192`, `AES256`, `DES`, `DES3`, `GCMAES128`, `GCMAES192`, `GCMAES256`, or `None`.

    - `ipsec_integrity` - (Required) The IPSec integrity algorithm. Valid options are `GCMAES128`, `GCMAES192`, `GCMAES256`, `MD5`, `SHA1`, or `SHA256`.

    - `pfs_group` - (Required) The DH group used in IKE phase 2 for new child SA. Valid options are `ECP256`, `ECP384`, `PFS1`, `PFS14`, `PFS2`, `PFS2048`, `PFS24`, `PFSMM`, or `None`.


- `tags` - (Optional) Dictionary of string with the tags that will appended on each resource created.

## Output
---

- `id` - Virtual Network Gateway ID

- `public_ip` - Map containing the information of the Virtual Network Gateway's public IP

```Ex
id = "/subscriptions/XXX/resourceGroups/rg/providers/Microsoft.Network/virtualNetworkGateways/gateway"
public_ip = {
  vpn-gateway-ip = {
    id        = "/subscriptions/XXX/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/vpn-gateway-ip"
    public_ip = "52.250.65.48"
  }
}
```
