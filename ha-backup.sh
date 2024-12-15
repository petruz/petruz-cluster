#!/bin/bash

# Function to display help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --help            Show this help message and exit"
    echo "  -ha               Execute only the Home Assistant backup"
    echo "  -zb               Execute only the Zigbee2mqtt backup"
    echo "  (no options)      Execute both Home Assistant and Zigbee2mqtt backups"
}

# Home Assistant backup function
home_assistant_backup() {
    echo "Starting Home Assistant backup..."
    NAMESPACE="home-automation"
    POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=home-assistant -o jsonpath="{.items[0].metadata.name}")
    VOLUME_PATH="/config"
    LOCAL_BACKUP_DIR="/tmp/home-assistant-backup"
    REMOTE_BACKUP_DIR="gdrive:/home-assistant-backups"

    mkdir -p $LOCAL_BACKUP_DIR

    kubectl cp $NAMESPACE/$POD_NAME:$VOLUME_PATH $LOCAL_BACKUP_DIR
    if [ $? -ne 0 ]; then
        echo "Error: Failed to copy volume from Home Assistant pod."
        exit 1
    fi

    echo "Uploading Home Assistant backup to Google Drive..."
    rclone sync $LOCAL_BACKUP_DIR $REMOTE_BACKUP_DIR --progress
    if [ $? -ne 0 ]; then
        echo "Error: Failed to upload Home Assistant backup to Google Drive."
        exit 1
    fi

    echo "Home Assistant backup completed successfully."
    rm -rf $LOCAL_BACKUP_DIR
}

# Zigbee2mqtt backup function
zigbee2mqtt_backup() {
    echo "Starting Zigbee2mqtt backup..."
    NAMESPACE="home-automation"
    POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=zigbee2mqtt-switches -o jsonpath="{.items[0].metadata.name}")
    VOLUME_PATH="/data"
    LOCAL_BACKUP_DIR="/tmp/zigbee2mqtt-switches-backup"
    REMOTE_BACKUP_DIR="gdrive:/zigbee2mqtt-switches-backups"

    mkdir -p $LOCAL_BACKUP_DIR

    kubectl cp $NAMESPACE/$POD_NAME:$VOLUME_PATH $LOCAL_BACKUP_DIR
    if [ $? -ne 0 ]; then
        echo "Error: Failed to copy volume from Zigbee2mqtt pod."
        exit 1
    fi

    echo "Uploading Zigbee2mqtt backup to Google Drive..."
    rclone sync $LOCAL_BACKUP_DIR $REMOTE_BACKUP_DIR --progress
    if [ $? -ne 0 ]; then
        echo "Error: Failed to upload Zigbee2mqtt backup to Google Drive."
        exit 1
    fi

    echo "Zigbee2mqtt backup completed successfully."
    rm -rf $LOCAL_BACKUP_DIR
}

# Parse script arguments
if [[ $# -gt 1 ]]; then
    echo "Error: Too many arguments"
    show_help
    exit 1
fi

case "$1" in
    --help)
        show_help
        exit 0
        ;;
    -ha)
        home_assistant_backup
        exit 0
        ;;
    -zb)
        zigbee2mqtt_backup
        exit 0
        ;;
    "")
        home_assistant_backup
        zigbee2mqtt_backup
        exit 0
        ;;
    *)
        echo "Error: Invalid option"
        show_help
        exit 1
        ;;
esac
