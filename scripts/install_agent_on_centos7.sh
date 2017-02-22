#!/bin/bash
# Script to install Puppet Agent (PE or FOSS) via yum or frictionless installer - tested on CentOS7.
# - David Newton 2017.02.22

yumrepo_default='https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm'
puppet_package='puppet-agent'
#set -e # Abort on error

while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        echo "options:"
                        echo "-h, --help                         Show help."
                        echo "-i, --master_ip=IP                 IP address of puppet master (used for setting /etc/hosts)."
                        echo "-f, --master_fqdn=FQDN             FQDN of puppet master (used for setting /etc/hosts)."
                        echo "-p, --psk=Pre-shared key           Autosigning pre-shared key to embed in the certificate request."
                        echo "-r, --role=Role                    Role (value of pp_role) to embed in the certificate request."
                        echo "-y, --yumrepo=URL                  YUM Repo URL - if specified then the FOSS agent will be installed via yum"
                        exit 0
                        ;;
                -i)
                        shift
                        if test $# -gt 0; then
                                master_ip="$1"
                        else
                                echo "ERROR: No IP for puppet master specified."
                                exit 1
                        fi
                        shift
                        ;;
                --master_ip*)
                        master_ip=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -f)
                        shift
                        if test $# -gt 0; then
                                master_fqdn=$1
                        else
                                echo "ERROR: No FQDN for puppet master specified."
                                exit 1
                        fi
                        shift
                        ;;
                --master_fqdn*)
                        master_fqdn=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -p)
                        shift
                        if test $# -gt 0; then
                                psk=$1
                        else
                                echo "ERROR: No pre-shared key specified."
                                exit 1
                        fi
                        shift
                        ;;
                --psk*)
                        psk=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -r)
                        shift
                        if test $# -gt 0; then
                                role=$1
                        else
                                echo "ERROR: No role specified."
                                exit 1
                        fi
                        shift
                        ;;
                --role*)
                        role=`echo $1 | sed -e 's/^[^=]*=//g'`
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

if [[ ! -z $master_fqdn &&  ! -z $master_ip ]]; then
  echo "$(date) INFO: Adding [$master_ip $master_fqdn] to hosts file..."
  sudo echo -e "$master_ip $master_fqdn\n$(cat /etc/hosts)" > /etc/hosts
fi

if [[ ! -z $psk || ! -z $role ]]; then
  echo "$(date) INFO: Setting up custom csr attributes for autosigning..."
  mkdir -p /etc/puppetlabs/puppet
  printf "custom_attributes:\n  1.2.840.113549.1.9.7: $psk\nextension_requests:\n  pp_role: $role\n" >  /etc/puppetlabs/puppet/csr_attributes.yaml 
fi

if [[ -z $yumrepo ]]; then
  echo "$(date) INFO: No yum repo URL specified, attempting PE frictionless install from: https://$master_fqdn:8140/packages/current/install.bash"
  curl -k https://$master_fqdn:8140/packages/current/install.bash | sudo bash
else
  echo "$(date) INFO: YUM repo URL specified, attempting FOSS install from: $yumrepo"
  sudo rpm -Uvh $yumrepo
  sudo yum install -y $puppet_package 
fi

PATH="/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/opt/puppet/bin:$PATH"

if [[ ! -z $master_fqdn ]]; then
  echo "$(date) INFO: Configuring puppet with master server $master_fqdn..."
  puppet config set server $master_fqdn
fi

echo "$(date) INFO: Running puppet agent..."
puppet agent -t

echo "$(date) INFO: Done."


