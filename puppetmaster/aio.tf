variable "remote_exec_script" {}
variable "dns_servers" { type = "list" }
variable "gateway" {}
variable "datacenter" {}         
variable "pe_installer_url" {}
variable "vsphere_user" {}
variable "vsphere_password" {}
variable "vsphere_server" {}

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
    source      = "/scripts"
    destination = "/tmp"
  }
  
  provisioner "remote-exec" {
    inline = [
      ". /tmp/scripts/${var.remote_exec_script} ${var.pe_installer_url}",
    ]
  }

}
