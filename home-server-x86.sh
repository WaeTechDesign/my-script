#!/bin/bash

clear

# Function to display messages with a delay
display_message() {
  echo "$1"
  sleep 2
  clear
}

# Function to pause and wait for user input
pause() {
  echo -e "${YELLOW}Press [Enter] to continue...${RESET}"
  read -r
}

# Function for user confirmation
confirm_action() {
  read -p "$1 (y/N): " response
  case "$response" in
    [yY][eE][sS]|[yY])
      return 0  # Yes, continue with the action
      ;;
    *)
      return 1  # No, skip this action
      ;;
  esac
}

# Define Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# Animation function for loading
loading_animation() {
  local pid=$1
  local delay=0.1
  local spin='-\|/'
  echo -n '  '
  while kill -0 $pid 2>/dev/null; do
    for i in `seq 0 3`; do
      echo -n "${spin:$i:1}"
      sleep $delay
      echo -ne "\b"
    done
  done
  echo -n '  '
}

echo -e "${CYAN}Script : ${RESET}"
echo -e "${CYAN}1. Update Repository${RESET}"
echo -e "${CYAN}2. Update & Upgrade System${RESET}"
echo -e "${CYAN}3. Install LXDE GUI${RESET}"
echo -e "${CYAN}4. Install Dependencies${RESET}"
echo -e "${CYAN}5. Install ZeroTier${RESET}"
echo -e "${CYAN}6. Join Network ZeroTier${RESET}"
echo -e "${CYAN}7. Install CasaOS${RESET}"
echo -e "${CYAN}8. Change Network Interface to Static IP${RESET}"
echo ""
sleep 10
clear

# Adding repositories
echo -e "${CYAN}Adding repositories...${RESET}"
echo ""

# List of repositories to add
REPOSITORIES=(
  "deb http://kartolo.sby.datautama.net.id/debian/ bookworm contrib main non-free non-free-firmware"
  "deb http://kartolo.sby.datautama.net.id/debian/ bookworm-updates contrib main non-free non-free-firmware"
  "deb http://kartolo.sby.datautama.net.id/debian/ bookworm-proposed-updates contrib main non-free non-free-firmware"
  "deb http://kartolo.sby.datautama.net.id/debian/ bookworm-backports contrib main non-free non-free-firmware"
  "deb http://kartolo.sby.datautama.net.id/debian-security/ bookworm-security contrib main non-free non-free-firmware"
)

# Check if each repository is already added before adding
for REPO in "${REPOSITORIES[@]}"; do
  if ! grep -Fxq "$REPO" /etc/apt/sources.list; then
    echo "$REPO" | sudo tee -a /etc/apt/sources.list
    echo -e "${GREEN}Repository added: $REPO${RESET}"
  else
    echo -e "${YELLOW}Repository already exists: $REPO${RESET}"
    if confirm_action "Do you want to add it again?"; then
      echo "$REPO" | sudo tee -a /etc/apt/sources.list
      echo -e "${GREEN}Repository added: $REPO${RESET}"
    else
      echo -e "${CYAN}Skipping repository addition: $REPO${RESET}"
    fi
  fi
done
sleep 5
clear

# Update repositories and install packages
echo -e "${CYAN}Updating repositories...${RESET}"
echo ""
sudo apt-get update &
loading_animation $!  # Run update in the background and show loading animation
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Repositories updated successfully.${RESET}"
else
    echo -e "${RED}Failed to update repositories.${RESET}"
    exit 1
fi
sleep 5
clear

# Update & Upgrade System
echo -e "${CYAN}Updating and upgrading your system...${RESET}"
echo ""
sudo apt-get update && sudo apt-get upgrade -y &
loading_animation $!  # Run upgrade in the background and show loading animation
echo -e "${GREEN}Your system has been successfully updated and upgraded.${RESET}"
sleep 5
clear

# Install LXDE GUI
echo -e "${CYAN}Installing LXDE GUI...${RESET}"
echo ""
if confirm_action "Do you want to install LXDE GUI?"; then
    sudo apt-get install -y lxde &
    loading_animation $!  # Run LXDE installation in the background and show loading animation
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}LXDE GUI installed successfully.${RESET}"
    else
        echo -e "${RED}Failed to install LXDE GUI.${RESET}"
    fi
else
    echo -e "${CYAN}Skipping LXDE GUI installation.${RESET}"
fi
sleep 5
clear

# Input for the list of packages to be installed
echo -e "${YELLOW}Enter the packages you want to install (space-separated, e.g., curl vim git):${RESET}"
read -r user_packages
echo ""

