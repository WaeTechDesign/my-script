#!/bin/bash

clear

# Colors for output
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# Function to check root access
check_root_access() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}This script must be run as root.${RESET}"
        
        # Request for root user if not root
        echo -e "${CYAN}Please enter the root username:${RESET}"
        read -r root_user

        echo -e "${CYAN}Please enter the root password for $root_user:${RESET}"
        read -sr root_password

        # Switch to root using sudo
        echo "$root_password" | sudo -S -u "$root_user" bash "$0"
        exit 0
    fi
}

# Validate root access
check_root_access

# Repositories
REPOS=(
"http://kartolo.sby.datautama.net.id/debian/ bookworm contrib main non-free non-free-firmware"
"http://kartolo.sby.datautama.net.id/debian/ bookworm-updates contrib main non-free non-free-firmware"
"http://kartolo.sby.datautama.net.id/debian/ bookworm-proposed-updates contrib main non-free non-free-firmware"
"http://kartolo.sby.datautama.net.id/debian/ bookworm-backports contrib main non-free non-free-firmware"
"http://kartolo.sby.datautama.net.id/debian-security/ bookworm-security contrib main non-free non-free-firmware"
)

# Function to check and add repositories
add_repositories() {
    echo -e "${YELLOW}Checking and adding repositories...${RESET}"
    for REPO in "${REPOS[@]}"; do
        if grep -Fq "$REPO" /etc/apt/sources.list; then
            echo -e "${CYAN}Repository already exists:${RESET} $REPO"
            echo -e "${YELLOW}Do you want to re-add it? (y/n):${RESET}"
            read -r response
            if [[ "$response" =~ ^[yY](es|ES)?$ ]]; then
                echo -e "${CYAN}Re-adding repository...${RESET}"
                sudo bash -c "echo '$REPO' >> /etc/apt/sources.list"
            else
                echo -e "${CYAN}Skipping repository: $REPO${RESET}"
            fi
        else
            echo -e "${CYAN}Adding new repository:${RESET} $REPO"
            sudo bash -c "echo '$REPO' >> /etc/apt/sources.list"
        fi
    done
}

# Function to update progress bar
progress_bar() {
    local current=$1
    local total=$2
    local progress=$((100 * current / total))
    local width=50 # Progress bar width

    # Calculate completed and remaining parts
    local completed=$((progress * width / 100))
    local remaining=$((width - completed))

    # Print progress bar (always on the last line of the terminal)
    printf "\r[%-${width}s] %d%%" "$(printf "#%.0s" $(seq 1 $completed))" "$progress"
}

