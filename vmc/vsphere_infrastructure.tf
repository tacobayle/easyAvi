data "vsphere_datacenter" "dc" {
  name = var.vmc.vcenter.dc
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vmc.vcenter.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name = var.vmc.vcenter.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.vmc.vcenter.resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "networkMgmt" {
  name = var.vmc.network_mgmt.name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "networkBackend" {
  count = (var.vmc.application == true ? 1 : 0)
  name = var.vmc.network_backend.name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "networkVip" {
  name = var.vmc.network_vip.name
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_folder" "folderController" {
  path          = var.vmc.vcenter.folderAvi
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_folder" "folderApp" {
  count         = (var.vmc.application == true ? 1 : 0)
  path          = var.vmc.vcenter.folderApps
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_tag_category" "ansible_group_backend" {
  name = "ansible_group_backend"
  cardinality = "SINGLE"
  associable_types = [
    "VirtualMachine",
  ]
}

resource "vsphere_tag_category" "ansible_group_client" {
  name = "ansible_group_client"
  cardinality = "SINGLE"
  associable_types = [
    "VirtualMachine",
  ]
}

resource "vsphere_tag_category" "ansible_group_controller" {
  name = "ansible_group_controller"
  cardinality = "SINGLE"
  associable_types = [
    "VirtualMachine",
  ]
}

resource "vsphere_tag_category" "ansible_group_jump" {
  name = "ansible_group_jump"
  cardinality = "SINGLE"
  associable_types = [
    "VirtualMachine",
  ]
}