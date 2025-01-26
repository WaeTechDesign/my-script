#!/usr/bin/env bash

# Home Server Toolkit
# Modified by Wae Tech Design - Diagnostics and Fixes | Wae Tech Design 2025
# Reference : BigBearCasaOS Complete Toolkit - Diagnostics and Fixes
# Run with sudo permissions

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

spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to print header
print_header() {
    echo "================================================"
    echo "$1"
    echo "================================================"
    echo
}

# Function to display menu
show_menu() {
    clear
    print_header "Wae Tech Design Home Server ToolKit V0.0.1"

    echo "Here are some links:"
    echo "https://github.com/WaeTechDesign"
    echo "https://github.com/BigBearTechWorld"
    echo "https://community.bigbeartechworld.com"
    echo ""
    
    echo "===================="
    echo "1. Setup Network Interfaces"
    echo "2. Update Source List"
    echo "3. Update & Upgrade System"
    echo "4. Update Repository"
    echo "5. Install & Configure DHCP Server"
    echo "6. Install Zerotier"
    echo "7. Zerotier Join Network Id"
    echo "8. Zerotier Status"
    echo "9. Zerotier Leave Network"
    echo "10. Zerotier List Network"
    echo "11. Install CasaOS"
    echo "12. Configure HDD/SSD and External Storage for CasaOS"
    echo "13. Disable DNS Service"
    echo "14. Set Disable DNS Service for auto run after reboot"

    read -p "Enter your choice (1-14): " choice
}

