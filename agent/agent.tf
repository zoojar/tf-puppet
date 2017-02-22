variable "remote_exec_script" {}
variable "dns_servers" { type = "list" }
variable "gateway" {}
variable "datacenter" {}         
variable "vsphere_user" {}
variable "vsphere_password" {}
variable "vsphere_server" {}
variable "puppetmaster_ip" {}
variable "puppetmaster_fqdn" {}
variable "role" {}
variable "psk" {}
variable "yumrepo" {}
variable "hostname_prefix" {}

# Configure the VMware vSphere Provider
provider "vsphere" {
  user                 = "${var.vsphere_user}"
  password             = "${var.vsphere_password}"
  vsphere_server       = "${var.vsphere_server}"
  allow_unverified_ssl = true
}

resource "vsphere_virtual_machine" "agent" {
  count        = "1"
  name         = "${var.hostname_prefix}agent-${count.index}"
  vcpu         = 1
  memory       = 1000
  datacenter   = "${var.datacenter}"
  dns_servers  = "${var.dns_servers}"

  network_interface {
    label              = "VM Network"
    ipv4_address       = "192.168.0.16${count.index}"
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
    source      = "scripts"
    destination = "/tmp"
  }
  
  provisioner "remote-exec" {
    inline = [
      ". /tmp/scripts/${var.remote_exec_script} --master_ip=${var.puppetmaster_ip} --master_fqdn=${var.puppetmaster_fqdn} --role=${var.role} --psk=${var.psk} --yumrepo=${var.yumrepo}",
    ]
  }

}
