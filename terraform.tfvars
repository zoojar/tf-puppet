variable "remote_exec_script" { default = "install_aio_mom_on_centos7.sh"}
variable "dns_servers"        { default = [ "8.8.8.8", "192.168.0.1" ] }
variable "gateway"            { default = "192.168.0.1" }
variable "datacenter"         { default = "Datacenter 1" }
#variable "pe_installer_url"   { default = "https://s3.amazonaws.com/pe-builds/released/2016.5.1/puppet-enterprise-2016.5.1-el-7-x86_64.tar.gz" }