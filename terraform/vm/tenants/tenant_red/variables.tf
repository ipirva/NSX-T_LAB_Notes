variable "data_center" {}
variable "cluster" {}
variable "workload_datastore" {}
variable "compute_pool" {}
variable "vm_folder" {}

variable "network_tn_dvs" { default = "new-vi-vcenter-2-vi-cluster1-vds02" }

variable "network_tenant_red_1" { default = "seg-vrf-red-1" }
variable "network_tenant_red_2" { default = "seg-vrf-red-2" }

variable "network_management" { default = "vi-cluster1-vds-Mgmt" }

variable "vm_template" { default = "Ubuntu_641804Template_DHCP" }

variable "vm_username" { default = "ubuntu" }
variable "vm_password" { default = "" }
variable "vm_private_key_path" { default = "/home/ipirva/.ssh/my_id_rsa" }

