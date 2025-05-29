#!/bin/bash

# Script to manually reload Mosquitto configuration without stopping the broker
# Usage: ./reload_config.sh

echo "Reloading Mosquitto configuration..."

# Get the container ID
CONTAINER_ID=$(docker-compose ps -q mosquitto)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ Error: Mosquitto container not found or not running"
    echo "Please start the broker first:"
    echo "docker-compose up -d"
    exit 1
fi

# Send SIGHUP signal to reload configuration
echo "Sending SIGHUP signal to container $CONTAINER_ID..."
docker kill --signal=HUP "$CONTAINER_ID"

# Check if successful
if [ $? -eq 0 ]; then
    echo "✅ Configuration reloaded successfully!"
    echo ""
    echo "The broker has reloaded:"
    echo "  - Password file (/mosquitto/config/passwd)"
    echo "  - ACL file (/mosquitto/config/acl)"
    echo "  - Main configuration (/mosquitto/config/mosquitto.conf)"
    echo ""
    echo "All existing client connections remain active."
    echo "New connections will use the updated configuration."
else
    echo "❌ Failed to reload configuration"
    echo "You may need to restart the broker manually:"
    echo "docker-compose restart mosquitto"
fi

# Show recent logs
echo ""
echo "Recent broker logs:"
docker-compose logs --tail 10 mosquitto