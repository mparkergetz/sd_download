#!/bin/bash
set -e  # EXIT ON FAILURE
SCRIPT_SRC="../sd_download.sh"
SERVICE_SRC="./sd_card_backup.service"
UDEV_SRC="./99-bee-cam.rules"
SERVICE_DEST="/etc/systemd/system/sd_card_backup.service"
UDEV_DEST="/etc/udev/rules.d/99-bee-cam.rules"

sudo chmod +x "$SCRIPT_SRC"
sudo cp "$UDEV_SRC" "$UDEV_DEST"

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Reloading udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo systemctl enable sd_card_backup.service

echo "Done"
