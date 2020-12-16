# Terraform Provider
terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = "3.1.0"
    }
  }
}

# NSX-T Manager Credentials
provider "nsxt" {
  host                  = var.nsx_manager
  username              = var.nsx_username
  password              = var.nsx_password
  allow_unverified_ssl  = true
  max_retries           = 10
  retry_min_delay       = 500
  retry_max_delay       = 5000
  retry_on_status_codes = [429]
}

# Data Sources we need for reference later
data "nsxt_policy_transport_zone" "overlay_tz" {
  display_name = "overlay-tz-vip-nsxmanager-cls1.vrack.vsphere.local"
}

data "nsxt_policy_transport_zone" "vlan_tz" {
  display_name = "VCF-edge_art-edge-cluster_uplink-tz"
}

data "nsxt_policy_edge_cluster" "edge_cluster" {
  display_name = "art-edge-cluster"
}

# DFW Services
data "nsxt_policy_service" "ssh" {
  display_name = "SSH"
}

data "nsxt_policy_service" "http" {
  display_name = "HTTP"
}

data "nsxt_policy_service" "https" {
  display_name = "HTTPS"
}

# T0 Provider
data "nsxt_policy_tier0_gateway" "t0_provider" {
  display_name = "T0_myMakCluster"
}

# Create VRF for Red Tenant
resource "nsxt_policy_tier0_gateway" "t0_vrf_red" {
  display_name         = "T0-VRF-Red-Tenant"
  description          = "T0 VRF Red Tenant"
  failover_mode        = "NON_PREEMPTIVE"
  default_rule_logging = false
  enable_firewall      = false
  ha_mode              = "ACTIVE_ACTIVE"
  edge_cluster_path    = data.nsxt_policy_edge_cluster.edge_cluster.path

  vrf_config {
    gateway_path        = data.nsxt_policy_tier0_gateway.t0_provider.path
    route_distinguisher = "65003:10"
    evpn_transit_vni    = 76001
    route_target {
      auto_mode      = false
      import_targets = ["65003:10"]
      export_targets = ["65003:10"]
    }
  }

  bgp_config {
    ecmp            = true
    multipath_relax = true
  }

  tag {
    scope = "tenant"
    tag   = "red"
  }

  tag {
    scope = var.nsx_tag_scope
    tag   = var.nsx_tag
  }
}

# Create VRF for Blue Tenant
resource "nsxt_policy_tier0_gateway" "t0_vrf_blue" {
  display_name         = "T0-VRF-Blue-Tenant"
  description          = "T0 VRF Blue Tenant"
  failover_mode        = "NON_PREEMPTIVE"
  default_rule_logging = false
  enable_firewall      = false
  ha_mode              = "ACTIVE_ACTIVE"
  edge_cluster_path    = data.nsxt_policy_edge_cluster.edge_cluster.path

  vrf_config {
    gateway_path        = data.nsxt_policy_tier0_gateway.t0_provider.path
    route_distinguisher = "65003:20"
    evpn_transit_vni    = 76002
    route_target {
      auto_mode      = false
      import_targets = ["65003:20"]
      export_targets = ["65003:20"]
    }
  }

  bgp_config {
    ecmp            = true
    multipath_relax = true
  }

  tag {
    scope = "tenant"
    tag   = "blue"
  }

  tag {
    scope = var.nsx_tag_scope
    tag   = var.nsx_tag
  }
}

# Create VRF for CS Tenant
resource "nsxt_policy_tier0_gateway" "t0_vrf_cs" {
  display_name         = "T0-VRF-CS-Tenant"
  description          = "T0 VRF CS Tenant"
  failover_mode        = "NON_PREEMPTIVE"
  default_rule_logging = false
  enable_firewall      = false
  ha_mode              = "ACTIVE_ACTIVE"
  edge_cluster_path    = data.nsxt_policy_edge_cluster.edge_cluster.path

  vrf_config {
    gateway_path        = data.nsxt_policy_tier0_gateway.t0_provider.path
    route_distinguisher = "65003:65003"
    evpn_transit_vni    = 76666
    route_target {
      auto_mode      = false
      import_targets = ["65003:65003"]
      export_targets = ["65003:65003"]
    }
  }

  bgp_config {
    ecmp            = true
    multipath_relax = true
  }

  tag {
    scope = "tenant"
    tag   = "cs"
  }

  tag {
    scope = var.nsx_tag_scope
    tag   = var.nsx_tag
  }
}

