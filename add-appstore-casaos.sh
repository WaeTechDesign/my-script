#!/bin/bash

# Define multiple App Store URLs (separated by commas)
APPSTORE_URLS="https://casaos-appstore.paodayag.dev/linuxserver.zip,https://play.cuse.eu.org/Cp0204-AppStore-Play.zip,https://play.cuse.eu.org/Cp0204-AppStore-Play-arm.zip,https://casaos-appstore.paodayag.dev/coolstore.zip,https://github.com/bigbeartechworld/big-bear-casaos,https://github.com/mariosemes/CasaOS-TMCstore/archive/refs/heads/main.zip,https://github.com/arch3rPro/Pentest-Docker/archive/refs/heads/master.zip"

# Check if CasaOS is installed
if ! command casaos -v &> /dev/null; then
    echo "CasaOS is not installed. Please install CasaOS first!"
    exit 1
fi

# Define CasaOS config file path
CONFIG_FILE="/etc/casaos/gateway.ini"

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "CasaOS configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Check if store_url exists in the config
if grep -q "store_url" "$CONFIG_FILE"; then
    # Replace existing store_url with new values
    sed -i "s|store_url=.*|store_url=$APPSTORE_URLS|" "$CONFIG_FILE"
    echo "App Store URLs updated successfully!"
else
    # Append new store_url if not found
    echo -e "\nstore_url=$APPSTORE_URLS" >> "$CONFIG_FILE"
    echo "App Store URLs added successfully!"
fi

# Restart CasaOS to apply changes
echo "Restarting CasaOS..."
sudo systemctl restart casaos

echo "Done! You can now access the added App Stores in CasaOS."
