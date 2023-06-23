#!/bin/bash

: '
This script performs a backup operation of the specified Raspberry Pi SD card and stores the backup in a specified directory. 

By default, it retains the seven most recent backups and removes any older backups. However, the number of backups to keep can be configured by passing the number as an argument to the script.

Upon the successful completion of the backup, the script sends a POST request to a specified Home Assistant server. This action triggers an event on the Home Assistant side indicating the completion of the backup operation. This Home Assistant integration can be turned off by passing a certain flag.
'

# Check if the script is running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root. Please try again with 'sudo'."
    exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$DIR/../.env"

# Default values
SD_CARD="/dev/mmcblk0"
BACKUP_DIR="/media/usb/backup"
NUM_BACKUPS=7
HASS_SERVER="http://127.0.0.1:8123"
HASS_TOKEN="your-long-lived-access-token"
EVENT_NAME="backup_completed"
HASS_INTEGRATION=true
FILE_NAME="pi_backup_"

# Help function
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "OPTIONS:"
    echo "-h, --help               Show help information and exit."
    echo "-s, --sdcard DEVICE      Specify the SD card device to backup."
    echo "-d, --dir DIRECTORY      Specify the backup directory."
    echo "-n, --num-backups NUMBER Specify the number of backups to keep."
    echo "-a, --hass-address ADDR  Specify the Home Assistant server address."
    echo "-t, --hass-token TOKEN   Specify the Home Assistant API token. Default: 127.0.0.1:8123"
    echo "-e, --event-name NAME    Specify the event name for Home Assistant."
    echo "-x, --no-hass            Disable the Home Assistant integration. Default true"
    echo "-f, --file-name          File name for backups. Default: pi_backup_"
    echo
    echo "EXAMPLE:"
    echo "$0 -s /dev/mmcblk0 -d /media/usb/backup -n 7 -a http://your-home-assistant-ip:8123 -t your-long-lived-access-token -e backup_completed"
    exit 1
}

# Parse command-line options
while getopts ":hs:d:n:a:t:e:x" OPTION; do
    case $OPTION in
        h)
            usage
            ;;
        s)
            SD_CARD=$OPTARG
            ;;
        d)
            BACKUP_DIR=$OPTARG
            ;;
        n)
            NUM_BACKUPS=$OPTARG
            ;;
        a)
            HASS_SERVER=$OPTARG
            ;;
        t)
            HASS_TOKEN=$OPTARG
            ;;
        e)
            EVENT_NAME=$OPTARG
            ;;
        x)
            HASS_INTEGRATION=false
            ;;
        f)
            FILE_NAME=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

# Define the backup filename
FILE_NAME="${FILE_NAME}$(date +"%Y_%m_%d_%H_%M_%S").img"

# Create backup directory if it doesn't exist
mkdir -p ${BACKUP_DIR}

# Backup the SD Card
if dd if=${SD_CARD} of=${BACKUP_DIR}/${FILE_NAME} bs=1M
then
    echo "Backup successful."
    # If backup is successful and Home Assistant integration is enabled, send event to Home Assistant
    if [ "$HASS_INTEGRATION" = true ]
    then
            # Get the remaining disk space
        disk_space=$(df ${BACKUP_DIR} | awk 'NR==2 {print $4}')

        # Get the file size
        file_size=$(ls -lh "${BACKUP_DIR}/${FILE_NAME}" | awk '{ print $5}')

        # Get the current timestamp
        timestamp=$(date)

        # Filename
        filename=$(basename "${BACKUP_DIR}/${FILE_NAME}")

        for i in {1..3}
        do
            curl -X POST -H "Authorization: Bearer ${HASS_TOKEN}" \
                -H "Content-Type: application/json" \
                --retry 3 --max-time 10 \
                -d '{
                    "event_type": "'${EVENT_NAME}'",
                    "event_data": {
                        "message": "Backup completed successfully",
                        "disk_space": "'${disk_space}'",
                        "file_size": "'${file_size}'",
                        "timestamp": "'${timestamp}'",
                        "filename": "'${filename}'"
                    }
                }' \
                ${HASS_SERVER}/api/events/${EVENT_NAME} && break
            echo "Failed to send event to Home Assistant. Retrying..."

        done
    fi
else
    echo "Backup failed."
    exit 1
fi

# Keep only the last n backups
cd ${BACKUP_DIR}
(ls -t|head -n ${NUM_BACKUPS};ls)|sort|uniq -u|xargs -I {} rm -- {}

echo "Old backups removed. Script completed successfully."
