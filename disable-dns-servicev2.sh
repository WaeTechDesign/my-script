#!/bin/bash

# Define file paths
SCRIPT_PATH="/usr/local/bin/disable-dns.sh"
SERVICE_PATH="/etc/systemd/system/disable-dns.service"

# Create the disable-dns.sh script
echo "Creating disable-dns.sh script..."
cat << 'EOF' > $SCRIPT_PATH
#!/bin/bash

# Disable and stop DNS services
echo "Disabling and stopping systemd-resolved..."
systemctl disable resolvconf-pull-resolved.service
systemctl disable resolvconf-pull-resolved.path
sudo systemctl stop dnsmasq

# Check if port 53 is clear
echo "Checking if port 53 is clear..."
if lsof -i :53 | grep -q '.'; then
    echo "Port 53 is still in use."
else
    echo "Port 53 is clear."
fi
EOF

# Make the script executable
chmod +x $SCRIPT_PATH

# Create the disable-dns.service file
echo "Creating disable-dns.service systemd unit..."
cat << 'EOF' > $SERVICE_PATH
[Unit]
Description=Disable DNS Services on Boot
After=network.target

[Service]
ExecStart=/bin/bash /usr/local/bin/disable-dns.sh
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize the new service
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Enable the service to run on boot
echo "Enabling disable-dns.service..."
systemctl enable disable-dns.service

# Start the service immediately
echo "Starting disable-dns.service..."
systemctl start disable-dns.service

echo "Setup complete! The script will disable DNS services on boot."
