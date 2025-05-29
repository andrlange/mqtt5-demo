#!/bin/bash

# Mosquitto MQTT5 Setup Script for macOS with Docker Desktop

echo "Setting up Mosquitto MQTT5 Broker..."

rm -rf ./vols

# Create directory structure
echo "Creating directory structure..."
mkdir -p ./vols/mosquitto/config
mkdir -p ./vols/mosquitto/data
mkdir -p ./vols/mosquitto/log
mkdir -p ./vols/mosquitto/certs

cp ./mosquitto_config/* ./vols/mosquitto/config/

# Set proper permissions for mosquitto user inside container (uid 1883)
echo "Setting permissions..."
chmod -R 755 ./vols/mosquitto
chown -R $(id -u):$(id -g) ./vols/mosquitto

# Check if mosquitto.conf exists
if [ ! -f "./vols/mosquitto/config/mosquitto.conf" ]; then
    echo "Please copy the mosquitto.conf file to ./vols/mosquitto/config/"
    echo "You can find the configuration in the mosquitto_config artifact."
    exit 1
fi

# Check if acl file exists
if [ ! -f "./vols/mosquitto/config/acl" ]; then
    echo "Please copy the acl file to ./vols/mosquitto/config/"
    echo "You can find the ACL configuration in the mosquitto_acl artifact."
    exit 1
fi

# Create password file with users
echo "Creating password file with users..."
PASSWD_FILE="./vols/mosquitto/config/passwd"

# Remove existing password file
rm -f "$PASSWD_FILE"

docker run --rm -v "$PWD/vols/mosquitto/config:/mosquitto/config" \
    eclipse-mosquitto:2.0.21 touch /mosquitto/config/passwd

docker run --rm -v "$PWD/vols/mosquitto/config:/mosquitto/config" \
    eclipse-mosquitto:2.0.21 chmod 0700 /mosquitto/config/passwd

docker run --rm -v "$PWD/vols/mosquitto/config:/mosquitto/config" \
    eclipse-mosquitto:2.0.21 chmod 0700 /mosquitto/config/acl

# Create users with passwords
# Publisher user (can publish messages)
echo "Creating publisher user..."
docker run --rm -v "$PWD/vols/mosquitto/config:/mosquitto/config" \
    eclipse-mosquitto:2.0.21 mosquitto_passwd -b /mosquitto/config/passwd publisher publisher123

# Subscriber users (can only subscribe)
echo "Creating subscriber users..."
docker run --rm -v "$PWD/vols/mosquitto/config:/mosquitto/config" \
    eclipse-mosquitto:2.0.21 mosquitto_passwd -b /mosquitto/config/passwd subscriber1 sub123

docker run --rm -v "$PWD/vols/mosquitto/config:/mosquitto/config" \
    eclipse-mosquitto:2.0.21 mosquitto_passwd -b /mosquitto/config/passwd subscriber2 sub456

docker run --rm -v "$PWD/vols/mosquitto/config:/mosquitto/config" \
    eclipse-mosquitto:2.0.21 mosquitto_passwd -b /mosquitto/config/passwd subscriber3 sub789

echo "Password file created successfully!"
echo ""
echo "Users created:"
echo "  Publisher: username=publisher, password=publisher123"
echo "  Subscriber 1: username=subscriber1, password=sub123"
echo "  Subscriber 2: username=subscriber2, password=sub456"
echo "  Subscriber 3: username=subscriber3, password=sub789"

echo "Directory structure created successfully!"
echo ""
echo "Directory structure:"
tree ./vols/ 2>/dev/null || find ./vols -type d

echo ""
echo "To start Mosquitto broker:"
echo "docker-compose up -d"
echo ""
echo "To view logs:"
echo "docker-compose logs -f mosquitto"
echo ""
echo "To stop:"
echo "docker-compose down"
echo ""
echo "MQTT5 Broker will be available at:"
echo "- MQTT: localhost:1883"
echo "- WebSocket: localhost:9001"
echo "- SSL (future): localhost:8883"