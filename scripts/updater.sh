#!/bin/bash

# Redirect stdout ( > ) and stderr (2>&1) to a logfile
exec > /var/log/updater.log 2>&1

# Define the lock file path
LOCK_FILE="/var/lock/updater.lock"

# Define the maximum number of retries
MAX_RETRIES=3

# Define the backoff time in seconds
BACKOFF_TIME=30

# Check for the lock file and retry if it exists
retry_count=0
while [ -e "$LOCK_FILE" ]; do
  if [ "$retry_count" -ge "$MAX_RETRIES" ]; then
    echo "Maximum number of retries reached. Another instance of the script is still running. Exiting."
    exit 1
  fi

  echo "Another instance of the script is already running. Retrying in $BACKOFF_TIME seconds..."
  sleep "$BACKOFF_TIME"
  retry_count=$((retry_count + 1))
done

# Create the lock file
touch "$LOCK_FILE"

# Function to release the lock
release_lock() {
  rm -f "$LOCK_FILE"
}

# Trap the EXIT signal to always release the lock
trap release_lock EXIT

# Get the directory where the script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )"

# Navigate to the parent directory
cd "$DIR"

# Pull the latest code from git
git pull

# Execute the setup cron script
./setup_cron.sh

# Fetch the latest images
docker-compose pull

# Refresh the compose setup
docker-compose down
docker-compose up -d --remove-orphans

sudo service webhook restart
