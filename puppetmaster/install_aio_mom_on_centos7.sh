#!/bin/bash

#Defaults:
log_file='/tmp/install_aio_mom.log'
conf_file='/tmp/master.conf'
installer_stagedir='/tmp/peinstaller'
installer_file="${installer_stagedir}/puppet-enterprise-installer"
r10k_key_path="/etc/puppetlabs/puppetserver/ssh"
r10k_key_file="id-control_repo.rsa"
r10k_remote="https://github.com/zoojar/control-repo"
hiera_yaml_file="/etc/puppetlabs/hiera.yaml"
console_admin_password="puppet"
regex_url='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
peinstaller_url=$1
if ! [[ $peinstaller_url =~ $regex_url ]] ; then peinstaller_url='https://s3.amazonaws.com/pe-builds/released/2016.5.1/puppet-enterprise-2016.5.1-el-7-x86_64.tar.gz'; fi
echo "$(date) Installing facter..." | tee -a  $log_file
yum install epel-release -y ; yum -y install facter
puppetmaster_fqdn="$(facter fqdn)"

firewall_default_zone=`sudo firewall-cmd --get-default-zone`
echo "$(date) INFO: Configuring firewall: Opening ports 8140, 443, 61613 & 8142 for the default zone: ${firewall_default_zone}..." | tee -a  $log_file
firewall-cmd --permanent --zone=$firewall_default_zone --add-port=8140/tcp
firewall-cmd --permanent --zone=$firewall_default_zone --add-port=443/tcp
firewall-cmd --permanent --zone=$firewall_default_zone --add-port=61613/tcp
firewall-cmd --permanent --zone=$firewall_default_zone --add-port=8142/tcp
firewall-cmd --permanent --zone=$firewall_default_zone --add-port=4433/tcp
firewall-cmd --reload

echo "$(date) INFO: Downloading puppet from $peinstaller_url and extracting to $installer_stagedir..." | tee -a $log_file
yum -y install wget
wget -q --timeout=1200 $peinstaller_url -O /tmp/peinstaller.tar.gz
mkdir $installer_stagedir
tar -xf /tmp/peinstaller.tar.gz --strip-components=1 -C $installer_stagedir


echo "$(date) INFO: Preparing the install config file..." | tee -a $log_file
cat <<EOF > $conf_file
{
  "console_admin_password": "$console_admin_password",
  "puppet_enterprise::puppet_master_host": "$puppetmaster_fqdn",
  "puppet_enterprise::use_application_services": true,
  "puppet_enterprise::profile::master::code_manager_auto_configure": true,
  "puppet_enterprise::profile::master::r10k_remote": "$r10k_remote",
  "puppet_enterprise::profile::master::r10k_private_key": "$r10k_key_path/$r10k_key_file"
}
EOF

echo "$(date) INFO: Installing puppet..." | tee -a $log_file
sudo $installer_file -c $conf_file

echo "$(date) INFO: Configuring code manager..." | tee -a $log_file
PATH="/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/opt/puppet/bin:$PATH"
puppet agent -t
puppet module install npwalker-pe_code_manager_webhook --version 1.0.11
chown -R pe-puppet:pe-puppet /etc/puppetlabs/code/
puppet apply -e "include pe_code_manager_webhook::code_manager"

echo "$(date) INFO: Setting console admin password..." | tee -a $log_file
PATH="/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/opt/puppet/bin:$PATH"
/opt/puppetlabs/puppet/bin/ruby /opt/puppetlabs/server/data/enterprise/modules/pe_install/files/set_console_admin_password.rb $console_admin_password


