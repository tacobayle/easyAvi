data "nsxt_policy_transport_zone" "tzMgmt" {
  display_name = "vmc-overlay-tz"
}

resource "nsxt_policy_nat_rule" "dnat_controller" {
  count = var.controller["count"]
  display_name         = "dnat_avicontroller"
  action               = "DNAT"
  source_networks      = []
  destination_networks = [vmc_public_ip.public_ip_controller[count.index].ip]
  translated_networks  = [vsphere_virtual_machine.controller[count.index].default_ip_address]
  gateway_path         = "/infra/tier-1s/cgw"
  logging              = false
  firewall_match       = "MATCH_INTERNAL_ADDRESS"
}

resource "nsxt_policy_nat_rule" "dnat_jump" {
  display_name         = "dnat_jump"
  action               = "DNAT"
  source_networks      = []
  destination_networks = [vmc_public_ip.public_ip_jump.ip]
  translated_networks  = [vsphere_virtual_machine.jump.default_ip_address]
  gateway_path         = "/infra/tier-1s/cgw"
  logging              = false
  firewall_match       = "MATCH_INTERNAL_ADDRESS"
}

resource "nsxt_policy_nat_rule" "dnat_vsHttp" {
  count = (var.vmc.public_ip == true ? 1 : 0)
  display_name         = "dnat_VS-HTTP-${count.index}"
  action               = "DNAT"
  source_networks      = []
  destination_networks = [vmc_public_ip.public_ip_vsHttp[count.index].ip]
  translated_networks  = [cidrhost(var.vmc.network_vip.cidr, var.vmc.network_vip.ipStartPool + count.index)]
  gateway_path         = "/infra/tier-1s/cgw"
  logging              = false
  firewall_match       = "MATCH_INTERNAL_ADDRESS"
}

resource "nsxt_policy_nat_rule" "dnat_vsDns" {
  depends_on = [nsxt_policy_nat_rule.dnat_vsHttp]
  count = (var.vmc.public_ip == true ? 1 : 0)
  display_name         = "dnat_VS-DNS-${count.index}"
  action               = "DNAT"
  source_networks      = []
  destination_networks = [vmc_public_ip.public_ip_vsDns[count.index].ip]
  translated_networks  = [cidrhost(var.vmc.network_vip.cidr, var.vmc.network_vip.ipStartPool + 1 + count.index)]
  gateway_path         = "/infra/tier-1s/cgw"
  logging              = false
  firewall_match       = "MATCH_INTERNAL_ADDRESS"
}

resource "nsxt_policy_group" "avi_networks_with_application" {
  count = (var.vmc.application == true ? 1 : 0)
  display_name = "all Avi Networks"
  domain       = "cgw"
  description  = "all Avi Networks"
  criteria {
    ipaddress_expression {
      ip_addresses = [var.vmc.network_mgmt.cidr, var.vmc.network_backend.cidr]
    }
  }
}

resource "nsxt_policy_group" "avi_networks_without_application" {
  count = (var.vmc.application == false ? 1 : 0)
  display_name = "all Avi Networks"
  domain       = "cgw"
  description  = "all Avi Networks"
  criteria {
    ipaddress_expression {
      ip_addresses = [var.vmc.network_mgmt.cidr]
    }
  }
}

resource "nsxt_policy_group" "controller" {
  count = var.controller["count"]
  display_name = "controller${count.index}"
  domain       = "cgw"
  description  = "Avi Controller${count.index} Public and Private IPs"
  criteria {
    ipaddress_expression {
      ip_addresses = [vmc_public_ip.public_ip_controller[count.index].ip, vsphere_virtual_machine.controller[count.index].default_ip_address]
    }
  }
}

resource "nsxt_policy_group" "jump" {
  display_name = "jump"
  domain       = "cgw"
  description  = "Jump Public and Private IPs"
  criteria {
    ipaddress_expression {
      ip_addresses = [vmc_public_ip.public_ip_jump.ip, vsphere_virtual_machine.jump.default_ip_address]
    }
  }
}

resource "nsxt_policy_group" "vsHttp" {
  count = (var.vmc.public_ip == true ? 1 : 0)
  display_name = "group-VS-Http-${count.index}"
  domain       = "cgw"
  description  = "group-VS-Http-${count.index}"
  criteria {
    ipaddress_expression {
      ip_addresses = [vmc_public_ip.public_ip_vsHttp[count.index].ip, cidrhost(var.vmc.network_vip.cidr, var.vmc.network_vip.ipStartPool + count.index)]
    }
  }
}

resource "nsxt_policy_group" "vsDns" {
  count = (var.vmc.public_ip == true ? 1 : 0)
  depends_on = [nsxt_policy_group.vsHttp]
  display_name = "group-VS-Dns-${count.index}"
  domain       = "cgw"
  description  = "group-VS-Dns-${count.index}"
  criteria {
    ipaddress_expression {
      ip_addresses = [vmc_public_ip.public_ip_vsDns[count.index].ip, cidrhost(var.vmc.network_vip.cidr, var.vmc.network_vip.ipStartPool + 1 + count.index)]
    }
  }
}

