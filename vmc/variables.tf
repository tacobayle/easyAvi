variable "avi_password" {}
variable "avi_username" {}
variable "vmc_vsphere_user" {}
variable "vmc_vsphere_password" {}
variable "vmc_vsphere_server" {}
variable "vmc_nsx_server" {}
variable "vmc_nsx_token" {}
variable "vmc_org_id" {}
variable "privateKeyFile" {}
variable "publicKeyFile" {}
variable "ubuntuOvaFile" {}
variable "aviOvaFile" {}

variable "contentLibrary" {
  default = {
    name = "EasyAvi - Created by TF - Build"
    description = "EasyAvi - Created by TF - Build"
  }
}

variable "controller" {
  default = {
    cpu = 8
    memory = 24768
    disk = 128
    count = "1"
    wait_for_guest_net_timeout = 2
    environment = "VMWARE"
    dns =  ["8.8.8.8", "8.8.4.4"]
    ntp = ["95.81.173.155", "188.165.236.162"]
    floatingIp = "1.1.1.1"
    from_email = "avicontroller@avidemo.fr"
    se_in_provider_context = "false"
    tenant_access_to_provider_se = "true"
    tenant_vrf = "false"
  }
}

variable "jump" {
  type = map
  default = {
    name = "jump"
    cpu = 2
    memory = 4096
    disk = 20
    wait_for_guest_net_timeout = 2
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    avisdkVersion = "18.2.9"
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
  type = map
  default = {
    cpu = 2
    memory = 4096
    disk = 20
    wait_for_guest_net_routable = "false"
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    url_demovip_server = "https://github.com/tacobayle/demovip_server"
    username = "ubuntu"
  }
}

//variable "client" {
//  type = map
//  default = {
//    cpu = 2
//    memory = 4096
//    disk = 20
//    template_name = "ubuntu-bionic-18.04-cloudimg-template"
//  }
//}

variable "vmc" {
  default = {
    name = "cloudVmc"
    application = false
    public_ip = false
    dfw_rules = false
    vcenter = {
      dc = "SDDC-Datacenter"
      cluster = "Cluster-1"
      datastore = "WorkloadDatastore"
      resource_pool = "Cluster-1/Resources"
      folderApps = "Avi-Apps"
      folderAvi = "Avi-Controllers"
    }
    domains = [
      {
        name = "vmc.avidemo.fr" # dynamic - read if application == 1
      }
    ]
    network_mgmt = {
      name = "avi-mgmt" # dynamic
      cidr = "10.1.1.0/24" # dynamic -  for NSX-T segment
    }
    network_vip = {
      name = "avi-vip"
      cidr = "10.1.3.0/24" # dynamic
      dhcp_enabled = "no"
      ipStartPool = "100" # dynamic for Avi IPAM - make sure there is no conflict with NSXT DHCP pool
      ipEndPool = "119" # dynamic for Avi IPAM - make sure there is no conflict with NSXT DHCP pool
      defaultGateway = "1" # dynamic for Avi default route
    }
    network_backend = {
      name = "avi-backend" # dynamic
      cidr = "10.1.2.0/24" # dynamic
    }
    serviceEngineGroup = [
      {
        name = "Default-Group" # name of the first SE group can't be changed
        numberOfSe = "2" # dynamic
        ha_mode = "HA_MODE_SHARED" # dynamic (HA_MODE_LEGACY_ACTIVE_STANDBY|HA_MODE_SHARED)
        min_scaleout_per_vs = "1" # dynamic
        disk_per_se = "25" # dynamic
        vcpus_per_se = "2" # dynamic
        cpu_reserve = "true" # dynamic
        memory_per_se = "4096" # dynamic
        mem_reserve = "true" # dynamic
        extra_shared_config_memory = "0" # dynamic
        networks = [ "avi-vip"] # dynamic
      },
      {
        name = "seGroupGslb" # dynamic
        numberOfSe = "1" # dynamic
        ha_mode = "HA_MODE_SHARED" # dynamic (HA_MODE_LEGACY_ACTIVE_STANDBY|HA_MODE_SHARED)
        min_scaleout_per_vs = "1" # dynamic
        disk_per_se = "25" # dynamic
        vcpus_per_se = "2" # dynamic
        cpu_reserve = "true" # dynamic
        memory_per_se = "8192" # dynamic
        mem_reserve = "true" # dynamic
        extra_shared_config_memory = "2000" # dynamic
        networks = [ "avi-vip"] # dynamic
      }
    ]
    httppolicyset = [
      {
        name = "http-request-policy-app1-content-switching-vmc"
        http_request_policy = {
          rules = [
            {
              name = "Rule 1"
              match = {
                path = {
                  match_criteria = "CONTAINS"
                  match_str = ["hello", "world"]
                }
              }
              rewrite_url_action = {
                path = {
                  type = "URI_PARAM_TYPE_TOKENIZED"
                  tokens = [
                    {
                      type = "URI_TOKEN_TYPE_STRING"
                      str_value = "index.html"
                    }
                  ]
                }
                query = {
                  keep_query = true
                }
              }
              switching_action = {
                action = "HTTP_SWITCHING_SELECT_POOL"
                status_code = "HTTP_LOCAL_RESPONSE_STATUS_CODE_200"
                pool_ref = "/api/pool?name=pool1-hello-vmc"
              }
            },
            {
              name = "Rule 2"
              match = {
                path = {
                  match_criteria = "CONTAINS"
                  match_str = ["avi"]
                }
              }
              rewrite_url_action = {
                path = {
                  type = "URI_PARAM_TYPE_TOKENIZED"
                  tokens = [
                    {
                      type = "URI_TOKEN_TYPE_STRING"
                      str_value = ""
                    }
                  ]
                }
                query = {
                  keep_query = true
                }
              }
              switching_action = {
                action = "HTTP_SWITCHING_SELECT_POOL"
                status_code = "HTTP_LOCAL_RESPONSE_STATUS_CODE_200"
                pool_ref = "/api/pool?name=pool2-avi-vmc"
              }
            },
          ]
        }
      }
    ]
    pools = [
      {
        name = "pool1-hello-vmc"
        lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
      },
      {
        name = "pool2-avi-vmc"
        application_persistence_profile_ref = "System-Persistence-Client-IP"
        default_server_port = 8080
      }
    ]
    virtualservices = {
      http = [
        {
          name = "app1-content-switching-vmc"
          pool_ref = "pool2-avi-vmc"
          http_policies = [
            {
              http_policy_set_ref = "/api/httppolicyset?name=http-request-policy-app1-content-switching-vmc"
              index = 11
            }
          ]
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
          name = "dns"
          services: [
            {
              port = 53
            }
          ]
        },
      ]
    }
  }
}

