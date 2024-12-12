#!/bin/bash

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

# Define Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RESET='\033[0m'

clear
echo -e "${CYAN}Script : ${RESET}"
echo -e "${CYAN}1. Update Repository${RESET}"
echo -e "${CYAN}2. Update & Upgrade System${RESET}"
echo -e "${CYAN}3. Install Dependecies${RESET}"
echo -e "${CYAN}4. Install ZeroTier${RESET}"
echo -e "${CYAN}5. Join Network ZeroTier${RESET}"
echo -e "${CYAN}6. Install CasaOS${RESET}"
echo -e "${CYAN}7. Change Network Interface to Static IP${RESET}"
echo ""
sleep 10
clear

# Adding repositories
echo -e "${CYAN}Adding repositories...${RESET}"
echo ""

echo "deb http://kartolo.sby.datautama.net.id/debian/ bookworm contrib main non-free non-free-firmware" | sudo tee -a /etc/apt/sources.list
echo "deb http://kartolo.sby.datautama.net.id/debian/ bookworm-updates contrib main non-free non-free-firmware" | sudo tee -a /etc/apt/sources.list
echo "deb http://kartolo.sby.datautama.net.id/debian/ bookworm-proposed-updates contrib main non-free non-free-firmware" | sudo tee -a /etc/apt/sources.list
echo "deb http://kartolo.sby.datautama.net.id/debian/ bookworm-backports contrib main non-free non-free-firmware" | sudo tee -a /etc/apt/sources.list
echo "deb http://kartolo.sby.datautama.net.id/debian-security/ bookworm-security contrib main non-free non-free-firmware" | sudo tee -a /etc/apt/sources.list
sleep 5
clear

# Update repositories and install packages
echo -e "${CYAN}Updating repositories...${RESET}"
echo ""

sudo apt-get update
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

sudo apt-get update && sudo apt-get upgrade -y
echo -e "${GREEN}Your system has been successfully updated and upgraded.${RESET}"
sleep 5
clear

# Input for the list of packages to be installed
echo -e "${YELLOW}Enter the packages you want to install (space-separated, e.g., curl vim git):${RESET}"
read -r user_packages
echo ""

# Install user-specified packages
echo -e "${CYAN}Installing packages...${RESET}"
echo ""
for PACKAGE in $user_packages
do
    echo -e "${CYAN}Installing $PACKAGE...${RESET}"
    sudo apt-get install -y $PACKAGE
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$PACKAGE installed successfully.${RESET}"
        echo ""
    else
        echo -e "${RED}Failed to install $PACKAGE.${RESET}"
    fi
done
sleep 5
clear

# Update the system and install dependencies
echo -e "${CYAN}Updating system and installing dependencies for ZeroTier and CasaOS...${RESET}"
echo ""

if sudo apt update && sudo apt upgrade -y; then
    echo -e "${GREEN}System updated successfully.${RESET}"
else
    echo -e "${RED}System update failed.${RESET}"
fi
if sudo apt install -y curl gnupg lsb-release; then
    echo -e "${GREEN}Dependencies installed successfully.${RESET}"
else
    echo -e "${RED}Dependency installation failed.${RESET}"
fi

# Install ZeroTier
echo -e "${CYAN}Installing ZeroTier...${RESET}"
echo ""

if curl -s https://install.zerotier.com | sudo bash; then
    echo -e "${GREEN}ZeroTier installed successfully.${RESET}"
else
    echo -e "${RED}ZeroTier installation failed.${RESET}"
fi

# Ask for the ZeroTier Network ID
echo -e "${YELLOW}Enter your ZeroTier Network ID:${RESET}"
read NETWORK_ID

# Join the ZeroTier network
echo -e "${CYAN}Joining ZeroTier network with ID $NETWORK_ID...${RESET}"
echo ""

if sudo zerotier-cli join $NETWORK_ID; then
    echo -e "${GREEN}Successfully joined the network.${RESET}"
else
    echo -e "${RED}Failed to join the network.${RESET}"
fi

# Check the ZeroTier status
echo -e "${CYAN}Checking ZeroTier status...${RESET}"
echo ""

if sudo zerotier-cli listnetworks; then
    echo -e "${GREEN}ZeroTier status checked successfully.${RESET}"
else
    echo -e "${RED}Failed to check ZeroTier status.${RESET}"
fi

# Install CasaOS
echo -e "${CYAN}Installing CasaOS...${RESET}"
echo ""

if curl -fsSL https://get.casaos.io | bash; then
    echo -e "${GREEN}CasaOS installed successfully.${RESET}"
else
    echo -e "${RED}CasaOS installation failed.${RESET}"
fi


# Input for IP Address, Gateway, and DNS configuration
echo -e "${YELLOW}Input Static IP Address Configuration : ${RESET}"
echo -e "${YELLOW}Enter the IP address (e.g., 192.168.0.2/24):${RESET}"
read -r ip_address
echo -e "${YELLOW}Enter the Gateway (e.g., 192.168.0.1):${RESET}"
read -r gateway
echo -e "${YELLOW}Enter the DNS (e.g., 8.8.8.8):${RESET}"
read -r dns
echo""

# Changing LAN port to static IP
echo -e "${CYAN}Configuring static IP for LAN...${RESET}"
echo -e "${GREEN}Static IP successfully configured for LAN.${RESET}"
echo -e "${CYAN}Setup completed!${RESET}"
echo -e "${CYAN}You can now log in using the new IP Address : $ip_address (without /24, just the ip address)${RESET}"
echo ""

# Display the actions taken
echo -e "${CYAN}Summary of actions performed:${RESET}"
echo -e "${GREEN}1. Repositories have been added successfully.${RESET}"
echo -e "${GREEN}2. System was updated and upgraded successfully.${RESET}"
echo -e "${GREEN}3. Installed packages: $user_packages${RESET}"
echo -e "${GREEN}4. ZeroTier installed and successfully joined the network with ID $NETWORK_ID.${RESET}"
echo -e "${GREEN}5. CasaOS installed successfully.${RESET}"
echo -e "${GREEN}6. Static IP Address has been set successfully for LAN: $ip_address${RESET}"
echo -e "${GREEN}7. DNS and Gateway have been configured as follows - DNS: $dns, Gateway: $gateway.${RESET}"

# End of script
echo -e "${CYAN}All actions are complete! Enjoy your setup!${RESET}"

sudo nmcli con mod "Wired connection 1" ipv4.addresses "$ip_address"
sudo nmcli con mod "Wired connection 1" ipv4.gateway "$gateway"
sudo nmcli con mod "Wired connection 1" ipv4.dns "$dns"
sudo nmcli con mod "Wired connection 1" ipv4.method manual
sudo nmcli con down "Wired connection 1" && sudo nmcli con up "Wired connection 1"
