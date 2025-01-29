#!/usr/bin/env bash

# BigBearCasaOS Complete Toolkit - Diagnostics and Fixes
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
    print_header "WAE TECH DESIGN CASAOS Toolkit V0.0.1"

    echo "Here are some links:"
    echo "https://community.bigbeartechworld.com"
    echo "https://github.com/WaeTechDesign"
    echo "https://github.com/BigBearTechWorld"
    echo ""
    
    echo "===================="
    echo "1. Change IP - Change IP Static"
    echo "2. Run Diagnostics - Collect system information and logs for troubleshooting"
    echo "3. Fix Docker Permissions - Reset directory permissions and ownership for Docker"
    echo "4. Fix Docker Overlay2 Issues - Repair storage driver problems and rebuild Docker structure"
    echo "5. Full System Reset - Clean reinstall of Docker and CasaOS (Backs up existing data from /var/lib/docker)"
    echo "6. Exit - Close the toolkit"
    read -p "Enter your choice (1-5): " choice
}

#
change_ip(){
    #!/bin/bash

    # Display available network interfaces
    echo "Displaying available network interfaces:"
    ip link show | grep -E "^[0-9]+: (eth|enp|wlan)"

    # Prompt user to select the interface
    echo "Enter the name of the interface you want to configure (e.g., eth0, enp3s0):"
    read selected_interface

    # Check if the selected interface exists
    if ! ip link show "$selected_interface" > /dev/null 2>&1; then
        echo "Interface $selected_interface not found. Exiting script."
        exit 1
    fi

    # Prompt user for new static IP, Gateway, and DNS
    echo "Enter the new static IP address (e.g., 192.168.1.100):"
    read new_ip

    echo "Enter the gateway address (e.g., 192.168.1.1):"
    read new_gateway

    echo "Enter the DNS address (e.g., 8.8.8.8):"
    read new_dns

    # Backup the interfaces file before modifying it
    cp /etc/network/interfaces /etc/network/interfaces.bak

    # Write the static IP configuration to /etc/network/interfaces
    echo "Changing IP settings in /etc/network/interfaces..."

    cat <<EOL > /etc/network/interfaces
    # interfaces(5) file used by ifup(8) and ifdown(8)

    # Please note that this file is written automatically by the script.

    auto lo
    iface lo inet loopback

    auto $selected_interface
    iface $selected_interface inet static
        address $new_ip
        netmask 255.255.255.0
        gateway $new_gateway
        dns-nameservers $new_dns
    EOL

    # Restart networking service to apply changes
    echo "Applying new configuration..."
    systemctl restart networking

    # Display the new IP settings
    echo "The new static IP settings have been applied to the $selected_interface interface:"
    ip a show $selected_interface

}
# Function to collect diagnostic information
run_diagnostics() {
    echo -e "${GREEN}Starting CasaOS diagnostic collection...${NC}"
    
    # Create output directory
    timestamp=$(date +%Y%m%d_%H%M%S)
    output_dir="casaos_diagnostics_${timestamp}"
    mkdir -p "$output_dir"

    # Function to collect command output
    collect_output() {
        local cmd="$1"
        local output_file="$2"
        echo -e "${YELLOW}Collecting: ${cmd}${NC}"
        eval "$cmd" > "$output_dir/$output_file" 2>&1
    }

    # Collect System Information
    collect_output "uname -a" "system_info.txt"
    collect_output "free -h" "memory_info.txt"
    collect_output "df -h" "disk_info.txt"
    collect_output "docker info" "docker_info.txt"
    collect_output "docker ps -a" "docker_containers.txt"
    collect_output "docker images" "docker_images.txt"
    collect_output "ls -la /var/lib/docker" "docker_directory_structure.txt"
    collect_output "systemctl status docker" "docker_service_status.txt"
    collect_output "systemctl status casaos" "casaos_service_status.txt"
    collect_output "journalctl -u docker --no-pager -n 200" "docker_logs.txt"
    collect_output "journalctl -u casaos --no-pager -n 200" "casaos_logs.txt"

    # Compress and cleanup
    tar czf "casaos_diagnostics_${timestamp}.tar.gz" "$output_dir"
    rm -rf "$output_dir"

    echo -e "${GREEN}Diagnostic collection complete!${NC}"
    echo -e "Diagnostic file created: ${YELLOW}casaos_diagnostics_${timestamp}.tar.gz${NC}"
}

