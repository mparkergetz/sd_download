#!/bin/bash
# INSTALL FOR POPUPS: sudo apt install libnotify-bin
# ADD AUTO DELETION OF ORIGINAL CONTENTS??
# IF SCALING UP TO MULTIPLE READERS, NEED TO FIGURE OUT MOUNT SCHEME/GIVE SD CARDS UNIQUE NAMES

BACKUP_DIR="/home/misha/data/sd_test" # SET TO SDD
TEMP_DIR="/tmp/bee_cam_backup"
USERNAME="misha"  # PC USERNAME
USER_ID=$(id -u "$USERNAME")
LOGFILE="/home/misha/repos/sd_download/logs/run.log"
MOUNT_BASE="/media/$USERNAME" # FINDS ALL SD CARDS. SD CARDS SHOULD BE GIVEN UNIQUE NAMES IN FUTURE
TIMEOUT=30
TIMER=0
FOUND=0

echo "$(date '+%Y-%m-%d %H:%M:%S') ===== Starting Backup =====" >> "$LOGFILE"

while [ "$TIMER" -lt "$TIMEOUT" ]; do
    for mount in "$MOUNT_BASE"/*; do
        if [ -d "$mount/home/pi/bee_cam/data" ]; then
            FOUND=1
            TARGET="$mount"
            break
        fi
    done
    if [ "$FOUND" -eq 1 ]; then
        break
    fi
    sleep 1
    TIMER=$((TIMER+1))
done

if [ "$FOUND" -ne 1 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: No mounted bee_cam device found. Exiting." >> "$LOGFILE"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') Found bee_cam data at $TARGET" >> "$LOGFILE"
mkdir -p "$TEMP_DIR"
TAR_FILE="$TEMP_DIR/bee_cam_backup_$(basename "$TARGET")_$(date +%Y%m%d_%H%M%S).tar"
echo "$(date '+%Y-%m-%d %H:%M:%S') Tarring data into $TAR_FILE" >> "$LOGFILE"
tar -cf "$TAR_FILE" -C "$TARGET/home/pi/bee_cam" data >> "$LOGFILE" 2>&1

if [ "$?" -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: Failed to create TAR archive!" >> "$LOGFILE"
    exit 2
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') Syncing TAR to $BACKUP_DIR" >> "$LOGFILE"
rsync -av --progress --inplace --partial "$TAR_FILE" "$BACKUP_DIR/" >> "$LOGFILE" 2>&1

if [ "$?" -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: Rsync failed!" >> "$LOGFILE"
    exit 3
fi

BACKUP_TAR="$BACKUP_DIR/$(basename "$TAR_FILE")"
echo "$(date '+%Y-%m-%d %H:%M:%S') Verifying TAR integrity at $BACKUP_TAR" >> "$LOGFILE"
tar -tvf "$BACKUP_TAR" > /dev/null 2>> "$LOGFILE"

if [ "$?" -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Verification SUCCESSFUL." >> "$LOGFILE"
    export DISPLAY=:0
    export XAUTHORITY=/home/$USERNAME/.Xauthority
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus"
    /usr/bin/notify-send "BeeCam Backup" "Backup and verification successful!" --icon=dialog-information
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: TAR verification FAILED!" >> "$LOGFILE"
    export DISPLAY=:0
    export XAUTHORITY=/home/$USERNAME/.Xauthority
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus"
    /usr/bin/notify-send "BeeCam Backup" "WARNING: Backup verification FAILED!" --icon=dialog-warning
    exit 4
fi

rm -f "$TAR_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') Temporary file $TAR_FILE removed" >> "$LOGFILE"

echo "$(date '+%Y-%m-%d %H:%M:%S') ===== BeeCam Backup Complete =====" >> "$LOGFILE"
exit 0