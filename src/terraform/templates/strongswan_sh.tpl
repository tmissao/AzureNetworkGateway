#! /bin/bash -e

sudo apt-get update
sudo apt-get install -y strongswan

cat <<EOF | sudo tee /etc/sysctl.conf
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1 
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
EOF

cat <<EOF | sudo tee /etc/ipsec.conf
config setup
        charondebug="all"
        uniqueids=yes
conn azure-bridge
        type=tunnel
        auto=start
        keyexchange=ikev2
        left=%any
        leftsubnet=${HOST_SUBNET}
        leftauth=psk
        right=${REMOTE_PUBLIC_IP}
        rightsubnet={${REMOTE_SUBNET},${REMOTE_SUBNET2}}
        rightauth=psk
        ike=aes256-sha256-modp2048!
        esp=aes256-sha256-modp2048!
        aggressive=no
        keyingtries=30
        ikelifetime=28800s
        lifetime=3600s
        dpddelay=30s
        dpdtimeout=120s
        dpdaction=restart
EOF

cat <<EOF | sudo tee  /etc/ipsec.secrets
${HOST_PUBLIC_IP} ${REMOTE_PUBLIC_IP} : PSK "${STRONGSWAN_PASSWORD}"
EOF

sudo iptables -t nat -A POSTROUTING -s ${REMOTE_SUBNET} -d ${HOST_SUBNET} -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -s ${REMOTE_SUBNET2} -d ${HOST_SUBNET} -j MASQUERADE

sudo sysctl -p /etc/sysctl.conf

sudo ipsec rereadsecrets

sudo ipsec reload