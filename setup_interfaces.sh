#!/usr/bin/env bash

# Set text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

setup_interfaces() {
    echo -e "${GREEN}Setting up Networking Interfaces...${NC}"
    echo -e "${GREEN}Available network interfaces:${NC}"
    ip -o link show | awk -F': ' '{print $2}'

    read -p "How many interfaces do you want to configure? " num_interfaces
    for ((i = 1; i <= num_interfaces; i++)); do
        echo "\nConfiguring interface #$i:"
        read -p "Enter the name of the interface: " interface_name
        read -p "Enter the IP address (e.g., 192.168.1.100): " ip_address
        read -p "Enter the netmask (e.g., 255.255.255.0): " netmask
        read -p "Enter the gateway (e.g., 192.168.1.1): " gateway

        # Backup and append configuration to /etc/network/interfaces
        cp /etc/network/interfaces /etc/network/interfaces.bak
        cat <<EOL >> /etc/network/interfaces

            auto $interface_name
            iface $interface_name inet static
            address $ip_address
            netmask $netmask
            gateway $gateway
        EOL
    echo -e "${GREEN}Interface $interface_name configured successfully.${NC}"
    systemctl restart networking
    echo -e "${GREEN}Networking services restarted.${NC}"
    echo -e "${GREEN}Done setting up network interfaces.${NC}"
}