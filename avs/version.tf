terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
      version = "v3.1.1"
    }
    vsphere = {
      source = "hashicorp/vsphere"
      version = "v1.24.3"
    }
    template = {
      source = "hashicorp/template"
      version = "v2.2.0"
    }
    null = {
      source = "hashicorp/null"
      version = "v3.0.0"
    }
  }
  required_version = ">= 0.13"
}

