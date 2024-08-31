#!/bin/bash

# Log file path
LOG_FILE="/var/log/portainer_update.log"

# Create or clear the log file
> "$LOG_FILE"

# Function to log messages
log_message() {
    echo "[LOG] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Start of the script
log_message "Starting the BIG upgrade script..."

# Upgrade the Ubuntu system
log_message "Upgrading Ubuntu..."
if sudo apt-get update && sudo apt-get upgrade -y 2>&1 | tee -a "$LOG_FILE"; then
    log_message "Ubuntu upgrade completed successfully."
else
    log_message "Failed to upgrade Ubuntu."
    exit 1
fi

# Check if the Portainer image is already up-to-date
log_message "Checking if Portainer image needs to be updated..."
pull_output=$(docker pull portainer/portainer-ce:latest 2>&1)

if echo "$pull_output" | grep -q "Status: Image is up to date for portainer/portainer-ce:latest"; then
    log_message "Portainer is already up-to-date. No update necessary."
    echo "Done! Check the log at $LOG_FILE"
    exit 0
else
    log_message "Portainer update required. Proceeding with the update..."
fi

# Stop the Portainer container
log_message "Stopping the Portainer container..."
if docker stop portainer 2>&1 | tee -a "$LOG_FILE"; then
    log_message "Portainer container stopped successfully."
else
    log_message "Failed to stop the Portainer container."
    exit 1
fi

# Sleep for 2 seconds
sleep 2

# Remove the Portainer container
log_message "Removing the Portainer container..."
if docker rm portainer 2>&1 | tee -a "$LOG_FILE"; then
    log_message "Portainer container removed successfully."
else
    log_message "Failed to remove the Portainer container."
    exit 1
fi

# Sleep for 2 seconds
sleep 2

# Run the new Portainer container
log_message "Running the new Portainer container..."
if docker run -d -p 8000:8000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest 2>&1 | tee -a "$LOG_FILE"; then
    log_message "Portainer container started successfully."
else
    log_message "Failed to start the Portainer container."
    exit 1
fi

log_message "Portainer update completed successfully!"
echo "Done! Check the log at $LOG_FILE"
