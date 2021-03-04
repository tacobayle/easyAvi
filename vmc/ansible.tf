resource "null_resource" "foo" {
  depends_on = [nsxt_policy_predefined_gateway_policy.cgw_jump]
  connection {
   host        = vmc_public_ip.public_ip_jump.ip
   type        = "ssh"
   agent       = false
   user        = var.jump.username
   private_key = file(var.privateKeyFile)
  }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }

  provisioner "file" {
  source      = var.privateKeyFile
  destination = "~/.ssh/${basename(var.privateKeyFile)}"
  }

  provisioner "file" {
  source      = var.ansible.directory
  destination = "~/ansible"
  }

  provisioner "remote-exec" {
    inline      = [
      "chmod 600 ~/.ssh/${basename(var.privateKeyFile)}",
      "export ANSIBLE_NOCOLOR=\"True\" ; cd ~/ansible ; ansible-playbook -i /opt/ansible/inventory/inventory.vmware.yml local.yml --extra-vars '{\"vmc_vsphere_server\": ${jsonencode(var.vmc_vsphere_server)}, \"avi_version\": ${jsonencode(basename(var.aviOvaFile))}, \"controllerPrivateIps\": ${jsonencode(vsphere_virtual_machine.controller.*.default_ip_address)}, \"vmc_vsphere_password\": ${jsonencode(var.vmc_vsphere_password)}, \"controller\": ${jsonencode(var.controller)}, \"vmc_vsphere_user\": ${jsonencode(var.vmc_vsphere_user)}, \"vmc\": ${jsonencode(var.vmc)}, \"avi_username\": ${jsonencode(var.avi_username)}, \"avi_password\": ${jsonencode(var.avi_password)}, \"avi_backend_servers_vmc\": ${jsonencode(vsphere_virtual_machine.backend.*.guest_ip_addresses)}}'",
    ]
  }
}

resource "null_resource" "local_file" {
  provisioner "local-exec" {
    command = "touch ${vmc_vsphere_server}.ran"
  }
}
