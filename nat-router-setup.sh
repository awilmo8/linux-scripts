#!/bin/bash

set -e

LAN_IF="eth0"
WAN_IF="wlan0"
LAN_IP="192.168.0.1"
LAN_SUBNET="192.168.0.0"
LAN_RANGE_START="192.168.0.100"
LAN_RANGE_END="192.168.0.200"
DNS_SERVERS="1.1.1.1, 8.8.8.8"

echo "[*] Installing required packages..."
sudo apt update
sudo apt install -y isc-dhcp-server iptables-persistent

echo "[*] Setting static IP for $LAN_IF..."
sudo tee -a /etc/dhcpcd.conf > /dev/null <<EOF

interface $LAN_IF
    static ip_address=$LAN_IP/24
EOF

echo "[*] Configuring DHCP server..."
sudo tee /etc/dhcp/dhcpd.conf > /dev/null <<EOF
subnet $LAN_SUBNET netmask 255.255.255.0 {
    range $LAN_RANGE_START $LAN_RANGE_END;
    option routers $LAN_IP;
    option domain-name-servers $DNS_SERVERS;
}
EOF

sudo sed -i "s/^INTERFACESv4=\".*\"/INTERFACESv4=\"$LAN_IF\"/" /etc/default/isc-dhcp-server

echo "[*] Enabling IP forwarding..."
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl -p

echo "[*] Adding NAT iptables rules..."
sudo iptables -t nat -A POSTROUTING -o $WAN_IF -j MASQUERADE
sudo iptables -A FORWARD -i $LAN_IF -o $WAN_IF -j ACCEPT
sudo iptables -A FORWARD -i $WAN_IF -o $LAN_IF -m state --state RELATED,ESTABLISHED -j ACCEPT

sudo netfilter-persistent save

echo "[*] Restarting services..."
sudo systemctl restart isc-dhcp-server
sudo systemctl enable isc-dhcp-server

echo "[✓] NAT router setup complete. Reboot recommended."
