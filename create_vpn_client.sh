#!/bin/bash

##
## Usage: ./ovpn-writer.sh USER
##

user=${1}
server="vpn.lagacetashop.com.ar"
cacert="/etc/openvpn/easy-rsa/pki/ca.crt"
client_cert="/etc/openvpn/easy-rsa/pki/issued/${1}.crt"
client_key="/etc/openvpn/easy-rsa/pki/private/${1}.key"
tls_key="/etc/openvpn/easy-rsa/ta.key"

if [ ! -f ${client_cert} ]; then
	/etc/openvpn/easy-rsa/easyrsa build-client-full ${user} nopass || exit 1
	sleep 2
fi

echo "--------------------[ CONFIG FILE ]--------------------"
cat << EOF
client
dev tun
proto tcp
remote ${server} 1194
auth SHA256
float
resolv-retry infinite
nobind
persist-key
persist-tun
comp-lzo
verb 3
tls-client
key-direction 1
pull
EOF
echo '<ca>'
cat ${cacert}
echo '</ca>'
echo '<cert>'
cat ${client_cert}
echo '</cert>'
echo '<key>'
cat ${client_key}
echo '</key>'
echo '<tls-auth>'
cat ${tls_key}
echo '</tls-auth>'
echo "--------------------[ CONFIG FILE ]--------------------"
exit $?

