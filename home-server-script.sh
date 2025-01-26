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
    echo "1. Update Source List"
    echo "2. Update & Upgrade System"
    echo "3. Update Repository"
    echo "4. Install Zerotier"
    echo "5. Zerotier Join Network Id"
    echo "6. Zerotier Status"
    echo "7. Zerotier Leave Network"
    echo "8. Zerotier List Network"
    echo "9. Install CasaOS"
    echo "10. Configure HDD/SSD and External Storage for CasaOS"
    echo "11. Disable DNS Service"
    echo "12. Set Disable DNS Service for auto run after reboot"

    read -p "Enter your choice (1-12): " choice
}


#1. Update Source List
add_repositories() {
    echo -e "${GREEN}Adding repositories...${NC}"
    read -p "Enter the repository URL (e.g., deb http://archive.ubuntu.com/ubuntu/ focal main): " repo_url
        # Add the repository to /etc/apt/sources.list
        echo "$repo_url" | tee -a /etc/apt/sources.list > /dev/null
        echo -e "${GREEN}Repository $repo_url added successfully.${NC}"
}
#2. Update & Upgrade System
upgrade_system() {
    echo -e "${GREEN}Updating and Upgrading system...${NC}"
    apt update && apt upgrade -y
    echo -e "${GREEN}Update & Upgrading System is Complete${NC}"
}

#3. Update Repository
update_repository() {
    echo -e "${GREEN}Updating source list...${NC}"
    apt update
    echo -e "${GREEN}Done updating source list.${NC}"
}

#4. Install Zerotier
install_zerotier() {
    echo -e "${GREEN}Installing Zerotier...${NC}"
    apt install zerotier-one -y
    echo -e "${GREEN}Done installing Zerotier.${NC}"
}

#5. Zerotier Join Network Id
zt_join() {
    echo -e "${GREEN}Joining Zerotier network...${NC}"
    read -p "Enter Network ID: " network_id
    sudo zerotier-cli join $network_id
    echo -e "${GREEN}Done joining Zerotier network.${NC}"
}

#6. Zerotier Status
zt_status() {
    echo -e "${GREEN}Zerotier status...${NC}"
    sudo zerotier-cli status
    echo -e "${GREEN}Done checking Zerotier status.${NC}"
}

#7. Zerotier Leave Network
zt_leave() {
    echo -e "${GREEN}Leaving Zerotier network...${NC}"
    read -p "Enter Network ID to leave: " leave_id
    sudo zerotier-cli leave $leave_id
    echo -e "${GREEN}Done leaving Zerotier network.${NC}"
}

#8. Zerotier List Network
zt_list() {
    echo -e "${GREEN}Listing Zerotier networks...${NC}"
    sudo zerotier-cli listnetworks
    echo -e "${GREEN}Done listing Zerotier networks.${NC}"
}

#9. Install CasaOS
install_casaos() {
    echo -e "${GREEN}Installing CasaOS...${NC}"
    curl -fsSL https://get.casaos.io | bash
}

#10. Configure HDD/SSD and External Storage for CasaOS
config_storage() {
    echo -e "${GREEN}Configuring external storage for CasaOS...${NC}"
    lsblk
    read -p "Enter the mount point: " mount_point
    sudo chmod -R 777 "$mount_point"
    echo -e "${GREEN}Done configuring external storage for CasaOS.${NC}"
}

#11. Disable DNS Service
disable_dns_service() {
    echo -e "${GREEN}Disabling DNS service...${NC}"

    # Check for required utilities and install if missing
for cmd in "systemctl" "lsof" "netstat" "nslookup" "awk" "grep" "sed"; do
  if ! command -v $cmd &> /dev/null; then
    echo "$cmd is required but not installed. Attempting to install..."
    case $cmd in
      "netstat") sudo apt-get install -y net-tools ;;
      "lsof") sudo apt-get install -y lsof ;;
      "nslookup") sudo apt-get install -y dnsutils ;;
      *) echo "$cmd is not a package or is already installed" ;;
    esac
  fi

    resolv_conf="/etc/resolv.conf"

    echo "List of processes with port 53 open:"
    lsof -i :53 || netstat -tulpn | grep ":53 "

    echo "Disabling and stopping systemd-resolved..."
    systemctl disable resolvconf-pull-resolved.service
    systemctl disable resolvconf-pull-resolved.path
    sudo systemctl stop dnsmasq

    echo "Checking if port 53 is clear..."
    if lsof -i :53 | grep -q '.'; then
        echo "Port 53 is still in use."
    else
        echo "Port 53 is clear."
    fi

    current_dns=$(grep '^nameserver' "$resolv_conf" | awk '{print $2}')
    echo "Current DNS: $current_dns"

    read -p "Enter new DNS (default is 1.1.1.1): " dns_server
    dns_server=${dns_server:-1.1.1.1}

    if nslookup bigbeartechworld.com "$dns_server" &> /dev/null; then
        echo "$dns_server can resolve correctly."
    else
        echo "$dns_server cannot resolve. Exiting."
        exit 1
    fi

    # Backup
    if [ ! -f "$resolv_conf.bak" ]; then
        cp "$resolv_conf" "$resolv_conf.bak"
    else
        echo "Backup already exists, skipping backup."
    fi

    sed -i "s/nameserver.*/nameserver $dns_server/" "$resolv_conf"

    echo "Updated /etc/resolv.conf:"
    cat "$resolv_conf"
    echo -e "${GREEN}Done disabling DNS service.${NC}"
}

#12. Set Disable DNS Service for auto run after reboot
autorun_disable_dns_service() {

    systemctl mask resolvconf-pull-resolved.service
    systemctl mask resolvconf-pull-resolved.path
    echo -e "${GREEN}DNS service will not run after reboot.${NC}"
}
# Main loop
while true; do
    show_menu
    case $choice in
        1)
            add_repositories
            ;;
        2)
            upgrade_system
            ;;
        3)
            update_repository
            ;;
        4)
            install_zerotier
            ;;
        5)
            zt_join
            ;;
        6)
            zt_status
            ;;
        7)
            zt_leave
            ;;
        8)
            zt_list
            ;;
        9)
            install_casaos
            ;;
        10)
            config_storage
            ;;
        11)
            disable_dns_service
            ;;
        12)
            autorun_disable_dns_service
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    echo
    read -p "Press Enter to continue..."
done