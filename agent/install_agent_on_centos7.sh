#!/bin/bash
#Script to install PE Puppet Agent via frictionless installer and autosigning.
#Accepts 3 arguments...
master_ip="$1"
master_fqdn="$2"
psk="$3"

echo "Adding [$master_ip $master_fqdn] to hosts file..."
sudo echo -e "$master_ip $master_fqdn\n$(cat /etc/hosts)" > /etc/hosts

echo "Setting up custom csr attributes for autosigning..."
mkdir -p /etc/puppetlabs/puppet
printf "custom_attributes:\n  1.2.840.113549.1.9.7: $psk" >  /etc/puppetlabs/puppet/csr_attributes.yaml 

echo "Installing puppet from https://$master_fqdn:8140/packages/current/install.bash..."
curl -k https://$master_fqdn:8140/packages/current/install.bash | sudo bash

PATH="/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/opt/puppet/bin:$PATH"
echo "Configuring puppet with master server $master_fqdn..."
puppet config set server $master_fqdn

puppet agent -t

echo "Done."