# Function for loading animation
loading_animation() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\' 
    echo -n " "
    while [ -d /proc/$pid ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Total steps
TOTAL_STEPS=10
step=0

clear
echo -e "${CYAN}Starting script...${RESET}"
echo ""
echo ""

# 1. Add Repositories
((step++))
echo -e "${YELLOW}1. Adding repositories...${RESET}"
progress_bar $step $TOTAL_STEPS
add_repositories &> /dev/null &
loading_animation $!
echo -e "${GREEN}Repositories checked and added successfully.${RESET}"

# 2. Update Repositories
echo ""
((step++))
echo -e "${YELLOW}2. Updating repositories...${RESET}"
progress_bar $step $TOTAL_STEPS
sudo apt update &> /dev/null &
loading_animation $!
echo -e "${GREEN}Repositories updated successfully.${RESET}"

# 3. Upgrade System
echo ""
((step++))
echo -e "${YELLOW}3. Upgrading system...${RESET}"
progress_bar $step $TOTAL_STEPS
sudo apt upgrade -y &> /dev/null &
loading_animation $!
echo -e "${GREEN}System upgraded successfully.${RESET}"

# 4. Install Additional Packages
echo ""
((step++))
echo -e "${YELLOW}4. Installing additional packages...${RESET}"
progress_bar $step $TOTAL_STEPS
echo -e "${CYAN}Custom Package Installation : ${RESET}"
echo ""
echo -e "${CYAN}Enter custom packages to install (separate with spaces):${RESET}"
read -r packages
echo -e "${CYAN}Installing & Enable additional packages... ${RESET}"
sudo apt install -y curl gnupg lsb-release cockpit isc-dhcp-server vlan iptables-persistent &> /dev/null &
systemctl enable --now cockpit.socket &> /dev/null &
echo -e "${CYAN}Installing custom packages... ${RESET}"
sudo apt install -y $packages &> /dev/null &
loading_animation $!
echo -e "${GREEN}Additional packages & custom packages installed successfully.${RESET}"

# 5. Install ZeroTier
echo ""
((step++))
echo -e "${YELLOW}5. Installing ZeroTier...${RESET}"
progress_bar $step $TOTAL_STEPS
dpkg -l | grep -qw "zerotier-one"
if [ $? -eq 0 ]; then
    echo -e "${YELLOW}ZeroTier is already installed. Skipping...${RESET}"
else
    sudo curl -s https://install.zerotier.com | sudo bash &> /dev/null &
    loading_animation $!
    echo -e "${GREEN}ZeroTier installed successfully.${RESET}"
fi

# Prompt for ZeroTier Network ID
echo ""
echo -e "${YELLOW}Enter your ZeroTier Network ID to join the network:${RESET}"
read -p "Network ID: " NETWORK_ID

if [[ -n "$NETWORK_ID" ]]; then
    echo -e "${YELLOW}Joining ZeroTier network with ID $NETWORK_ID...${RESET}"
    sudo zerotier-cli join $NETWORK_ID &> /dev/null &
    loading_animation $!
    
    # Check if joining the network was successful
    sudo zerotier-cli listnetworks | grep -qw "$NETWORK_ID"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully joined the ZeroTier network with ID $NETWORK_ID.${RESET}"
    else
        echo -e "${RED}Failed to join the ZeroTier network. Please check the Network ID and try again.${RESET}"
    fi
else
    echo -e "${RED}No Network ID provided. Skipping ZeroTier network join.${RESET}"
fi

# 6. Install CasaOS
echo ""
((step++))
echo -e "${YELLOW}6. Installing CasaOS...${RESET}"
progress_bar $step $TOTAL_STEPS
if command -v casaos &> /dev/null || [ -f "/usr/bin/casaos" ] || [ -d "/etc/casaos" ]; then
    echo -e "${YELLOW}CasaOS is already installed. Skipping...${RESET}"
else
    echo -e "${CYAN}CasaOS is not installed. Do you want to install it? (y/n)${RESET}"
    read -p "Your choice: " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Installing CasaOS...${RESET}"
        curl -fsSL https://get.casaos.io | sudo bash &> /dev/null &
        loading_animation $!
        echo -e "${GREEN}CasaOS installed successfully.${RESET}"
    else
        echo -e "${YELLOW}Skipped CasaOS installation.${RESET}"
    fi
fi

echo -e "${YELLOW}Setup Router...${RESET}"

# 7. Enabling IPv4 forwarding
echo ""
((step++))
progress_bar $step $TOTAL_STEPS
echo -e "${CYAN}7. Enabling IPv4 forwarding...${RESET}"
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-ipforward.conf
sysctl -p /etc/sysctl.d/99-ipforward.conf

# 8. Show Interfaces
echo ""
((step++))
echo -e "${YELLOW}8. Show Interfaces...${RESET}"
progress_bar $step $TOTAL_STEPS
show_interfaces() {
    echo -e "${YELLOW}Available network interfaces:${RESET}"
    ip link show | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]" {print $2}' | sed 's/[[:space:]]//g'
}

