#!/bin/bash

clear

# Colors for output
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

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

# Total steps (adjusted to 7 steps)
TOTAL_STEPS=7
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

# 3. Install Additional Packages
echo ""
((step++))
echo -e "${YELLOW}3. Installing additional packages...${RESET}"
progress_bar $step $TOTAL_STEPS
echo -e "${CYAN}Enter packages to install (separate with spaces):${RESET}"
read -r packages
sudo apt install -y curl gnupg lsb-release &> /dev/null &
sudo apt install -y $packages &> /dev/null &
loading_animation $!
echo -e "${GREEN}Additional packages installed successfully.${RESET}"

# 4. Install ZeroTier
echo ""
((step++))
echo -e "${YELLOW}4. Installing ZeroTier...${RESET}"
progress_bar $step $TOTAL_STEPS
dpkg -l | grep -qw "zerotier-one"
if [ $? -eq 0 ]; then
    echo -e "${YELLOW}ZeroTier is already installed. Skipping...${RESET}"
else
    sudo curl -s https://install.zerotier.com | sudo bash &> /dev/null &
    loading_animation $!
    echo -e "${GREEN}ZeroTier installed successfully.${RESET}"
fi

# 5. Install CasaOS
echo ""
((step++))
echo -e "${YELLOW}5. Installing CasaOS...${RESET}"
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

# 6. Install LXDE GUI
echo ""
((step++))
echo -e "${YELLOW}6. Installing LXDE GUI...${RESET}"
progress_bar $step $TOTAL_STEPS
dpkg -l | grep -qw "lxde"
if [ $? -eq 0 ]; then
    echo -e "${YELLOW}LXDE is already installed. Skipping...${RESET}"
else
    sudo apt install -y lxde &> /dev/null &
    loading_animation $!
    echo -e "${GREEN}LXDE GUI installed successfully.${RESET}"
fi

# 7. Upgrade System
echo ""
((step++))
echo -e "${YELLOW}7. Upgrading system...${RESET}"
progress_bar $step $TOTAL_STEPS
sudo apt upgrade -y &> /dev/null &
loading_animation $!
echo -e "${GREEN}System upgraded successfully.${RESET}"

# Final progress without the progress bar
echo -e "\n${CYAN}All tasks completed successfully!${RESET}"

# Reboot Prompt
echo ""
echo -e "${YELLOW}Do you want to reboot the system now? (y/n):${RESET}"
read -r reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}Rebooting...${RESET}"
    sudo reboot
else
    echo -e "${CYAN}Reboot skipped. Please reboot the system later. ${RESET}"
fi