# Create Red Tier-1 Gateway
resource "nsxt_policy_tier1_gateway" "t1_gw_red" {
  description               = "Red Tenant Tier-1"
  display_name              = "T1-Red"
  edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster.path
  failover_mode             = "NON_PREEMPTIVE"
  default_rule_logging      = "false"
  enable_firewall           = "true"
  enable_standby_relocation = "false"
  tier0_path                = nsxt_policy_tier0_gateway.t0_vrf_red.path
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]

  tag {
    scope = "tenant"
    tag   = "red"
  }

  tag {
    scope = var.nsx_tag_scope
    tag   = var.nsx_tag
  }

  route_advertisement_rule {
    name                      = "Tier 1 Networks"
    action                    = "PERMIT"
    subnets                   = ["172.17.10.0/24", "172.17.11.0/24"]
    prefix_operator           = "GE"
    route_advertisement_types = ["TIER1_CONNECTED"]
  }
}

# Create Blue Tier-1 Gateway
resource "nsxt_policy_tier1_gateway" "t1_gw_blue" {
  description               = "Blue Tenant Tier-1"
  display_name              = "T1-Blue"
  edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster.path
  failover_mode             = "NON_PREEMPTIVE"
  default_rule_logging      = "false"
  enable_firewall           = "true"
  enable_standby_relocation = "false"
  tier0_path                = nsxt_policy_tier0_gateway.t0_vrf_blue.path
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]

  tag {
    scope = "tenant"
    tag   = "blue"
  }

  tag {
    scope = var.nsx_tag_scope
    tag   = var.nsx_tag
  }

  route_advertisement_rule {
    name                      = "Tier 1 Networks"
    action                    = "PERMIT"
    subnets                   = ["172.17.20.0/24"]
    prefix_operator           = "GE"
    route_advertisement_types = ["TIER1_CONNECTED"]
  }
}

# Create CS Tier-1 Gateway
resource "nsxt_policy_tier1_gateway" "t1_gw_cs" {
  description               = "CS Tenant Tier-1"
  display_name              = "T1-CS"
  edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster.path
  failover_mode             = "NON_PREEMPTIVE"
  default_rule_logging      = "false"
  enable_firewall           = "true"
  enable_standby_relocation = "false"
  tier0_path                = nsxt_policy_tier0_gateway.t0_vrf_cs.path
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]

  tag {
    scope = "tenant"
    tag   = "cs"
  }

  tag {
    scope = var.nsx_tag_scope
    tag   = var.nsx_tag
  }

  route_advertisement_rule {
    name                      = "Tier 1 Networks"
    action                    = "PERMIT"
    subnets                   = ["172.17.66.0/24"]
    prefix_operator           = "GE"
    route_advertisement_types = ["TIER1_CONNECTED"]
  }
}

# Create Tenant Segments
resource "nsxt_policy_segment" "seg_vrf_red_1" {
  display_name        = "seg-vrf-red-1"
  description         = "Red Tenant Segment 1"
  connectivity_path   = nsxt_policy_tier1_gateway.t1_gw_red.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path

  subnet {
    cidr = "172.17.10.1/24"
  }

  tag {
    scope = "tenant"
    tag   = "red"
  }

  tag {
    scope = var.nsx_tag_scope
    tag   = var.nsx_tag
  }
}

resource "nsxt_policy_segment" "seg_vrf_red_2" {
  display_name        = "seg-vrf-red-2"
  description         = "Red Tenant Segment 2"
  connectivity_path   = nsxt_policy_tier1_gateway.t1_gw_red.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path

  subnet {
    cidr = "172.17.11.1/24"
  }

  tag {
    scope = "tenant"
    tag   = "red"
  }

  tag {
    scope = var.nsx_tag_scope
    tag   = var.nsx_tag
  }
}

