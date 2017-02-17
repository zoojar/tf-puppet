#!/bin/bash

#Defaults:
log_file='/tmp/install_aio_mom.log'
conf_file='/tmp/master.conf'
installer_stagedir='/tmp/peinstaller'
installer_file="${installer_stagedir}/puppet-enterprise-installer"
r10k_key_path="/etc/puppetlabs/puppetserver/ssh"
r10k_key_file="id-control_repo.rsa"
r10k_remote="https://github.com/zoojar/control-repo"
hiera_yaml_file_url="https://raw.githubusercontent.com/zoojar/control-repo/production/hiera.yaml"
hiera_yaml_file="/etc/puppetlabs/puppet/hiera.yaml"
console_admin_password="puppet"
regex_url='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
code_mgr_token_dir='/etc/puppetlabs/puppetserver/.puppetlabs'
repo_url=$1
if ! [[ $repo_url =~ $regex_url ]] ; then repo_url='https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm'; fi
echo "$(date) Installing facter..." | tee -a  $log_file
yum install epel-release -y ; yum -y install facter
puppetmaster_fqdn="$(facter fqdn)"
echo "$(date) Puppet Master Server FQDN is: $puppetmaster_fqdn (resolved using: facter fqdn)" | tee -a  $log_file

firewall_default_zone=`sudo firewall-cmd --get-default-zone`
echo "$(date) INFO: Configuring firewall: Opening ports 8140, 443, 61613 & 8142 for the default zone: ${firewall_default_zone}..." | tee -a  $log_file
firewall-cmd --permanent --zone=$firewall_default_zone --add-port=8140/tcp
firewall-cmd --permanent --zone=$firewall_default_zone --add-port=443/tcp
firewall-cmd --permanent --zone=$firewall_default_zone --add-port=61613/tcp
firewall-cmd --permanent --zone=$firewall_default_zone --add-port=8142/tcp
firewall-cmd --permanent --zone=$firewall_default_zone --add-port=4433/tcp
firewall-cmd --reload

echo "$(date) INFO: Downloading puppet repo: $repo_url..." | tee -a $log_file
rpm -Uvh $repo_url

echo "$(date) INFO: Installing puppetserver..." | tee -a $log_file
yum -y install puppetserver

echo "$(date) INFO: Setting env path for Puppet..." | tee -a $log_file
PATH="/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/opt/puppet/bin:$PATH"

echo "$(date) INFO: Configuring R10k..." | tee -a $log_file
puppet module install puppet-r10k --version 4.2.0
puppet apply -e "class {'r10k': remote => '$r10k_remote',}"
puppet code deploy environment

echo "$(date) INFO: Configuring hiera..." | tee -a $log_file
curl -k $hiera_yaml_file_url > $(puppet config print hiera_config)

echo "$(date) INFO: Enabling & starting puppetserver..." | tee -a $log_file
puppet apply -e "service { 'puppetserver': enable => true, }"
service puppetserver start
