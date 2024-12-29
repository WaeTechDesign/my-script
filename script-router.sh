#!/bin/bash

# Fungsi loading screen
loading() {
  local duration=$1
  local message=$2
  echo -n "$message"
  for i in $(seq 1 $duration); do
    echo -n "."
    sleep 1
  done
  echo " Done!"
}

# Update dan upgrade paket
loading 3 "Memperbarui paket"
sudo apt update && sudo apt upgrade -y

# Install paket dasar
loading 3 "Menginstal paket dasar"
sudo apt install -y git curl wget unzip vim dnsmasq iptables cockpit

# Enable dan start Cockpit
loading 3 "Mengaktifkan Cockpit"
sudo systemctl enable --now cockpit

# Enable IP Forwarding
loading 2 "Mengaktifkan IP Forwarding"
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Konfigurasi DNSMasq
loading 2 "Mengonfigurasi DNSMasq"
cat <<EOF | sudo tee /etc/dnsmasq.conf
interface=eth0  # Interface untuk jaringan lokal
dhcp-range=192.168.1.100,192.168.1.200,24h
EOF
sudo systemctl restart dnsmasq

# Setup NAT (Network Address Translation)
loading 2 "Mengatur NAT dengan iptables"
sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# Install ZeroTier
loading 3 "Menginstal ZeroTier"
curl -s https://install.zerotier.com | sudo bash
sudo systemctl enable zerotier-one
sudo systemctl start zerotier-one

# Tambahkan informasi ZeroTier
read -p "Masukkan NETWORK_ID ZeroTier: " NETWORK_ID
loading 2 "Bergabung ke jaringan ZeroTier"
sudo zerotier-cli join $NETWORK_ID

# Install CasaOS
loading 3 "Menginstal CasaOS"
curl -fsSL https://get.casaos.io | sudo bash

# Pesan selesai
echo "======================================"
echo "Instalasi selesai!"
echo "Akses GUI Cockpit di http://<IP_OrangePi>:9090"
echo "Akses GUI CasaOS di http://<IP_OrangePi>:80"
echo "======================================"
