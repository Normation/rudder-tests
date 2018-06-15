#!/bin/sh


NET="$1"
LAST_DIGIT_IP="$2"
HOSTS="$3"

# Install a clean /etc/hosts for Rudder to operate properly (all)
cat << EOF > /etc/hosts
# /etc/hosts, built by rtf (Rudder Test Framwork)
#
# Format:
# IP-Address  Full-Qualified-Hostname  Short-Hostname
#

# IPv4
127.0.0.1       localhost

EOF

for host in ${HOSTS}
do
  echo "${NET}.${LAST_DIGIT_IP}    ${host}.rudder.local ${host}" >> /etc/hosts
  LAST_DIGIT_IP=`expr $LAST_DIGIT_IP + 1`
done

cat << EOF >> /etc/hosts

# IPv6
::1             localhost ipv6-localhost ipv6-loopback

fe00::0         ipv6-localnet

ff00::0         ipv6-mcastprefix
ff02::1         ipv6-allnodes
ff02::2         ipv6-allrouters
ff02::3         ipv6-allhosts
EOF
