resource "vsphere_content_library" "library" {
  name            = var.contentLibrary.name
  storage_backing = [data.vsphere_datastore.datastore.id]
  description     = var.contentLibrary.description
}

resource "vsphere_content_library_item" "avi" {
  name        = "Avi OVA file"
  description = "Avi OVA file"
  library_id  = vsphere_content_library.library.id
  file_url = var.aviOvaFile
}

resource "vsphere_content_library_item" "ubuntu" {
  name        = "Ubuntu OVA file"
  description = "Ubuntu OVA file"
  library_id  = vsphere_content_library.library.id
  file_url = var.ubuntuOvaFile
}