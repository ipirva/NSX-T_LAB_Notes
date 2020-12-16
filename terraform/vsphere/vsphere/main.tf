data "vsphere_datacenter" "dc" {
  name          = var.data_center
}
data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_folder" "folder" {
  path          = var.vm_folder
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}
resource "vsphere_resource_pool" "pool" {
  name                    = var.compute_pool
  parent_resource_pool_id = data.vsphere_compute_cluster.compute_cluster.resource_pool_id
}
