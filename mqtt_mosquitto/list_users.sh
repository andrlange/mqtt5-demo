#!/bin/bash

# Script to list all MQTT users and their permissions
# Usage: ./list_users.sh

PASSWD_FILE="./vols/mosquitto/config/passwd"
ACL_FILE="./vols/mosquitto/config/acl"

echo "=== MQTT Users and Permissions ==="
echo ""

if [ ! -f "$PASSWD_FILE" ]; then
    echo "Password file not found: $PASSWD_FILE"
    exit 1
fi

if [ ! -f "$ACL_FILE" ]; then
    echo "ACL file not found: $ACL_FILE"
    exit 1
fi

# Extract usernames from password file
USERS=$(cut -d: -f1 "$PASSWD_FILE" | sort)

if [ -z "$USERS" ]; then
    echo "No users found in password file"
    exit 0
fi

echo "Users found:"
for user in $USERS; do
    echo ""
    echo "📋 User: $user"

    # Find user's permissions in ACL file
    PERMS=$(awk "
        /^user $user$/ {
            found=1; next
        }
        /^user / && found==1 {
            found=0
        }
        found==1 && /^topic / {
            print \"    \" \$0
        }
    " "$ACL_FILE")

    if [ -n "$PERMS" ]; then
        echo "  Permissions:"
        echo "$PERMS"

        # Determine user type
        if echo "$PERMS" | grep -q "write"; then
            echo "  Type: 📤 Publisher (can publish and subscribe)"
        else
            echo "  Type: 📥 Subscriber (can only subscribe)"
        fi
    else
        echo "  Permissions: ❌ No permissions found in ACL"
    fi
done

echo ""
echo "=== Quick Test Commands ==="
echo ""
for user in $USERS; do
    # Check if user can publish
    if awk "/^user $user$/,/^user / { if(/topic write/) print }" "$ACL_FILE" | grep -q "write"; then
        echo "# Publisher: $user"
        echo "mosquitto_pub -h localhost -p 1883 -V 5 -u $user -P <password> -t test/topic -m 'Hello from $user'"
    else
        echo "# Subscriber: $user"
        echo "mosquitto_sub -h localhost -p 1883 -V 5 -u $user -P <password> -t test/topic"
    fi
done

echo ""
echo "=== Broker Status ==="
CONTAINER_ID=$(docker-compose ps -q mosquitto)
if [ -n "$CONTAINER_ID" ]; then
    echo "✅ Mosquitto broker is running"
    echo "Container ID: $CONTAINER_ID"
else
    echo "❌ Mosquitto broker is not running"
fi