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

module "tenant_red" {
  source = "../tenants/tenant_red"
  data_center         = var.data_center
  cluster             = var.cluster
  workload_datastore  = var.workload_datastore
  compute_pool        = var.compute_pool
  vm_folder           = var.vm_folder
}

module "tenant_blue" {
  source = "../tenants/tenant_blue"
  data_center         = var.data_center
  cluster             = var.cluster
  workload_datastore  = var.workload_datastore
  compute_pool        = var.compute_pool
  vm_folder           = var.vm_folder
}


module "tenant_cs" {
  source = "../tenants/tenant_cs"
  data_center         = var.data_center
  cluster             = var.cluster
  workload_datastore  = var.workload_datastore
  compute_pool        = var.compute_pool
  vm_folder           = var.vm_folder
}
