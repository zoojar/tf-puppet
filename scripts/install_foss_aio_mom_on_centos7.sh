#!/bin/bash

#Terminate on error...
set -e

#Defaults:
log_file='/tmp/install_aio_mom.log'
conf_file='/tmp/master.conf'
installer_stagedir='/tmp/peinstaller'
installer_file="${installer_stagedir}/puppet-enterprise-installer"
r10k_key_path="/etc/puppetlabs/puppetserver/ssh"
r10k_key_file="id-control_repo.rsa"
hiera_yaml_file_url="https://raw.githubusercontent.com/zoojar/control-repo/production/hiera.yaml"
hiera_yaml_file="/etc/puppetlabs/puppet/hiera.yaml"
console_admin_password="puppet"
regex_url='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
code_mgr_token_dir='/etc/puppetlabs/puppetserver/.puppetlabs'
autosign_exe_url='https://raw.githubusercontent.com/zoojar/classified/master/autosign.sh'
yumrepo_default='https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm'
psk_default='changeme'
r10k_remote_default="https://github.com/zoojar/control-repo"

while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        echo "options:"
                        echo "-h, --help                         Show help."
                        echo "-p, --psk=PSK                      IP address of puppet master (used for setting /etc/hosts)."
                        echo "-c --control_repo=URL              URL of control repo (for r10k setup)"
                        echo "-y, --yumrepo=URL                  YUM Repo URL - installed via yum"
                        exit 0
                        ;;
                -c)
                        shift
                        if test $# -gt 0; then
                                r10k_remote=$1
                        else
                                echo "INFO: No control-repo URL specified - using default: $r10k_remote_default"
                                r10k_remote=$r10k_remote_default
                        fi
                        shift
                        ;;
                --control_repo*)
                        r10k_remote=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -p)
                        shift
                        if test $# -gt 0; then
                                psk=$1
                        else
                                echo "INFO: No PSK specified - using default: $psk_default"
                                psk=$psk_default
                        fi
                        shift
                        ;;
                --psk*)
                        psk=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -y)
                        shift
                        if test $# -gt 0; then
                                yumrepo=$1
                        else
                                echo "INFO: No yumrepo URL specified - using default: $yumrepo_default"
                                yumrepo=$yumrepo_default
                        fi
                        shift
                        ;;
                --yumrepo*)
                        yumrepo=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                *)
                        break
                        ;;
        esac
done



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

echo "$(date) INFO: Downloading puppet repo: $yumrepo..." | tee -a $log_file
rpm -Uvh $yumrepo

echo "$(date) INFO: Installing puppetserver..." | tee -a $log_file
yum -y install puppetserver

echo "$(date) INFO: Setting env path for Puppet & r10k..." | tee -a $log_file
PATH="/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/opt/puppet/bin:/usr/bin:$PATH"

echo "$(date) INFO: Configuring R10k..." | tee -a $log_file
puppet module install puppet-r10k --version 4.2.0
puppet apply -e "class {'r10k': remote => '$r10k_remote',}"
r10k deploy environment -v

echo "$(date) INFO: Configuring Hiera..." | tee -a $log_file
curl -k $hiera_yaml_file_url > $(puppet config print hiera_config)

if [[ ! -z $psk ]]; then
  echo "$(date) INFO: Configuring autosigning..." | tee -a $log_file
  echo $psk >/etc/puppetlabs/puppet/global-psk
  curl -L "${autosign_exe_url}" > /etc/puppetlabs/puppet/autosign.sh
  chmod 500 /etc/puppetlabs/puppet/autosign.sh ; sudo chown puppet /etc/puppetlabs/puppet/autosign.sh
  puppet config set autosign /etc/puppetlabs/puppet/autosign.sh --section master
fi

echo "$(date) INFO: Enabling & starting puppetserver..." | tee -a $log_file
puppet apply -e "service { 'puppetserver': enable => true, }"
service puppetserver start
