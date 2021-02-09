
resource "null_resource" "foo" {
  depends_on = [vsphere_virtual_machine.jump]
  connection {
    host        = split("/", var.jump["ipCidr"])[0]
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file(var.jump["private_key_path"])
  }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }

  provisioner "file" {
    source      = var.jump["private_key_path"]
    destination = "~/.ssh/${basename(var.jump["private_key_path"])}"
  }

  provisioner "file" {
    source      = var.ansible.directory
    destination = "~/ansible"
  }

  provisioner "remote-exec" {
    inline      = [
      "chmod 600 ~/.ssh/${basename(var.jump["private_key_path"])}",
      "cd ~/ansible ; ansible-playbook -i /opt/ansible/inventory/inventory.vmware.yml local.yml --extra-vars '{\"avi_username\": ${jsonencode(var.avi_username)}, \"avi_password\": ${jsonencode(var.avi_password)}, \"avi_version\": ${jsonencode(basename(var.aviOvaFile))}, \"controllerPrivateIps\": ${jsonencode(vsphere_virtual_machine.controller.*.default_ip_address)}, \"controller\": ${jsonencode(var.controller)}, \"nsxt\": ${jsonencode(var.nsxt)}, \"avi_backend_servers_nsxt\": ${jsonencode(vsphere_virtual_machine.backend.*.guest_ip_addresses)}}'",
    ]
  }
}

