#!/bin/bash

# Get the directory where the script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# The path to the script
SCRIPT_PATH="$DIR/scripts"

# Setup cron jobs
CRON_DIR=$DIR/cron.d

# Label to identify automatic jobs
LABEL="# AUTOMATIC_JOB"

# Remove existing automatic jobs
crontab -l | grep -v "$LABEL" | crontab -

for file in $CRON_DIR/*; do
    jobname=$(basename $file)

    # Replace the placeholder in the cron job file with the actual path
    jobcontent=$(sed "s|\$SCRIPT_PATH|$SCRIPT_PATH|g" $file)

    # Add label to the job
    jobcontent="$jobcontent $LABEL"

    # Add job to the crontab
    (crontab -l; echo "$jobcontent") | crontab -
done
