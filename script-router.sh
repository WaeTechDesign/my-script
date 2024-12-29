#!/bin/bash

set -e

echo "Memulai konfigurasi Orange Pi 3B v2.1 sebagai router dengan Webmin..."

# Update dan install dependencies
echo "Memperbarui paket dan menginstal dependensi..."
apt update && apt upgrade -y
apt install -y net-tools neofetch isc-dhcp-server iptables-persistent ufw curl

# Konfigurasi interfaces tanpa mengubah end1 (WAN) terlebih dahulu
echo "Mengatur konfigurasi jaringan awal..."
cat <<EOF > /etc/network/interfaces
# WLAN (Access Point)
auto wlan0
iface wlan0 inet static
    address 192.168.1.1
    netmask 255.255.255.0
    network 192.168.1.0
    broadcast 192.168.1.255
    post-up iw dev wlan0 set type nl80211
    post-up ip link set wlan0 up

# USBtoLAN1
auto enx207bd27e966e
iface enx207bd27e966e inet dhcp

# USBtoLAN2
auto wlan1
iface wlan1 inet dhcp
EOF

# Aktifkan perubahan jaringan tanpa menyentuh end1
echo "Merestart layanan jaringan untuk konfigurasi awal..."
systemctl restart networking

# Aktifkan IP forwarding
echo "Mengaktifkan IP forwarding..."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

# Konfigurasi NAT
echo "Menambahkan aturan NAT..."
iptables -t nat -A POSTROUTING -o end1 -j MASQUERADE
iptables-save > /etc/iptables/rules.v4

# Konfigurasi DHCP Server
echo "Mengatur DHCP server..."
cat <<EOF > /etc/dhcp/dhcpd.conf
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option domain-name-servers 192.168.1.1;
}
EOF

echo 'INTERFACESv4="wlan0 enx207bd27e966e wlan1"' > /etc/default/isc-dhcp-server

# Restart layanan DHCP server
echo "Merestart layanan DHCP server..."
systemctl restart isc-dhcp-server

# Tambahkan repositori Webmin
echo "Menambahkan repositori Webmin..."
cat <<EOF >> /etc/apt/sources.list
deb http://download.webmin.com/download/repository sarge contrib
EOF

wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -
apt update
apt install -y webmin

# Konfigurasi firewall UFW
echo "Mengkonfigurasi firewall..."
ufw allow 10000/tcp
ufw allow ssh
ufw enable

# Konfigurasi end1 (WAN) di akhir agar tidak memutus koneksi SSH
echo "Mengatur konfigurasi end1 (WAN)..."
cat <<EOF >> /etc/network/interfaces

# Restart layanan jaringan dengan end1 diaktifkan
echo "Merestart layanan jaringan dengan konfigurasi lengkap..."
systemctl restart networking

echo "Konfigurasi selesai! Anda dapat mengakses Webmin di https://<IP_Orange_Pi>:10000"

# WAN
auto end1
iface end1 inet static
    address 192.168.0.2
    netmask 255.255.255.0
    network 192.168.0.0
    gateway 192.168.0.1
    dns-nameservers 192.168.0.1
    broadcast 192.168.0.255
EOF

