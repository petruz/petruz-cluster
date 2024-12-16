#!/bin/bash

# Function to display help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --help            Show this help message and exit"
    echo "  -ha               Execute only the Home Assistant restore"
    echo "  -zb               Execute only the Zigbee2mqtt restore"
    echo "  (no options)      Execute both Home Assistant and Zigbee2mqtt restores"
}

# Home Assistant restore function
home_assistant_restore() {
    echo "Starting Home Assistant restore..."
    NAMESPACE="home-automation"
    POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=home-assistant -o jsonpath="{.items[0].metadata.name}")
    VOLUME_PATH="/config"
    LOCAL_RESTORE_DIR="/tmp/home-assistant-restore"
    REMOTE_BACKUP_DIR="gdrive:/home-assistant-backups"

    mkdir -p $LOCAL_RESTORE_DIR

    echo "Fetching Home Assistant backup from Google Drive..."
    rclone sync $REMOTE_BACKUP_DIR $LOCAL_RESTORE_DIR --progress
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch Home Assistant backup from Google Drive."
        exit 1
    fi

    echo "Restoring Home Assistant backup to Kubernetes pod..."
    kubectl cp $LOCAL_RESTORE_DIR/. $NAMESPACE/$POD_NAME:$VOLUME_PATH
    if [ $? -ne 0 ]; then
        echo "Error: Failed to restore Home Assistant backup to pod."
        exit 1
    fi

    echo "Restarting the Home Assistant pod..."
    kubectl delete pod $POD_NAME -n $NAMESPACE
    if [ $? -ne 0 ]; then
        echo "Error: Failed to restart the Home Assistant pod."
        exit 1
    fi

    echo "Home Assistant restore completed successfully."
    rm -rf $LOCAL_RESTORE_DIR
}

zigbee2mqtt_restore() {
    echo "Starting Zigbee2mqtt restore..."
    NAMESPACE="home-automation"
    CLAIM_NAME="z2m-switches-data"
    LOCAL_RESTORE_DIR="/tmp/zigbee2mqtt-restore"
    REMOTE_BACKUP_DIR="gdrive:/zigbee2mqtt-switches-backups"

    mkdir -p $LOCAL_RESTORE_DIR

    echo "Fetching Zigbee2mqtt backup from Google Drive..."
    rclone sync $REMOTE_BACKUP_DIR $LOCAL_RESTORE_DIR --progress
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch Zigbee2mqtt backup from Google Drive."
        exit 1
    fi

    echo "Finding Persistent Volume details..."
    PV_NAME=$(kubectl get pvc $CLAIM_NAME -n $NAMESPACE -o jsonpath="{.spec.volumeName}")
    PV_HOST_PATH=$(sudo find /var/lib/kubelet -name $PV_NAME)

    if [ -z "$PV_HOST_PATH" ]; then
        echo "Error: Node hosting the volume could not be determined."
        exit 1
    fi

    echo "Restoring Zigbee2mqtt data to $PV_HOST_PATH on node $NODE_NAME..."
    sudo mkdir -p $PV_HOST_PATH

    sudo rsync -av --delete $LOCAL_RESTORE_DIR/. $PV_HOST_PATH
    if [ $? -ne 0 ]; then
        echo "Error: Failed to restore Zigbee2mqtt data to Persistent Volume."
        exit 1
    fi

    echo "Zigbee2mqtt restore completed successfully."
    sudo rm -rf $LOCAL_RESTORE_DIR
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
        home_assistant_restore
        exit 0
        ;;
    -zb)
        zigbee2mqtt_restore
        exit 0
        ;;
    "")
        home_assistant_restore
        zigbee2mqtt_restore
        exit 0
        ;;
    *)
        echo "Error: Invalid option"
        show_help
        exit 1
        ;;
esac