# Function to fix Docker permissions
fix_docker_permissions() {
    echo -e "${YELLOW}Fixing Docker permissions...${NC}"
    
    # Ensure Docker is running
    if ! systemctl is-active --quiet docker; then
        systemctl start docker
    fi

    # Create necessary directories
    mkdir -p /var/lib/docker/tmp
    chmod 755 /var/lib/docker/tmp

    # Reset permissions
    chown -R root:root /var/lib/docker
    chmod -R 755 /var/lib/docker

    # Clean up and restart
    docker system prune -f
    systemctl restart docker
    systemctl restart casaos

    echo -e "${GREEN}Docker permissions have been reset!${NC}"
}

# Function to fix Overlay2 issues
fix_overlay2() {
    echo -e "${YELLOW}Fixing Docker overlay2 issues...${NC}"
    
    # Stop services
    systemctl stop docker
    systemctl stop casaos

    # Backup existing Docker root
    if [ -d "/var/lib/docker" ]; then
        mv /var/lib/docker /var/lib/docker.bak.$(date +%Y%m%d_%H%M%S)
    fi

    # Create fresh directory structure
    mkdir -p /var/lib/docker
    mkdir -p /var/lib/docker/overlay2
    mkdir -p /var/lib/docker/overlay2/l
    mkdir -p /var/lib/docker/tmp

    # Set permissions
    chown -R root:root /var/lib/docker
    chmod -R 755 /var/lib/docker
    chmod 700 /var/lib/docker/overlay2/l

    # Configure Docker daemon
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<EOL
{
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ]
}
EOL

    # Restart services
    systemctl daemon-reload
    systemctl start docker
    systemctl start casaos

    # Clean up
    docker system prune -af --volumes

    echo -e "${GREEN}Overlay2 fix complete!${NC}"
}
# Function for full system reset
full_reset() {
    echo -e "${RED}WARNING: This will remove all Docker containers, images, and reset CasaOS settings!${NC}"
    read -p "Are you sure you want to continue? (y/N): " confirm
    if [[ $confirm == [yY] ]]; then
        echo -e "${YELLOW}Performing full system reset...${NC}"
        
        # Stop services
        systemctl stop docker
        systemctl stop casaos

        # Backup and clean Docker
        timestamp=$(date +%Y%m%d_%H%M%S)
        if [ -d "/var/lib/docker" ]; then
            mv /var/lib/docker "/var/lib/docker.backup_${timestamp}"
        fi

        # Backup CasaOS data
        if [ -d "/var/lib/casaos" ]; then
            mv /var/lib/casaos "/var/lib/casaos.backup_${timestamp}"
        fi

        # Remove Docker configuration
        rm -rf /etc/docker

        # Remove CasaOS
        curl -fsSL https://get.casaos.io/uninstall | sudo bash

        # Reinstall CasaOS
        curl -fsSL https://get.casaos.io | sudo bash

        # Reinstall Docker configuration
        mkdir -p /etc/docker
        cat > /etc/docker/daemon.json <<EOL
{
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ]
}
EOL

        # Create fresh Docker directory structure
        mkdir -p /var/lib/docker
        mkdir -p /var/lib/docker/overlay2
        mkdir -p /var/lib/docker/overlay2/l
        mkdir -p /var/lib/docker/tmp

        # Set permissions
        chown -R root:root /var/lib/docker
        chmod -R 755 /var/lib/docker
        chmod 700 /var/lib/docker/overlay2/l

        # Restart services
        systemctl daemon-reload
        systemctl start docker
        systemctl start casaos

        echo -e "${GREEN}Full system reset complete!${NC}"
    else
        echo "Reset cancelled."
    fi

}
# Main loop
while true; do
    show_menu
    case $choice in
        1)
            change_ip
            ;;
        2)
            run_diagnostics
            ;;
        3)
            fix_docker_permissions
            ;;
        4)
            fix_overlay2
            ;;
        5)
            full_reset
            ;;
        6)
            echo -e "${GREEN}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
done