#!/bin/bash

# Define variables
NAMESPACE="home-automation" # Replace with your namespace
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=home-assistant -o jsonpath="{.items[0].metadata.name}")
VOLUME_PATH="/config" # The path inside the container
LOCAL_RESTORE_DIR="/tmp/home-assistant-restore"
REMOTE_BACKUP_DIR="gdrive:/home-assistant-backups"

# Ensure local restore directory exists
mkdir -p $LOCAL_RESTORE_DIR

# Fetch the latest backup from Google Drive
echo "Fetching backup from Google Drive..."
rclone sync $REMOTE_BACKUP_DIR $LOCAL_RESTORE_DIR --progress

if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch backup from Google Drive."
    exit 1
fi

echo "Backup fetched successfully. Starting restore to Kubernetes pod..."

# Use kubectl to copy the backup to the pod
kubectl cp $LOCAL_RESTORE_DIR/. $NAMESPACE/$POD_NAME:$VOLUME_PATH

if [ $? -ne 0 ]; then
    echo "Error: Failed to restore backup to pod."
    exit 1
fi

echo "Restore completed successfully. Restarting the Home Assistant pod..."

# Restart the pod by deleting it (Kubernetes will recreate it automatically)
kubectl delete pod $POD_NAME -n $NAMESPACE

if [ $? -ne 0 ]; then
    echo "Error: Failed to restart the pod."
    exit 1
fi

echo "Pod restarted successfully."

# Clean up local restore directory
rm -rf $LOCAL_RESTORE_DIR

