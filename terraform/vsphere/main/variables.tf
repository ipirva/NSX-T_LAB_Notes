# vsphere
variable "vsphere_username" {}
variable "vsphere_password" {}
variable "vsphere_server" {}

variable "data_center" { default = "new-vi-DC" }
variable "cluster" { default = "vi-cluster1" }
variable "workload_datastore" { default = "vi-cluster1-vSanDatastore" }
variable "compute_pool" { default = "Compute-Resource-Pool" }
variable "vm_folder" { default = "Workloads" }
