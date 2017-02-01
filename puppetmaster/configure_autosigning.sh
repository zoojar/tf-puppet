#!/bin/bash
# Script to configure autosigning on PE 2016.5.1. Accepts one argument: the PSK - written into /etc/puppetlabs/puppet/global-psk.

psk=$1
autosign_exe_url="https://raw.githubusercontent.com/zoojar/classified/master/autosign.sh"

echo "Configuring policy-based autosigning..."
echo $psk >/etc/puppetlabs/puppet/global-psk
curl -L "${autosign_exe_url}" > /etc/puppetlabs/puppet/autosign.sh
chmod 500 /etc/puppetlabs/puppet/autosign.sh ; sudo chown pe-puppet /etc/puppetlabs/puppet/autosign.sh
PATH="/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/opt/puppet/bin:$PATH"
puppet config set autosign /etc/puppetlabs/puppet/autosign.sh --section master
