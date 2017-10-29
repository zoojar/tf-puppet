variable "remote_exec_script" {}
variable "dns_servers" { type = "list" }
variable "gateway" {}
variable "datacenter" {}         
variable "pe_installer_url" {}
variable "vsphere_user" {}
variable "vsphere_password" {}
variable "vsphere_server" {}
variable "psk" {}
variable "control_repo" {}
variable "ip_prefix" {}
variable "template" { type = "string" default = "centos7-template" }
variable "vm_network" { type = "string" default = "VM Network" }


# Configure the VMware vSphere Provider
provider "vsphere" {
  user                 = "${var.vsphere_user}"
  password             = "${var.vsphere_password}"
  vsphere_server       = "${var.vsphere_server}"
  allow_unverified_ssl = true
}


resource "vsphere_virtual_machine" "foss_puppetmaster" {
  count        = "1"
  name         = "foss-puppetmaster-${count.index}"
  vcpu         = 2
  memory       = 8000
  datacenter   = "${var.datacenter}"
  dns_servers  = "${var.dns_servers}"

  network_interface {
    label              = "${var.vm_network}"
    ipv4_address       = "${var.ip_prefix}${count.index}"
    ipv4_prefix_length = "24"
    ipv4_gateway       = "${var.gateway}"
  }

  disk {
    type     = "thin" 
    template = "${var.template}" 
  }

  connection {
    type     = "ssh"
    user     = "root"
    password = "root"
  }

  provisioner "file" {
    source      = "scripts"
    destination = "/tmp"
  }
  
  provisioner "remote-exec" {
    inline = [
      ". /tmp/scripts/${var.remote_exec_script} --yumrepo=${var.pe_installer_url} --psk=${var.psk} --control_repo=${var.control_repo}",
    ]
  }

}