resource "nsxt_policy_segment" "seg_vrf_blue_1" {
  display_name        = "seg-vrf-blue-1"
  description         = "Blue Tenant Segment 1"
  connectivity_path   = nsxt_policy_tier1_gateway.t1_gw_blue.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path

  subnet {
    cidr = "172.17.20.1/24"
  }

  tag {
    scope = "tenant"
    tag   = "blue"
  }

  tag {
    scope = var.nsx_tag_scope
    tag   = var.nsx_tag
  }
}

resource "nsxt_policy_segment" "seg_vrf_cs_1" {
  display_name        = "seg-vrf-cs-1"
  description         = "CS Tenant Segment 1"
  connectivity_path   = nsxt_policy_tier1_gateway.t1_gw_cs.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path

  subnet {
    cidr = "172.17.66.1/24"
  }

  tag {
    scope = "tenant"
    tag   = "cs"
  }

  tag {
    scope = var.nsx_tag_scope
    tag   = var.nsx_tag
  }
}

# Create Security Groups
resource "nsxt_policy_group" "web_servers" {
  display_name = "Web server"
  description  = "My Web servers"
  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "CONTAINS"
      value       = "web"
    }
  }
  tag {
    scope = var.nsx_tag_scope
    tag   = var.nsx_tag
  }
}

resource "nsxt_policy_group" "app_servers" {
  display_name = "App server"
  description  = "My App servers"

  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "CONTAINS"
      value       = "app"
    }
  }
  tag {
    scope = var.nsx_tag_scope
    tag   = var.nsx_tag
  }
}


resource "nsxt_policy_group" "red_servers" {
  display_name = "Tenant Red servers"
  description  = "Red's servers"

  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "CONTAINS"
      value       = "red"
    }
  }
  tag {
    scope = var.nsx_tag_scope
    tag   = var.nsx_tag
  }
}

resource "nsxt_policy_group" "blue_servers" {
  display_name = "Tenant Blue servers"
  description  = "Blue's servers"

  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "CONTAINS"
      value       = "blue"
    }
  }
  tag {
    scope = var.nsx_tag_scope
    tag   = var.nsx_tag
  }
}

# Create Custom Services
resource "nsxt_policy_service" "service_tcp8443" {
  description  = "HTTPS custom service"
  display_name = "TCP 8443"

  l4_port_set_entry {
    display_name      = "TCP8443"
    description       = "TCP port 8443 entry"
    protocol          = "TCP"
    destination_ports = ["8443"]
  }

  tag {
    scope = var.nsx_tag_scope
    tag   = var.nsx_tag
  }
}

# Create Security Policies
resource "nsxt_policy_security_policy" "allow_blue" {
  display_name = "Blue tenant"
  description  = "Terraform provisioned Security Policy"
  category     = "Application"
  locked       = false
  stateful     = true
  tcp_strict   = true
  scope        = [nsxt_policy_group.web_servers.path]

  rule {
    display_name       = "Allow SSH to Blue Servers"
    destination_groups = [nsxt_policy_group.blue_servers.path]
    action             = "ALLOW"
    services           = [data.nsxt_policy_service.ssh.path]
    logged             = true
    scope              = [nsxt_policy_group.blue_servers.path]
  }

  rule {
    display_name       = "Allow HTTPS to Web Servers"
    destination_groups = [nsxt_policy_group.web_servers.path]
    action             = "ALLOW"
    services           = [data.nsxt_policy_service.https.path]
    logged             = true
    scope              = [nsxt_policy_group.web_servers.path]
  }

  rule {
    display_name       = "Allow TCP 8443 to App Servers"
    source_groups      = [nsxt_policy_group.web_servers.path]
    destination_groups = [nsxt_policy_group.app_servers.path]
    action             = "ALLOW"
    services           = [nsxt_policy_service.service_tcp8443.path]
    logged             = true
    scope              = [nsxt_policy_group.web_servers.path, nsxt_policy_group.app_servers.path]
  }

  rule {
    display_name = "Any Deny"
    action       = "REJECT"
    logged       = false
    scope        = [nsxt_policy_group.blue_servers.path]
  }
}
