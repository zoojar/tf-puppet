variable "vsphere_user"       {}
variable "vsphere_password"   {}
variable "vsphere_server"     {}
variable "remote_exec_script" { default = "install_aio_mom_on_centos7.sh"}
variable "dns_servers"        { default = [ "8.8.8.8", "192.168.0.1" ] }
variable "gateway"            { default = "192.168.0.1" }
variable "datacenter"         { default = "Datacenter 1" }
variable "pe_installer_url"   {}
variable "puppetmaster_fqdn"  {}
variable "puppetmaster_ip"    {}