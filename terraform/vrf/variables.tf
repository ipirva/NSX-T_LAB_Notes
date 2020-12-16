# NSX Manager
variable "nsx_manager" {
    default = "10.0.0.66"
}

# Username & Password for NSX-T Manager
variable "nsx_username" {
  default = "admin"
}

variable "nsx_password" {
    default = "EvoSddc!2016"
}

# NSX tag which can be used later
variable "nsx_tag_scope" {
  default = "Created by"
}

variable "nsx_tag" {
  default = "Terraform"
}

# Enter Edge Nodes Display Name. Required for external interfaces.
variable "edge_node_1" {
   default = "nsxt-edge-node-11"
}
variable "edge_node_2" {
   default = "nsxt-edge-node-12"
}
