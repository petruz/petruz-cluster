#!/bin/bash

## Home Assistant backup

# Define variables
NAMESPACE="home-automation" # Replace with your namespace
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=home-assistant -o jsonpath="{.items[0].metadata.name}")
VOLUME_PATH="/config" # The path inside the container
LOCAL_BACKUP_DIR="/tmp/home-assistant-backup"
REMOTE_BACKUP_DIR="gdrive:/home-assistant-backups" # Google Drive remote setup in rclone

# Ensure local backup directory exists
mkdir -p $LOCAL_BACKUP_DIR

# Use rsync to copy the volume content to the local backup directory
echo "Starting Home Assistant backup from Kubernetes pod..."
kubectl cp $NAMESPACE/$POD_NAME:$VOLUME_PATH $LOCAL_BACKUP_DIR

if [ $? -ne 0 ]; then
    echo "Error: Failed to copy volume from Home Assistant pod."
    exit 1
fi

echo "Home Assistant Backup completed successfully. Starting upload to Google Drive..."

# Use rclone to upload the backup to Google Drive
rclone sync $LOCAL_BACKUP_DIR $REMOTE_BACKUP_DIR --progress

if [ $? -ne 0 ]; then
    echo "Error: Failed to upload backup to Google Drive."
    exit 1
fi

echo "Home Assistant Backup uploaded to Google Drive successfully."

# Clean up local backup directory
rm -rf $LOCAL_BACKUP_DIR


## Zigbee2mqtt backup
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=zigbee2mqtt-switches -o jsonpath="{.items[0].metadata.name}")
VOLUME_PATH="/data" # The path inside the container

LOCAL_BACKUP_DIR="/tmp/zigbee2mqtt-switches-backup"
REMOTE_BACKUP_DIR="gdrive:/zigbee2mqtt-switches-backups" # Google Drive remote setup in rclone

# Ensure local backup directory exists
mkdir -p $LOCAL_BACKUP_DIR

# Use rsync to copy the volume content to the local backup directory
echo "Starting Zigbee2mqtt backup from Kubernetes pod..."
kubectl cp $NAMESPACE/$POD_NAME:$VOLUME_PATH $LOCAL_BACKUP_DIR

if [ $? -ne 0 ]; then
    echo "Error: Failed to copy volume from Zigbee2mqtt pod."
    exit 1
fi

echo "Zigbee2mqtt Backup completed successfully. Starting upload to Google Drive..."

# Use rclone to upload the backup to Google Drive
rclone sync $LOCAL_BACKUP_DIR $REMOTE_BACKUP_DIR --progress

if [ $? -ne 0 ]; then
    echo "Error: Failed to upload backup to Google Drive."
    exit 1
fi

echo "Zigbee2mqtt Backup uploaded to Google Drive successfully."

# Clean up local backup directory
rm -rf $LOCAL_BACKUP_DIR






