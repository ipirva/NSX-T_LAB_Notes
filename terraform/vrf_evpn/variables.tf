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