# Install user-specified packages with confirmation
echo -e "${CYAN}Installing packages...${RESET}"
echo ""
for PACKAGE in $user_packages
do
    echo -e "${CYAN}Checking if $PACKAGE is already installed...${RESET}"
    if dpkg -l | grep -q "$PACKAGE"; then
        echo -e "${YELLOW}$PACKAGE is already installed.${RESET}"
        if confirm_action "Do you want to reinstall $PACKAGE"; then
            echo -e "${CYAN}Reinstalling $PACKAGE...${RESET}"
            sudo apt-get install --reinstall -y $PACKAGE &
            loading_animation $!  # Run installation in the background and show loading animation
        else
            echo -e "${CYAN}Skipping $PACKAGE installation.${RESET}"
        fi
    else
        echo -e "${CYAN}Installing $PACKAGE...${RESET}"
        sudo apt-get install -y $PACKAGE &
        loading_animation $!  # Run installation in the background and show loading animation
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}$PACKAGE installed successfully.${RESET}"
        else
            echo -e "${RED}Failed to install $PACKAGE.${RESET}"
        fi
    fi
done
sleep 5
clear

# Install ZeroTier
echo -e "${CYAN}Installing ZeroTier...${RESET}"
echo ""
if curl -s https://install.zerotier.com | sudo bash &> /dev/null &
then
    loading_animation $!  # Run installation in the background and show loading animation
    echo -e "${GREEN}ZeroTier installed successfully.${RESET}"
else
    echo -e "${RED}ZeroTier installation failed.${RESET}"
fi
sleep 5
clear

# Join ZeroTier Network
echo -e "${YELLOW}Enter your ZeroTier Network ID:${RESET}"
read NETWORK_ID
echo -e "${CYAN}Joining ZeroTier network with ID $NETWORK_ID...${RESET}"
if sudo zerotier-cli join $NETWORK_ID &> /dev/null &
then
    loading_animation $!  # Show animation while joining network
    echo -e "${GREEN}Successfully joined the network.${RESET}"
else
    echo -e "${RED}Failed to join the network.${RESET}"
fi
sleep 5
clear

# Install CasaOS
echo -e "${CYAN}Installing CasaOS...${RESET}"
echo ""
if curl -fsSL https://get.casaos.io | bash &> /dev/null &
then
    loading_animation $!  # Run CasaOS installation in the background and show loading animation
    echo -e "${GREEN}CasaOS installed successfully.${RESET}"
else
    echo -e "${RED}CasaOS installation failed.${RESET}"
fi
sleep 5
clear

# Input Static IP Address Configuration
echo -e "${YELLOW}Configuring static IP address for your LAN interface...${RESET}"
echo -e "${YELLOW}Enter the interface name (e.g., eth0 or wlan0):${RESET}"
read -r interface_name
echo -e "${YELLOW}Enter the static IP address (e.g., 192.168.1.100/24):${RESET}"
read -r static_ip
echo -e "${YELLOW}Enter the gateway (e.g., 192.168.1.1):${RESET}"
read -r gateway
echo -e "${YELLOW}Enter the DNS server (e.g., 8.8.8.8):${RESET}"
read -r dns_server
echo ""

# Backup the original interfaces file
sudo cp /etc/network/interfaces /etc/network/interfaces.bak

# Write new static IP configuration to interfaces file
sudo bash -c "cat > /etc/network/interfaces <<EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# Loopback network interface
auto lo
iface lo inet loopback

# Primary network interface
auto $interface_name
iface $interface_name inet static
    address $static_ip
    gateway $gateway
    dns-nameservers $dns_server
EOF"

# Restart networking service to apply changes
echo -e "${CYAN}Restarting networking service to apply changes...${RESET}"
sudo systemctl restart networking
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Static IP address successfully configured for $interface_name.${RESET}"
    echo -e "${CYAN}New IP Address: $static_ip${RESET}"

    # Display the actions taken
    echo -e "${CYAN}Summary of actions performed:${RESET}"
    echo -e "${CYAN}1. Repositories updated.${RESET}"
    echo -e "${CYAN}2. System updated and upgraded.${RESET}"
    echo -e "${CYAN}3. LXDE GUI installed.${RESET}"
    echo -e "${CYAN}4. Packages installed: $user_packages${RESET}"
    echo -e "${CYAN}5. ZeroTier installed and network joined.${RESET}"
    echo -e "${CYAN}6. CasaOS installed.${RESET}"
    echo -e "${CYAN}7. Static IP configured.${RESET}"

else
    echo -e "${RED}Failed to apply static IP configuration. Please check your settings.${RESET}"
fi