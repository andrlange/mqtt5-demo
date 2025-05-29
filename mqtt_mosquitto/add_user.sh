#!/bin/bash

# Script to add new MQTT users without stopping the broker
# Usage: ./add_user.sh <username> <password> <type>
# Type: "publisher" or "subscriber"

if [ $# -ne 3 ]; then
    echo "Usage: $0 <username> <password> <publisher|subscriber>"
    echo "Example: $0 newuser mypassword subscriber"
    exit 1
fi

USERNAME=$1
PASSWORD=$2
USER_TYPE=$3

PASSWD_FILE="./vols/mosquitto/config/passwd"
ACL_FILE="./vols/mosquitto/config/acl"

# Validate user type
if [ "$USER_TYPE" != "publisher" ] && [ "$USER_TYPE" != "subscriber" ]; then
    echo "Error: User type must be 'publisher' or 'subscriber'"
    exit 1
fi

# Check if user already exists
if grep -q "^$USERNAME:" "$PASSWD_FILE" 2>/dev/null; then
    echo "User $USERNAME already exists. Updating password..."
else
    echo "Adding new user: $USERNAME"
fi

# Add/update user in password file
echo "Updating password file..."
docker run --rm -v "$PWD/vols/mosquitto/config:/mosquitto/config" \
    eclipse-mosquitto:2.0.21 mosquitto_passwd -b /mosquitto/config/passwd "$USERNAME" "$PASSWORD"

# Update ACL file
echo "Updating ACL permissions..."
if ! grep -q "^user $USERNAME" "$ACL_FILE"; then
    echo "" >> "$ACL_FILE"
    echo "user $USERNAME" >> "$ACL_FILE"

    if [ "$USER_TYPE" = "publisher" ]; then
        echo "topic write #" >> "$ACL_FILE"
        echo "topic read #" >> "$ACL_FILE"  # Publishers can also read
        echo "Added publisher permissions for $USERNAME"
    else
        echo "topic read #" >> "$ACL_FILE"
        echo "Added subscriber permissions for $USERNAME"
    fi
else
    echo "User $USERNAME already exists in ACL file"
fi

# Reload Mosquitto configuration without stopping the broker
echo "Reloading Mosquitto configuration..."
CONTAINER_ID=$(docker-compose ps -q mosquitto)

if [ -n "$CONTAINER_ID" ]; then
    # Send SIGHUP signal to reload configuration
    docker kill --signal=HUP "$CONTAINER_ID"
    echo "Configuration reloaded successfully!"
    echo ""
    echo "New user credentials:"
    echo "  Username: $USERNAME"
    echo "  Password: $PASSWORD"
    echo "  Type: $USER_TYPE"
    echo ""
    echo "Test the new user:"
    if [ "$USER_TYPE" = "publisher" ]; then
        echo "  mosquitto_pub -h localhost -p 1883 -V 5 -u $USERNAME -P $PASSWORD -t test/topic -m 'Hello from $USERNAME'"
    else
        echo "  mosquitto_sub -h localhost -p 1883 -V 5 -u $USERNAME -P $PASSWORD -t test/topic"
    fi
else
    echo "Warning: Mosquitto container not found. Please restart manually:"
    echo "docker-compose restart mosquitto"
fi