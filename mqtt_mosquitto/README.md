# Mosquitto MQTT5 Broker Setup

This setup provides a Mosquitto MQTT5 broker running in Docker with configuration mounted from your local machine.

## Prerequisites

- Docker Desktop installed on macOS
- Terminal access

## Setup Instructions

### 1. Setup folder structure

```bash
# Create main folders keeping mosquitto data
# Make script executable
chmod +x setup.sh

./setup.sh

```

### 2. Start the Broker

```bash
# Start Mosquitto broker
docker-compose up -d

# Check if it's running
docker-compose ps

# View logs
docker-compose logs -f mosquitto
```

## User Authentication

The broker is configured with 4 users:

### Publisher User (can publish messages)
- **Username**: `publisher`
- **Password**: `publisher123`
- **Permissions**: Can publish to any topic (#)

### Subscriber Users (can only subscribe)
- **Username**: `subscriber1`, **Password**: `sub123`
- **Username**: `subscriber2`, **Password**: `sub456`
- **Username**: `subscriber3`, **Password**: `sub789`
- **Permissions**: Can subscribe to any topic (#)

## Testing with Authentication

### Using mosquitto_pub/mosquitto_sub

```bash
# Test publishing with publisher user
mosquitto_pub -h localhost -p 1883 -V 5 -u publisher -P publisher123 -t test/topic -m "Hello from Publisher"

# Test subscribing with subscriber1
mosquitto_sub -h localhost -p 1883 -V 5 -u subscriber1 -P sub123 -t test/topic

# Test permission denied - subscriber trying to publish (should fail)
mosquitto_pub -h localhost -p 1883 -V 5 -u subscriber1 -P sub123 -t test/topic -m "This should fail"
```

### Using Docker containers

```bash
# Subscribe with subscriber2
docker run -it --rm --network mqtt-demo_mqtt-network eclipse-mosquitto:2.0.21 \
  mosquitto_sub -h mosquitto-broker -p 1883 -V 5 -u subscriber2 -P sub456 -t test/topic

# Publish with publisher user
docker run -it --rm --network mqtt-demo_mqtt-network eclipse-mosquitto:2.0.21 \
  mosquitto_pub -h mosquitto-broker -p 1883 -V 5 -u publisher -P publisher123 -t test/topic -m "Authenticated message"
```

## Configuration Details

- **MQTT Port**: 1883 (unencrypted)
- **WebSocket Port**: 9001
- **SSL Port**: 8883 (prepared for future SSL setup)
- **Protocol**: MQTT v5.0 enabled
- **Authentication**: File-based authentication enabled (no anonymous connections)
- **Authorization**: ACL-based topic permissions
- **Persistence**: Enabled with data stored in `./vols/mosquitto/data`
- **Logs**: Available in `./vols/mosquitto/log`

## Dynamic User Management

You can add/remove users **without stopping the broker** using the provided scripts:

### Add New Users
```bash
# Make scripts executable
chmod +x add_user.sh remove_user.sh list_users.sh reload_config.sh

# Add a new subscriber
./add_user.sh newsubscriber mypassword123 subscriber

# Add a new publisher  
./add_user.sh newpublisher pubpass456 publisher
```

### Remove Users
```bash
# Remove a user
./remove_user.sh olduser
```

### List All Users
```bash
# Show all users and their permissions
./list_users.sh
```

### Manual Configuration Reload
```bash
# If you manually edit config files, reload without stopping broker
./reload_config.sh
```

### Manual User Management (Alternative)

If you prefer manual commands:

```bash
# Add user to password file
docker run --rm -v "$(pwd)/vols/mosquitto/config:/mosquitto/config" \
    eclipse-mosquitto:2.0.21 mosquitto_passwd -b /mosquitto/config/passwd username password

# Remove user from password file  
docker run --rm -v "$(pwd)/vols/mosquitto/config:/mosquitto/config" \
    eclipse-mosquitto:2.0.21 mosquitto_passwd -D /mosquitto/config/passwd username

# Edit ACL file manually
nano ./vols/mosquitto/config/acl

# Reload configuration (sends SIGHUP signal)
docker kill --signal=HUP $(docker-compose ps -q mosquitto)
```

### How Hot Reload Works

- **SIGHUP signal**: Mosquitto reloads config files without dropping connections
- **No downtime**: Existing clients stay connected
- **New rules apply**: New connections use updated authentication/authorization
- **Safe operation**: If config has errors, old config remains active

## Future SSL Setup

The configuration is prepared for SSL certificates. When ready:

1. Generate self-signed certificates in `./vols/mosquitto/certs/`
2. Uncomment SSL listener section in `mosquitto.conf`
3. Restart the container

## Troubleshooting

### Permission Issues
```bash
# Fix permissions if needed
sudo chown -R $(id -u):$(id -g) ./vols/mosquitto
chmod -R 755 ./vols/mosquitto
```

### Container Logs
```bash
# View detailed logs
docker-compose logs mosquitto

# Real-time logs
docker-compose logs -f mosquitto
```

### Network Issues
```bash
# Check if ports are available
netstat -an | grep -E "1883|8883|9001"

# Test connection
telnet localhost 1883
```

## Next Steps

Once this Mosquitto broker is running, you can:
1. Create your Spring Boot MQTT publisher
2. Build your Dart MQTT subscriber
3. Test the complete message flow

The broker is now ready to handle MQTT5 messages from your Spring Boot application and deliver them to your Dart client!