#!/bin/bash

# Paths
HEROIC_EXEC="/userdata/system/add-ons/heroic/heroic.AppImage"
CREATE_LAUNCHERS_SCRIPT="/userdata/system/add-ons/heroic/create_game_launchers.sh"

# Function to check if Heroic is running
is_heroic_running() {
    pgrep -f "$HEROIC_EXEC" > /dev/null
}

echo "Monitoring Heroic process..."

# Wait for Heroic to start
echo "Waiting for Heroic to start..."
until is_heroic_running; do
    sleep 10
done

# Loop while Heroic is running
while true; do
    if is_heroic_running; then
        echo "Heroic is running. Checking launchers..."
        "$CREATE_LAUNCHERS_SCRIPT"
        sleep 1 # Wait for 1 second before checking again
    else
        echo "Heroic is not running. Exiting."
        curl http://127.0.0.1:1234/reloadgames
        break
    fi
done
