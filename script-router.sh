#!/bin/bash

set -e

# Fungsi untuk menangani konflik paket
echo "Memperbarui paket..."
sudo apt update && sudo apt upgrade -y

# Periksa dan hapus paket yang tertahan
held_packages=$(apt-mark showhold)
if [ -n "$held_packages" ]; then
    echo "Menghapus tanda tahan dari paket berikut: $held_packages"
    sudo apt-mark unhold $held_packages
fi

# Instalasi dependensi dasar
echo "Menginstal dependensi dasar..."
sudo apt install -y net-tools neofetch curl wget nano iptables-persistent

# Menambahkan repositori Webmin jika belum ada
if ! grep -q "webmin.com" /etc/apt/sources.list; then
    echo "Menambahkan repositori Webmin..."
    echo "deb http://download.webmin.com/download/repository sarge contrib" | sudo tee -a /etc/apt/sources.list
    wget -qO - http://www.webmin.com/jcameron-key.asc | sudo apt-key add -
    sudo apt update
fi

# Instalasi Webmin
echo "Menginstal Webmin..."
sudo apt install -y webmin

# Aktifkan IP forwarding
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl -p

# Konfigurasi NAT dengan iptables
echo "Mengonfigurasi NAT menggunakan iptables..."
sudo iptables -t nat -A POSTROUTING -o end1 -j MASQUERADE
sudo iptables-save > /etc/iptables/rules.v4

# Instalasi DHCP server
echo "Menginstal ISC DHCP Server..."
sudo apt install -y isc-dhcp-server

# Konfigurasi DHCP untuk WLAN
sudo bash -c 'cat > /etc/dhcp/dhcpd.conf' << EOF
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option domain-name-servers 192.168.1.1;
}
EOF

# Konfigurasi interface DHCP
sudo sed -i 's/INTERFACESv4=""/INTERFACESv4="wlan0 enx207bd27e966e enx207bd27e1234"/' /etc/default/isc-dhcp-server

# Restart DHCP server
sudo systemctl restart isc-dhcp-server

# Konfigurasi interface jaringan
echo "Mengonfigurasi interface jaringan..."
sudo bash -c 'cat > /etc/network/interfaces' << EOF
# WAN
auto end1
iface end1 inet dhcp

# WLAN (Access Point)
auto wlan0
iface wlan0 inet static
    address 192.168.1.1
    netmask 255.255.255.0

# USB to LAN 1
auto enx207bd27e966e
iface enx207bd27e966e inet static
    address 192.168.2.1
    netmask 255.255.255.0

# USB to LAN 2
auto enx207bd27e1234
iface enx207bd27e1234 inet static
    address 192.168.3.1
    netmask 255.255.255.0
EOF

# Restart networking service
echo "Merestart layanan jaringan..."
sudo systemctl restart networking

# Tambahkan firewall UFW jika tidak ada konflik dengan iptables-persistent
if ! dpkg -s ufw >/dev/null 2>&1; then
    echo "Menginstal UFW..."
    sudo apt install -y ufw
    sudo ufw allow 10000/tcp   # Webmin
    sudo ufw allow ssh         # SSH
    sudo ufw enable
fi

# Konfigurasi selesai
echo "Konfigurasi selesai. Anda dapat mengakses Webmin melalui https://<IP_Orange_Pi>:10000"