# 1. Setup Network Interfaces
setup_interfaces() {
    echo -e "${GREEN}Setting up Networking Interfaces...${NC}"
    spinner &
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

# 2. Update Source List
add_repositories() {
    echo -e "${GREEN}Adding repositories...${NC}"
    spinner &
    read -p "How many repositories do you want to add? " repo_count
    for ((i = 1; i <= repo_count; i++)); do
        read -p "Enter the repository URL (e.g., deb http://archive.ubuntu.com/ubuntu/ focal main): " repo_url
        # Add the repository to /etc/apt/sources.list
        echo "$repo_url" | tee -a /etc/apt/sources.list > /dev/null
        echo -e "${GREEN}Repository $repo_url added successfully.${NC}"
    done
    spinner &
}

# 3. Update & Upgrade System
upgrade_system() {
    echo -e "${GREEN}Updating and Upgrading system...${NC}"
    spinner &
    apt update && apt upgrade -y
    echo -e "${GREEN}Update & Upgrading System is Complete${NC}"
}

# 4. Update Repository
update_repository() {
    echo -e "${GREEN}Updating source list...${NC}"
    spinner &
    apt update
    echo -e "${GREEN}Done updating source list.${NC}"
}

# 5. Install & Configure DHCP Server
install_configure_dhcp() {
    echo -e "${GREEN}Installing DHCP server...${NC}"
    spinner &
    apt install isc-dhcp-server -y
    echo -e "${GREEN}Configuring DHCP server...${NC}"

    # List available network interfaces
    echo -e "${GREEN}Listing available network interfaces...${NC}"
    ip -o link show | awk -F': ' '{print $2}'

    # Ask how many interfaces to configure for DHCP
    read -p "How many interfaces do you want to configure for DHCP? " dhcp_interfaces
    interfaces=()  # Array to store interface names

    for ((i = 1; i <= dhcp_interfaces; i++)); do
        read -p "Enter the interface name to configure for DHCP (e.g., eth0, wlan0): " interface_name
        interfaces+=("$interface_name")
    done

    # Ask the user for the network information once for all interfaces
    echo -e "${GREEN}Enter the network configuration details...${NC}"
    read -p "Enter the network IP address (e.g., 192.168.1.0): " network_ip
    read -p "Enter the netmask (e.g., 255.255.255.0): " netmask
    read -p "Enter the gateway IP address: " gateway_ip

    # Calculate DHCP range
    IFS='.' read -r -a ip_parts <<< "$network_ip"
    subnet_range="${ip_parts[0]}.${ip_parts[1]}.${ip_parts[2]}"

    dhcp_start="${subnet_range}.100"
    dhcp_end="${subnet_range}.200"

    # Backup current configuration
    cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak
    
    # Configure DHCP settings
    cat <<EOL > /etc/dhcp/dhcpd.conf
# DHCP configuration
subnet $network_ip netmask $netmask {
  range $dhcp_start $dhcp_end;
  option routers $gateway_ip;
  option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOL

    # Configure DHCP server to listen on selected interfaces
    for interface_name in "${interfaces[@]}"; do
        # Specify interfaces to listen on in the /etc/default/isc-dhcp-server file
        sed -i "/INTERFACESv4=\"\"/a INTERFACESv4=\"$interface_name\"" /etc/default/isc-dhcp-server
        echo -e "${GREEN}DHCP server configured for $interface_name.${NC}"

    # Restart DHCP server
    systemctl restart isc-dhcp-server
    echo -e "${GREEN}DHCP server restarted and interfaces configured.${NC}"
    echo -e "${GREEN}Done installing and configuring DHCP server.${NC}"
}

# 6. Install Zerotier
install_zerotier() {
    echo -e "${GREEN}Installing Zerotier...${NC}"
    spinner &
    apt install zerotier-one -y
    echo -e "${GREEN}Done installing Zerotier.${NC}"
}

# 7. Zerotier Join Network Id
zt_join() {
    echo -e "${GREEN}Joining Zerotier network...${NC}"
    spinner &
    read -p "Enter Network ID: " network_id
    sudo zerotier-cli join $network_id
    echo -e "${GREEN}Done joining Zerotier network.${NC}"
}

# 8. Zerotier Status
zt_status() {
    echo -e "${GREEN}Zerotier status...${NC}"
    spinner &
    sudo zerotier-cli status
    echo -e "${GREEN}Done checking Zerotier status.${NC}"
}

# 9. Zerotier Leave Network
zt_leave() {
    echo -e "${GREEN}Leaving Zerotier network...${NC}"
    spinner &
    read -p "Enter Network ID to leave: " leave_id
    sudo zerotier-cli leave $leave_id
    echo -e "${GREEN}Done leaving Zerotier network.${NC}"
}

# 10. Zerotier List Network
zt_list() {
    echo -e "${GREEN}Listing Zerotier networks...${NC}"
    spinner &
    sudo zerotier-cli listnetworks
    echo -e "${GREEN}Done listing Zerotier networks.${NC}"
}

# 11. Install CasaOS
install_casaos() {
    echo -e "${GREEN}Installing CasaOS...${NC}"
    spinner &
    curl -fsSL https://get.casaos.io | bash
    echo -e "${GREEN}Done installing CasaOS.${NC}"
}

# 12. Configure HDD/SSD and External Storage for CasaOS
config_storage() {
    echo -e "${GREEN}Configuring HDD/SSD for CasaOS...${NC}"
    spinner &
    # Your code for configuring HDD/SSD goes here
    echo -e "${GREEN}Done configuring external storage.${NC}"
}

# 13. Disable DNS Service
disable_dns() {
    echo -e "${GREEN}Disabling DNS service...${NC}"
    spinner &
    systemctl stop systemd-resolved
    systemctl disable systemd-resolved
    echo -e "${GREEN}DNS service disabled.${NC}"
}

# 14. Set Disable DNS Service for auto run after reboot
disable_dns_auto() {
    echo -e "${GREEN}Disabling DNS auto-run after reboot...${NC}"
    spinner &
    systemctl mask systemd-resolved
    echo -e "${GREEN}DNS service will not run after reboot.${NC}"
}

# Main logic
while true; do
    show_menu

    case $choice in
        1) setup_interfaces ;;
        2) add_repositories ;;
        3) upgrade_system ;;
        4) update_repository ;;
        5) install_configure_dhcp ;;
        6) install_zerotier ;;
        7) zt_join ;;
        8) zt_status ;;
        9) zt_leave ;;
        10) zt_list ;;
        11) install_casaos ;;
        12) config_storage ;;
        13) disable_dns ;;
        14) disable_dns_auto ;;
        *) echo "Invalid option" ;;
    esac
done
