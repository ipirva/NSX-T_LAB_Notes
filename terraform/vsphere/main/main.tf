terraform {
  required_providers {
    vsphere = {
      source = "vsphere"
      version = "~> 1.24"
    }
  }
}
provider "vsphere" {
  user                  = var.vsphere_username
  password              = var.vsphere_password
  vsphere_server        = var.vsphere_server
  allow_unverified_ssl  = true
}

module "vsphere" {
  source = "../vsphere"
  data_center         = var.data_center
  cluster             = var.cluster
  compute_pool        = var.compute_pool
  vm_folder           = var.vm_folder
}
