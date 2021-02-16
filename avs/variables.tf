variable "avi_password" {}
variable "avi_username" {}
variable "aviOvaFile" {}
variable "ubuntuOvaFile" {}
variable "privateKeyFile" {}
variable "publicKeyFile" {}
variable "vsphere_username" {}
variable "vsphere_password" {}
variable "nsx_username" {}
variable "nsx_password" {}


variable "contentLibrary" {
  default = {
    name = "Content Library Build Avi"
    description = "Content Library Build Avi"
  }
}

variable "controller" {
  default = {
    cpu = 8
    memory = 24768
    disk = 128
    count = "1"
    floatingIp = "1.1.1.1"
    wait_for_guest_net_timeout = 2
    private_key_path = "~/.ssh/cloudKey"
    environment = "VMWARE"
    dns =  ["8.8.8.8", "8.8.4.4"]
    ntp = ["95.81.173.155", "188.165.236.162"]
    from_email = "avicontroller@avidemo.fr"
    se_in_provider_context = "false"
    tenant_access_to_provider_se = "true"
    tenant_vrf = "false"
    aviCredsJsonFile = "~/.creds.json"
  }
}

variable "jump" {
  type = map
  default = {
    name = "jump"
    cpu = 2
    memory = 4096
    disk = 24
    wait_for_guest_net_routable = "false"
    aviSdkVersion = "18.2.9"
    username = "ubuntu"
  }
}

variable "ansible" {
  type = map
  default = {
    version = "2.9.12"
    directory = "ansible"
  }
}

variable "backend" {
  default = {
    cpu = 1
    memory = 2048
    disk = 10
    wait_for_guest_net_routable = "false"
    nsxtGroup = {
      name = "n1-avi-backend"
      description = "Created by TF - For Avi Build"
      tag = "n1-avi-backend"
    }
  }
}

variable "client" {
  type = map
  default = {
    cpu = 1
    memory = 2048
    disk = 10
    wait_for_guest_net_routable = "false"
  }
}

variable "nsxt" {
  default = {
    name = "cloudAvs" # static
    application = true # dynamic
    server = "10.7.0.3" # dynamic
    dhcp_enabled = "false" # static
    obj_name_prefix = "AVINSXT" # static
    domains = [
      {
        name = "avi.avs.info" # dynamic if nsxt.application == true
      }
    ]
    transport_zone = {
      name = "TNT69-OVERLAY-TZ" # dynamic
    }
    tier1s = [
      {
        name     = "T1_AVI" # dynamic
        description = "Created by TF - For Avi Build"
        route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED", "TIER1_LB_VIP"] # static
        tier0 = "TNT69-T0" # dynamic
      }
    ]
    management_network = {
      name = "Avi_mgmt"
      tier1 = "T1_AVI"
      cidr = "192.168.55.0/24"
      ipStartPool = "11"
      ipEndPool = "50"
      type = "V4"
      dhcp_enabled = "no"
      exclude_discovered_subnets = "true"
      vcenter_dvs = "true"
    }
    network_vip = {
      name = "Avi_vip"
      tier1 = "T1_AVI"
      cidr = "192.168.56.0/24"
      type = "V4"
      ipStartPool = "11"
      ipEndPool = "50"
      exclude_discovered_subnets = "true"
      vcenter_dvs = "true"
      dhcp_enabled = "false"
      gateway = "1"
    }
    network_backend = {
      name = "Avi_backend"
      tier1 = "T1_AVI"
      cidr = "192.168.57.0/24"
    }
    vcenter = {
      server = "10.7.0.2" # dynamic
      dc = "SDDC-Datacenter" # static
      cluster = "Cluster-1" # static
      datastore = "vsanDatastore" # static
      resource_pool = "Cluster-1/Resources" # static
      folderApps = "Avi-Apps" # static
      folderAvi = "Avi-Controllers" # static
      content_library = {
        name = "Avi SE Content Library" # static
        description = "TF built - Avi SE Content Library" # static
      }
    }
    serviceEngineGroup = [ # dynamic
      {
        name = "Default-Group"
        ha_mode = "HA_MODE_SHARED"
        min_scaleout_per_vs = 2
        buffer_se = 1
        extra_shared_config_memory = 0
        vcenter_folder = "Avi-SE"
        vcpus_per_se = 1
        memory_per_se = 2048
        disk_per_se = 25
        realtime_se_metrics = {
          enabled = true
          duration = 0
        }
      },
      {
        name = "seGroupCpuAutoScale"
        ha_mode = "HA_MODE_SHARED"
        min_scaleout_per_vs = 2
        buffer_se = 0
        extra_shared_config_memory = 0
        vcenter_folder = "Avi-SE"
        vcpus_per_se = 1
        memory_per_se = 1024
        disk_per_se = 25
        auto_rebalance = true
        auto_rebalance_interval = 30
        auto_rebalance_criteria = [
          "SE_AUTO_REBALANCE_CPU"
        ]
        realtime_se_metrics = {
          enabled = true
          duration = 0
        }
      },
      {
        name = "seGroupGslb"
        ha_mode = "HA_MODE_SHARED"
        min_scaleout_per_vs = 1
        buffer_se = 0
        extra_shared_config_memory = 2000
        vcenter_folder = "Avi-SE"
        vcpus_per_se = 2
        memory_per_se = 8192
        disk_per_se = 25
        realtime_se_metrics = {
          enabled = true
          duration = 0
        }
      }
    ]
    pool = {
      name = "pool1"
      lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
    }
    pool_nsxt_group = {
      name = "pool2BasedOnNsxtGroup"
      lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
      nsxt_group_name = "n1-avi-backend"
    }
    virtualservices = {
      http = [
        {
          name = "app1"
          pool_ref = "pool1"
          services: [
            {
              port = 80
              enable_ssl = "false"
            },
            {
              port = 443
              enable_ssl = "true"
            }
          ]
        },
        {
          name = "app2-se-cpu-auto-scale"
          pool_ref = "pool1"
          services: [
            {
              port = 80
              enable_ssl = "false"
            },
            {
              port = 443
              enable_ssl = "true"
            }
          ]
          se_group_ref: "seGroupCpuAutoScale"
        },
        {
          name = "app3-nsxtGroupBased"
          pool_ref = "pool2BasedOnNsxtGroup"
          services: [
            {
              port = 80
              enable_ssl = "false"
            },
            {
              port = 443
              enable_ssl = "true"
            }
          ]
        },
      ]
      dns = [
        {
          name = "app4-dns"
          services: [
            {
              port = 53
            }
          ]
        },
        {
          name = "app5-gslb"
          services: [
            {
              port = 53
            }
          ]
          se_group_ref: "seGroupGslb"
        }
      ]
    }
  }
}