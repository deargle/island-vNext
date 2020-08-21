#!/bin/bash -ex
# DEPRECATED: replaced by github.com/deargle/exim4 docker container

'''
todo:
- place DKIM_PRIVATE_KEY
- specify `name_of_network`

'''

apt update && apt install -y  exim4 ipcalc

cat <<EOF >> /etc/exim4/conf.d/transport/10_exim4-config_transport-macros
DKIM_DOMAIN = island.byu.edu
DKIM_SELECTOR = 20160822
DKIM_CANON = relaxed
DKIM_PRIVATE_KEY = /etc/exim4/dkim/island.byu.edu-dkim-private.pem
EOF




mkdir -p /etc/exim4/dkim/
# place the dkim private key file where it is expected... it is located in `lockbox:/Keys/island/`
chown Debian-exim:Debian-exim /etc/exim4/dkim/island.byu.edu-dkim-private.pem
chmod 400 /etc/exim4/dkim/island.byu.edu-dkim-private.pem


name_of_network=docker0 # set this to the id for the user-defined network created for the nginx-proxy

docker0_ip=$(ip -4 -o addr show ${name_of_network} | awk '{print $4}' | cut -d'/' -f1)
docker0_network=$(ipcalc -n 172.17.0.1/16 | grep Network | awk '{print $2}')


cat <<EOF > /etc/exim4/update-exim4.conf.conf
# /etc/exim4/update-exim4.conf.conf
#
# Edit this file and /etc/mailname by hand and execute update-exim4.conf
# yourself or use 'dpkg-reconfigure exim4-config'
#
# Please note that this is _not_ a dpkg-conffile and that automatic changes
# to this file might happen. The code handling this will honor your local
# changes, so this is usually fine, but will break local schemes that mess
# around with multiple versions of the file.
#
# update-exim4.conf uses this file to determine variable values to generate
# exim configuration macros for the configuration file.
#
# Most settings found in here do have corresponding questions in the
# Debconf configuration, but not all of them.
#
# This is a Debian specific file

dc_eximconfig_configtype='satellite'
dc_other_hostnames=''
dc_local_interfaces='${docker0_ip};127.0.0.1 ; ::1'
dc_readhost='island.byu.edu'
dc_relay_domains=''
dc_minimaldns='false'
dc_relay_nets='${docker0_network}'
dc_smarthost='mmgateway.byu.edu'
CFILEMODE='644'
dc_use_split_config='true'
dc_hide_mailname='true'
dc_mailname_in_oh='true'
dc_localdelivery='mail_spool'
EOF






cat <<EOF >> /etc/exim4/conf.d/transport/30_exim4-config_remote_smtp
# DKIM setup copied from 30_exim4-config_remote_smtp
# see: https://serverfault.com/a/782069/117087
.ifdef DKIM_DOMAIN
  dkim_domain = DKIM_DOMAIN
.endif
.ifdef DKIM_SELECTOR
  dkim_selector = DKIM_SELECTOR
.endif
.ifdef DKIM_PRIVATE_KEY
  dkim_private_key = DKIM_PRIVATE_KEY
.endif
.ifdef DKIM_CANON
  dkim_canon = DKIM_CANON
.endif
.ifdef DKIM_STRICT
  dkim_strict = DKIM_STRICT
.endif
.ifdef DKIM_SIGN_HEADERS
  dkim_sign_headers = DKIM_SIGN_HEADERS
.endif
EOF

sudo update-exim4.conf -v
sudo service exim4 restart # this recreates the conf-file
