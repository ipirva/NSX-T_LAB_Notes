data "vsphere_datacenter" "dc" {
  name          = var.data_center
}
data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_datastore" "datastore" {
  name          = var.workload_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_resource_pool" "pool" {
  name          = var.compute_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_distributed_virtual_switch" "dvs" {
  name          = var.network_tn_dvs
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_network" "network_tenant_red_1" {
  name          = var.network_tenant_red_1
  datacenter_id = data.vsphere_datacenter.dc.id
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.dvs.id
}
data "vsphere_network" "network_tenant_red_2" {
  name          = var.network_tenant_red_2
  datacenter_id = data.vsphere_datacenter.dc.id
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.dvs.id
}
data "vsphere_network" "network_management" {
  name          = var.network_management
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_virtual_machine" "vm_template" {
  name          = var.vm_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Configure VM09
resource "vsphere_virtual_machine" "vm09" {
  name             = "testvm_vm09"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.vm_folder
  num_cpus = 1
  memory   = 2048
  guest_id = data.vsphere_virtual_machine.vm_template.guest_id
  network_interface {
    network_id = data.vsphere_network.network_management.id
  }
  network_interface {
    network_id = data.vsphere_network.network_tenant_red_1.id
  }
  cdrom {
    client_device = true
  }
  disk {
    label = "disk0"
    size  = 10
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.vm_template.id
    customize {
      linux_options {
        host_name  = "vm09"
        domain     = "tenantred.com"
        hw_clock_utc = true
        time_zone = "UTC"
      }
      network_interface {}
      network_interface {
        ipv4_address = "172.17.10.9"
        ipv4_netmask = 24
      }
      ipv4_gateway = "172.17.10.1"
      dns_suffix_list = ["tenantred.com"]
      dns_server_list = ["8.8.8.8"]

    }
  }
  wait_for_guest_net_routable = false
}

resource "null_resource" "vm09_configure" {
  depends_on = [vsphere_virtual_machine.vm09]
  provisioner "file" {
    connection {
      type        = "ssh"
      host        = vsphere_virtual_machine.vm09.default_ip_address
      insecure    = true
      user        = var.vm_username
      # password = var.vm_password
      private_key = file(var.vm_private_key_path)
    }
    source      = "../tenants/tenant_red/vm_customization_script.sh"
    destination = "/tmp/vm_customization_script.sh"
  }

  # Execute script
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = vsphere_virtual_machine.vm09.default_ip_address
      insecure    = true
      user        = var.vm_username
      # password = var.vm_password
      private_key = file(var.vm_private_key_path)
    }

    inline = [
      # Make script executable
      "sudo chmod +x /tmp/vm_customization_script.sh",
      # Execute the script as sudo
      "sudo /tmp/vm_customization_script.sh"
    ]
  }
}

# Configure VM10
resource "vsphere_virtual_machine" "vm10" {
  name             = "testvm_vm10"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.vm_folder
  num_cpus = 1
  memory   = 2048
  guest_id = data.vsphere_virtual_machine.vm_template.guest_id
  network_interface {
    network_id = data.vsphere_network.network_management.id
  }
  network_interface {
    network_id = data.vsphere_network.network_tenant_red_1.id
  }
  cdrom {
    client_device = true
  } 
  disk {
    label = "disk0"
    size  = 10
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.vm_template.id
    customize {
      linux_options {
        host_name  = "vm10"
        domain     = "tenantred.com"
        hw_clock_utc = true
        time_zone = "UTC"
      }
      network_interface {}
      network_interface {
        ipv4_address = "172.17.10.10"
        ipv4_netmask = 24
      }
      ipv4_gateway = "172.17.10.1"
      dns_suffix_list = ["tenantred.com"]
      dns_server_list = ["8.8.8.8"]
      
    }
  }
  wait_for_guest_net_routable = false
}

resource "null_resource" "vm10_configure" {
  depends_on = [vsphere_virtual_machine.vm10]
  provisioner "file" {
    connection {
      type        = "ssh"
      host        = vsphere_virtual_machine.vm10.default_ip_address
      insecure    = true
      user        = var.vm_username
      # password = var.vm_password
      private_key = file(var.vm_private_key_path)
    }
    source      = "../tenants/tenant_red/vm_customization_script.sh"
    destination = "/tmp/vm_customization_script.sh"
  }

  # Execute script
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = vsphere_virtual_machine.vm10.default_ip_address
      insecure    = true
      user        = var.vm_username
      # password = var.vm_password
      private_key = file(var.vm_private_key_path)
    }

    inline = [
      # Make script executable
      "sudo chmod +x /tmp/vm_customization_script.sh",
      # Execute the script as sudo
      "sudo /tmp/vm_customization_script.sh"
    ]
  }
}

# Configure VM11
resource "vsphere_virtual_machine" "vm11" {
  name             = "testvm_vm11"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.vm_folder
  num_cpus = 1
  memory   = 2048
  guest_id = data.vsphere_virtual_machine.vm_template.guest_id
  network_interface {
    network_id = data.vsphere_network.network_management.id
  }
  network_interface {
    network_id = data.vsphere_network.network_tenant_red_2.id
  }
  cdrom {
    client_device = true
  }
  disk {
    label = "disk0"
    size  = 10
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.vm_template.id
    customize {
      linux_options {
        host_name  = "vm11"
        domain     = "tenantred.com"
        hw_clock_utc = true
        time_zone = "UTC"
      }
      network_interface {}
      network_interface {
        ipv4_address = "172.17.11.11"
        ipv4_netmask = 24
      }
      # ipv4_gateway = "172.17.11.1"
      dns_suffix_list = ["tenantred.com"]
      dns_server_list = ["8.8.8.8"]

    }
  }
  wait_for_guest_net_routable = false
}

resource "null_resource" "vm11_configure" {
  depends_on = [vsphere_virtual_machine.vm11]
  provisioner "file" {
    connection {
      type        = "ssh"
      host        = vsphere_virtual_machine.vm11.default_ip_address
      insecure    = true
      user        = var.vm_username
      # password = var.vm_password
      private_key = file(var.vm_private_key_path)
    }
    source      = "../tenants/tenant_red/vm_customization_script.sh"
    destination = "/tmp/vm_customization_script.sh"
  }

  # Execute script
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = vsphere_virtual_machine.vm11.default_ip_address
      insecure    = true
      user        = var.vm_username
      # password = var.vm_password
      private_key = file(var.vm_private_key_path)
    }

    inline = [
      # Make script executable
      "sudo chmod +x /tmp/vm_customization_script.sh",
      # Execute the script as sudo
      "sudo /tmp/vm_customization_script.sh"
    ]
  }
}