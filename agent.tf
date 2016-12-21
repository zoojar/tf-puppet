
# Configure the VMware vSphere Provider
provider "vsphere" {
  user                 = "${var.vsphere_user}"
  password             = "${var.vsphere_password}"
  vsphere_server       = "${var.vsphere_server}"
  allow_unverified_ssl = true
}


resource "vsphere_virtual_machine" "agent" {
  count        = "1"
  name         = "agent-${count.index}"
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
  
  provisioner "remote-exec" {
    inline = [
      "sudo echo -e \"${var.puppetmaster_ip} ${var.puppetmaster_fqdn}\" >> /etc/hosts",
      "curl -k https://${var.puppetmaster_fqdn}:8140/packages/current/install.bash | sudo bash",
    ]
  }

}
