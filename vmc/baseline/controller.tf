//resource "vsphere_tag" "ansible_group_controller" {
//  name             = "controller"
//  category_id      = vsphere_tag_category.ansible_group_controller.id
//}

resource "vsphere_virtual_machine" "controller" {
  count            = var.no_access_vcenter.controller.count
  name             = "${split(".ova", basename(var.no_access_vcenter.vcenter.contentLibrary.aviOvaFile))[0]}-${count.index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = data.vsphere_folder.folderController.path
  network_interface {
    network_id = data.vsphere_network.networkMgmt.id
  }

  num_cpus = var.no_access_vcenter.controller.cpu
  memory = var.no_access_vcenter.controller.memory
  wait_for_guest_net_timeout = var.no_access_vcenter.controller.wait_for_guest_net_timeout
  guest_id = "guestid-${split(".ova", basename(var.no_access_vcenter.vcenter.contentLibrary.aviOvaFile))[0]}-${count.index}"


  disk {
    size             = var.no_access_vcenter.controller.disk
    label            = "controller-${split(".ova", basename(var.no_access_vcenter.vcenter.contentLibrary.aviOvaFile))[0]}-${count.index}.lab_vmdk"
    thin_provisioned = true
  }

  clone {
    template_uuid = vsphere_content_library_item.avi.id
  }

//  tags = [
//        vsphere_tag.ansible_group_controller.id,
//  ]
}
