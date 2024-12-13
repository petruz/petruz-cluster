#!/bin/bash

# Define variables
NAMESPACE="home-automation" # Replace with your namespace
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=home-assistant -o jsonpath="{.items[0].metadata.name}")
VOLUME_PATH="/config" # The path inside the container
LOCAL_BACKUP_DIR="/tmp/home-assistant-backup"
REMOTE_BACKUP_DIR="gdrive:/home-assistant-backups" # Google Drive remote setup in rclone

# Ensure local backup directory exists
mkdir -p $LOCAL_BACKUP_DIR

# Use rsync to copy the volume content to the local backup directory
echo "Starting backup from Kubernetes pod..."
kubectl cp $NAMESPACE/$POD_NAME:$VOLUME_PATH $LOCAL_BACKUP_DIR

if [ $? -ne 0 ]; then
    echo "Error: Failed to copy volume from pod."
    exit 1
fi

echo "Backup completed successfully. Starting upload to Google Drive..."

# Use rclone to upload the backup to Google Drive
rclone sync $LOCAL_BACKUP_DIR $REMOTE_BACKUP_DIR --progress

if [ $? -ne 0 ]; then
    echo "Error: Failed to upload backup to Google Drive."
    exit 1
fi

echo "Backup uploaded to Google Drive successfully."

# Clean up local backup directory
rm -rf $LOCAL_BACKUP_DIR

