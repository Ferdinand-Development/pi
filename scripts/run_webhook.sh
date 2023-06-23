#!/bin/bash

# Get the directory where the script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Load the environment variables from the .env file
source "$DIR/../.env"

# Navigate to the parent directory of the script
cd "$DIR/.."

# Check if the webhook binary is installed
if ! command -v webhook &>/dev/null; then
  echo "webhook is not installed. Installing..."

  # Install the webhook package using apt-get
  sudo apt-get update
  sudo apt-get install -y webhook
  
  # Check if the installation was successful
  if ! command -v webhook &>/dev/null; then
    echo "Failed to install webhook. Please make sure you have the necessary permissions or try installing manually."
    exit 1
  fi
  
  echo "webhook is installed successfully."
fi

echo "Running webhook"
export WEBHOOK_SECRET_KEY
# Run the webhook command with the loaded environment variables and passed arguments
webhook -hooks "$DIR/../webhook/hooks.json" -template -verbose -ip "0.0.0.0" -port 9000 "$@"