resource "nsxt_policy_service" "serviceHttp" {
  description = "Avi HTTP VS provisioned by Terraform"
  display_name = "Avi HTTP VS provisioned by Terraform"
  l4_port_set_entry {
    display_name = "TCP80 and TCP443"
    description = "TCP80 and TCP443"
    protocol = "TCP"
    destination_ports = ["80", "443"]
  }
}

resource "nsxt_policy_service" "serviceDns" {
  description = "Avi DNS VS provisioned by Terraform"
  display_name = "Avi DNS VS provisioned by Terraform"
  l4_port_set_entry {
    display_name = "DNS53"
    description = "DNS53"
    protocol = "UDP"
    destination_ports = ["53"]
  }
}

resource "nsxt_policy_predefined_gateway_policy" "cgw_vsHttp" {
  path = "/infra/domains/cgw/gateway-policies/default"
  count = (var.vmc.dfw_rules == true ? 1 : 0)
  rule {
    action = "ALLOW"
    destination_groups    = [nsxt_policy_group.vsHttp[count.index].path]
    destinations_excluded = false
    direction             = "IN_OUT"
    disabled              = false
    display_name          = "HTTP VS - ${count.index}"
    ip_version            = "IPV4_IPV6"
    logged                = false
    profiles              = []
    scope                 = ["/infra/labels/cgw-public"]
    services              = [nsxt_policy_service.serviceHttp.path]
    source_groups         = []
    sources_excluded      = false
  }
}

resource "nsxt_policy_predefined_gateway_policy" "cgw_vsDns" {
  path = "/infra/domains/cgw/gateway-policies/default"
  count = (var.vmc.dfw_rules == true ? 1 : 0)
  rule {
    action = "ALLOW"
    destination_groups    = [nsxt_policy_group.vsDns[count.index].path]
    destinations_excluded = false
    direction             = "IN_OUT"
    disabled              = false
    display_name          = "DNS VS - ${count.index}"
    ip_version            = "IPV4_IPV6"
    logged                = false
    profiles              = []
    scope                 = ["/infra/labels/cgw-public"]
    services              = [nsxt_policy_service.serviceDns.path]
    source_groups         = []
    sources_excluded      = false
  }
}

resource "nsxt_policy_predefined_gateway_policy" "cgw_outbound_with_application" {
  count = (var.vmc.application == true ? 1 : 0)
  path = "/infra/domains/cgw/gateway-policies/default"
  rule {
    action = "ALLOW"
    destination_groups    = []
    destinations_excluded = false
    direction             = "IN_OUT"
    disabled              = false
    display_name          = "Outbound Internet"
    ip_version            = "IPV4_IPV6"
    logged                = false
    profiles              = []
    scope                 = ["/infra/labels/cgw-public"]
    services              = []
    source_groups         = [nsxt_policy_group.avi_networks_with_application[0].path]
    sources_excluded      = false
  }
}

resource "nsxt_policy_predefined_gateway_policy" "cgw_outbound_without_application" {
  count = (var.vmc.application == false ? 1 : 0)
  path = "/infra/domains/cgw/gateway-policies/default"
  rule {
    action = "ALLOW"
    destination_groups    = []
    destinations_excluded = false
    direction             = "IN_OUT"
    disabled              = false
    display_name          = "Outbound Internet"
    ip_version            = "IPV4_IPV6"
    logged                = false
    profiles              = []
    scope                 = ["/infra/labels/cgw-public"]
    services              = []
    source_groups         = [nsxt_policy_group.avi_networks_without_application[0].path]
    sources_excluded      = false
  }
}

resource "nsxt_policy_predefined_gateway_policy" "cgw_controller" {
  path = "/infra/domains/cgw/gateway-policies/default"
  count = var.controller["count"]
  rule {
    action = "ALLOW"
    destination_groups    = [nsxt_policy_group.controller[count.index].path]
    destinations_excluded = false
    direction             = "IN_OUT"
    disabled              = false
    display_name          = "controller${count.index}"
    ip_version            = "IPV4_IPV6"
    logged                = false
    profiles              = []
    scope                 = ["/infra/labels/cgw-public"]
    services              = []
    source_groups         = []
    sources_excluded      = false
  }
}

resource "nsxt_policy_predefined_gateway_policy" "cgw_jump" {
  path = "/infra/domains/cgw/gateway-policies/default"
  rule {
    action = "ALLOW"
    destination_groups    = [nsxt_policy_group.jump.path]
    destinations_excluded = false
    direction             = "IN_OUT"
    disabled              = false
    display_name          = "jump"
    ip_version            = "IPV4_IPV6"
    logged                = false
    profiles              = []
    scope                 = ["/infra/labels/cgw-public"]
    services              = []
    source_groups         = []
    sources_excluded      = false
  }
}
