#!/bin/bash

# Path ke file konfigurasi app-management.conf
CONF_FILE="/etc/casaos/app-management.conf"

# URL App Store yang ingin ditambahkan
APPSTORE_URLS=(
    "https://casaos.app/store/main.zip"
    "https://github.com/bigbeartechworld/big-bear-casaos/archive/refs/heads/master.zip"
    "https://casaos-appstore.paodayag.dev/linuxserver.zip"
    "https://play.cuse.eu.org/Cp0204-AppStore-Play.zip"
    "https://play.cuse.eu.org/Cp0204-AppStore-Play-arm.zip"
    "https://casaos-appstore.paodayag.dev/coolstore.zip"
    "https://github.com/mariosemes/CasaOS-TMCstore/archive/refs/heads/main.zip"
    "https://github.com/arch3rPro/Pentest-Docker/archive/refs/heads/master.zip"
)

# Backup file konfigurasi sebelum diubah
cp "$CONF_FILE" "$CONF_FILE.bak"

# Fungsi untuk menambahkan URL App Store ke dalam file konfigurasi
add_appstore_urls() {
    # Cek apakah file sudah mengandung baris [server] dengan appstore
    if grep -q '\[server\]' "$CONF_FILE"; then
        echo "Section [server] found, adding appstore URLs..."
    else
        echo "[server]" >> "$CONF_FILE"
        echo "Created [server] section in $CONF_FILE"
    fi

    # Tambahkan URL appstore ke bagian [server]
    for URL in "${APPSTORE_URLS[@]}"; do
        # Cek jika URL sudah ada di file untuk menghindari duplikasi
        if ! grep -q "$URL" "$CONF_FILE"; then
            echo "appstore = $URL" >> "$CONF_FILE"
            echo "Added: $URL"
        else
            echo "URL already exists: $URL"
        fi
    done
}

# Panggil fungsi untuk menambahkan URL App Store
add_appstore_urls

# Restart CasaOS untuk menerapkan perubahan
echo "Restarting CasaOS, Please reload browser after 1 Minutes..."
sleep 10
sudo reboot