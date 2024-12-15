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

# Define Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RESET='\033[0m'

echo -e "${CYAN}Script : ${RESET}"
echo -e "${CYAN}1. Update Repository${RESET}"
echo -e "${CYAN}2. Update & Upgrade System${RESET}"
echo -e "${CYAN}3. Install Dependecies${RESET}"
echo -e "${CYAN}4. Install ZeroTier${RESET}"
echo -e "${CYAN}5. Join Network ZeroTier${RESET}"
echo -e "${CYAN}6. Install CasaOS${RESET}"
echo -e "${CYAN}7. Installing LXDE GUI${RESET}"
echo -e "${CYAN}8. Change Network Interface to Static IP${RESET}"
echo ""
sleep 10
clear

# Adding repositories
echo -e "${CYAN}Adding repositories...${RESET}"
echo ""

echo "deb http://kartolo.sby.datautama.net.id/debian/ bookworm contrib main non-free non-free-firmware" | tee -a /etc/apt/sources.list
echo "deb http://kartolo.sby.datautama.net.id/debian/ bookworm-updates contrib main non-free non-free-firmware" | tee -a /etc/apt/sources.list
echo "deb http://kartolo.sby.datautama.net.id/debian/ bookworm-proposed-updates contrib main non-free non-free-firmware" | tee -a /etc/apt/sources.list
echo "deb http://kartolo.sby.datautama.net.id/debian/ bookworm-backports contrib main non-free non-free-firmware" | tee -a /etc/apt/sources.list
echo "deb http://kartolo.sby.datautama.net.id/debian-security/ bookworm-security contrib main non-free non-free-firmware" | tee -a /etc/apt/sources.list
sleep 5
clear

# Update repositories and install packages with progress bar
echo -e "${CYAN}Updating repositories...${RESET}"
echo ""

# Progress bar with `dialog` for apt update
apt update | dialog --title "Updating Repositories" --gauge "Please wait while repositories are being updated..." 10 60 0
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Repositories updated successfully.${RESET}"
else
    echo -e "${RED}Failed to update repositories.${RESET}"
    exit 1
fi
sleep 5
clear

# Update & Upgrade System with progress bar
echo -e "${CYAN}Updating and upgrading your system...${RESET}"
echo ""

# Progress bar with `dialog` for apt upgrade
apt update && apt upgrade -y | dialog --title "Updating & Upgrading" --gauge "Upgrading the system, please wait..." 10 60 0
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Your system has been successfully updated and upgraded.${RESET}"
else
    echo -e "${RED}Failed to update and upgrade system.${RESET}"
    exit 1
fi
sleep 5
clear

# Install LXDE GUI with progress bar
echo -e "${CYAN}Installing LXDE GUI...${RESET}"
echo ""

# Progress bar with `dialog` for LXDE installation
apt install -y lxde | dialog --title "Installing LXDE" --gauge "Installing LXDE GUI, please wait..." 10 60 0
if [ $? -eq 0 ]; then
    echo -e "${GREEN}LXDE GUI installed successfully.${RESET}"
else
    echo -e "${RED}Failed to install LXDE GUI.${RESET}"
    exit 1
fi
sleep 5
clear

# Set LXDE as the default GUI for booting
echo -e "${CYAN}Setting LXDE as the default GUI...${RESET}"
if systemctl set-default graphical.target &&  systemctl isolate graphical.target; then
    echo -e "${GREEN}LXDE set as the default GUI successfully.${RESET}"
else
    echo -e "${RED}Failed to set LXDE as the default GUI.${RESET}"
    exit 1
fi
echo ""
sleep 5
clear

# Input for IP Address, Gateway, and DNS configuration
echo -e "${YELLOW}Input Static IP Address Configuration : ${RESET}"
echo -e "${YELLOW}Enter the IP address (e.g., 192.168.0.2/24):${RESET}"
read -r ip_address
echo -e "${YELLOW}Enter the Gateway (e.g., 192.168.0.1):${RESET}"
read -r gateway
echo -e "${YELLOW}Enter the DNS (e.g., 8.8.8.8):${RESET}"
read -r dns
echo ""

# Changing LAN port to static IP
echo -e "${CYAN}Configuring static IP for LAN...${RESET}"
echo -e "${GREEN}Static IP successfully configured for LAN.${RESET}"
echo -e "${CYAN}Setup completed!${RESET}"
echo -e "${CYAN}You can now log in using the new IP Address : $ip_address (without /24, just the ip address)${RESET}"
echo ""
