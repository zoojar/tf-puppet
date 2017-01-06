variable "remote_exec_script" {}
variable "dns_servers" {}
variable "gateway" {}
variable "datacenter" {}         
variable "pe_installer_url" {}

# Configure the VMware vSphere Provider
provider "vsphere" {
  user                 = "${var.vsphere_user}"
  password             = "${var.vsphere_password}"
  vsphere_server       = "${var.vsphere_server}"
  allow_unverified_ssl = true
}


resource "vsphere_virtual_machine" "puppetmaster" {
  count        = "1"
  name         = "puppetmaster-${count.index}"
  vcpu         = 2
  memory       = 8000
  datacenter   = "${var.datacenter}"
  dns_servers  = "${var.dns_servers}"

  network_interface {
    label              = "VM Network"
    ipv4_address       = "192.168.0.15${count.index}"
    ipv4_prefix_length = "24"
    ipv4_gateway       = "${var.gateway}"
  }

  disk {
    type     = "thin" 
    template = "centos7-template" 
  }

  connection {
    type     = "ssh"
    user     = "root"
    password = "root"
  }

  provisioner "file" {
    source      = "${var.remote_exec_script}"
    destination = "/tmp/${var.remote_exec_script}"
  }
  
  provisioner "remote-exec" {
    inline = [
      ". /tmp/${var.remote_exec_script} ${var.pe_installer_url}",
    ]
  }

}
