#!/usr/bin/env bash

lan_ip=$(hostname -I | awk '{print $1}')

cp /DATA/AppData/big-bear-nextcloud-smb/html/config/config.php /DATA/AppData/big-bear-nextcloud-smb/html/config/config.php.bak

awk -v ip="$lan_ip" '/0 => '\''localhost'\''/{print; print "    1 => '\''"ip"'\'',"; next}1' /DATA/AppData/big-bear-nextcloud-smb/html/config/config.php.bak > /DATA/AppData/big-bear-nextcloud-smb/html/config/config.php

COMPOSE_FILE="/var/lib/casaos/apps/big-bear-nextcloud-smb/docker-compose.yml"

casaos-cli app-management apply "big-bear-nextcloud-smb" --file="$COMPOSE_FILE"