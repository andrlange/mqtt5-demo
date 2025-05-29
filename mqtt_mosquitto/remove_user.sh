#!/bin/bash

# Script to remove MQTT users without stopping the broker
# Usage: ./remove_user.sh <username>

if [ $# -ne 1 ]; then
    echo "Usage: $0 <username>"
    echo "Example: $0 olduser"
    exit 1
fi

USERNAME=$1
PASSWD_FILE="./vols/mosquitto/config/passwd"
ACL_FILE="./vols/mosquitto/config/acl"

# Check if user exists
if ! grep -q "^$USERNAME:" "$PASSWD_FILE" 2>/dev/null; then
    echo "User $USERNAME does not exist in password file"
    exit 1
fi

echo "Removing user: $USERNAME"

# Remove user from password file
echo "Updating password file..."
docker run --rm -v "$PWD/vols/mosquitto/config:/mosquitto/config" \
    eclipse-mosquitto:2.0.21 mosquitto_passwd -D /mosquitto/config/passwd "$USERNAME"

# Remove user from ACL file
echo "Updating ACL permissions..."
if grep -q "^user $USERNAME" "$ACL_FILE"; then
    # Create temp file without the user and their permissions
    awk "
    /^user $USERNAME$/ {
        skip=1; next
    }
    /^user / && skip==1 {
        skip=0
    }
    skip==0 || !/^topic / {
        print
    }
    " "$ACL_FILE" > "${ACL_FILE}.tmp" && mv "${ACL_FILE}.tmp" "$ACL_FILE"

    echo "Removed $USERNAME from ACL file"
else
    echo "User $USERNAME not found in ACL file"
fi

# Reload Mosquitto configuration
echo "Reloading Mosquitto configuration..."
CONTAINER_ID=$(docker-compose ps -q mosquitto)

if [ -n "$CONTAINER_ID" ]; then
    docker kill --signal=HUP "$CONTAINER_ID"
    echo "User $USERNAME removed successfully!"
    echo "Configuration reloaded without interrupting the broker."
else
    echo "Warning: Mosquitto container not found. Please restart manually:"
    echo "docker-compose restart mosquitto"
fi