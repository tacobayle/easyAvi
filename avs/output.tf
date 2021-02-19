# Outputs for Terraform

output "jump" {
  value = vsphere_virtual_machine.jump.default_ip_address
}

output "controllers" {
  value = vsphere_virtual_machine.controller.*.default_ip_address
}

output "backends" {
  value = vsphere_virtual_machine.backend.*.guest_ip_addresses
}

output "client" {
  value = vsphere_virtual_machine.client.*.guest_ip_addresses
}