# 9. Function to configure Router
echo ""
((step++))
echo -e "${YELLOW}9. Configure Router...${RESET}"
progress_bar $step $TOTAL_STEPS
# Function to configure interfaces
configure_interfaces() {
    show_interfaces
    echo -e "${CYAN}Enter the number of interfaces you want to configure:${RESET}"
    read -r num_interfaces

    # Loop to configure multiple interfaces
    for ((i = 1; i <= num_interfaces; i++)); do
        echo -e "${CYAN}Enter the interface name for interface $i (e.g., eth0):${RESET}"
        read -r interface_name

        echo -e "${CYAN}Enter the IP address and subnet for interface $interface_name (e.g., 192.168.1.1/24):${RESET}"
        read -r interface_ip

        # Assign IP to the interface
        ip addr add "$interface_ip" dev "$interface_name"
        ip link set up "$interface_name"
        echo -e "${GREEN}IP $interface_ip configured for interface $interface_name.${RESET}"

        # Configure DHCP for the interface
        cat >> /etc/dhcp/dhcpd.conf <<EOL
subnet ${interface_ip%/*} netmask ${interface_ip#*/} {
    range ${interface_ip%.*}.100 ${interface_ip%.*}.200;
    option routers ${interface_ip%.*}.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOL
        echo -e "${GREEN}DHCP configuration added for interface $interface_name.${RESET}"
    done

    # Restart DHCP service
    systemctl restart isc-dhcp-server
}

# Function to configure VLANs
configure_vlans() {
    echo -e "${CYAN}Do you want to configure VLANs? (y/n):${RESET}"
    read -r enable_vlan

    if [[ "$enable_vlan" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Enter the parent interface for VLANs (e.g., eth0):${RESET}"
        read -r parent_interface

        echo -e "${CYAN}Enter the number of VLANs to configure:${RESET}"
        read -r vlan_count

        for ((i = 1; i <= vlan_count; i++)); do
            echo -e "${CYAN}Configuring VLAN $i on $parent_interface:${RESET}"
            echo -e "${CYAN}Enter VLAN ID (e.g., 10):${RESET}"
            read -r vlan_id

            echo -e "${CYAN}Enter the IP address and subnet for VLAN $vlan_id (e.g., 192.168.10.1/24):${RESET}"
            read -r vlan_ip

            # Create VLAN interface
            ip link add link "$parent_interface" name "$parent_interface.$vlan_id" type vlan id "$vlan_id"
            ip addr add "$vlan_ip" dev "$parent_interface.$vlan_id"
            ip link set up "$parent_interface.$vlan_id"
            echo -e "${GREEN}VLAN $vlan_id configured on $parent_interface with IP $vlan_ip.${RESET}"

            # Configure DHCP for VLAN
            cat >> /etc/dhcp/dhcpd.conf <<EOL
subnet ${vlan_ip%/*} netmask ${vlan_ip#*/} {
    range ${vlan_ip%.*}.100 ${vlan_ip%.*}.200;
    option routers ${vlan_ip%.*}.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOL
            echo -e "${GREEN}DHCP configuration added for VLAN $vlan_id.${RESET}"
        done

        # Restart DHCP service
        systemctl restart isc-dhcp-server
    else
        echo -e "${CYAN}No VLAN configuration selected.${RESET}"
    fi
}

# Main configuration steps
# Configure interfaces
configure_interfaces

# Configure VLANs
configure_vlans

# Configure firewall rules
echo -e "${CYAN}Configuring firewall rules...${RESET}"
ipv4_forward_file="/proc/sys/net/ipv4/ip_forward"
echo 1 > "$ipv4_forward_file"
iptables -t nat -A POSTROUTING -o end1 -j MASQUERADE
iptables -A FORWARD -i end1 -o br0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i br0 -o end1 -j ACCEPT

# Save iptables configuration
iptables-save > /etc/iptables/rules.v4

# Setting up Cockpit GUI
echo -e "${CYAN}Setting up Cockpit GUI...${RESET}"
echo -e "${GREEN}Router setup complete. Access Cockpit at https://<your-ip>:9090.${RESET}"

# 10. Set Static IP
echo ""
((step++))
echo -e "${YELLOW}10. Set Static IP...${RESET}"
progress_bar $step $TOTAL_STEPS

echo -e "${YELLOW}Show Interfaces...${RESET}"
show_interfaces() {
    echo -e "${YELLOW}Available network interfaces:${RESET}"
    ip link show | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]" {print $2}' | sed 's/[[:space:]]//g'
}

# Configure WAN IP to static
echo -e "${YELLOW}Enter the interface name (e.g., eth0 or wlan0):${RESET}"
read -r interface_name
echo -e "${YELLOW}Enter the static IP address (e.g., 192.168.1.100/24):${RESET}"
read -r static_ip
echo -e "${YELLOW}Enter the gateway (e.g., 192.168.1.1):${RESET}"
read -r gateway
echo -e "${YELLOW}Enter the DNS server (e.g., 8.8.8.8):${RESET}"
read -r dns_server

sudo bash -c "cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto $interface_name
iface $interface_name inet static
    address $static_ip
    gateway $gateway
    dns-nameservers $dns_server
EOF"

sudo systemctl restart networking
echo -e "${GREEN}Static IP address configured successfully.${RESET}"