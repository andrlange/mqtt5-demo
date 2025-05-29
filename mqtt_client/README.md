# Dart MQTT5 Subscriber Client

A Dart 3.8 MQTT subscriber client that connects to Mosquitto broker and receives messages from specific topics with graceful shutdown support.

## Features

✅ **MQTT5 Connection** - Connects using MQTT v5.0 protocol  
✅ **Dual Topic Subscription** - Subscribes to both `client/{USERNAME}` and `clients/all`  
✅ **Command Line Parameters** - Username and password as CLI arguments  
✅ **Graceful Shutdown** - Handles Ctrl+C (SIGINT) and SIGTERM properly  
✅ **Auto-Reconnection** - Automatically reconnects if connection is lost  
✅ **Structured Logging** - Clear message formatting with timestamps  
✅ **Cross-Platform** - Works on Windows, macOS, and Linux

## Prerequisites

1. **Dart SDK 3.8+** installed
2. **Mosquitto MQTT Broker** running with authentication
3. Valid subscriber credentials from your Mosquitto setup

## Quick Start

### 1. Install Dependencies
```bash
dart pub get
```

### 2. Run the Subscriber
```bash
# Basic usage with subscriber1 credentials
dart run ./lib/main.dart -u subscriber1 -p sub123

# With custom host and port
dart run ./lib/main.dart -u subscriber2 -p sub456 -h localhost --port 1883

# With custom client ID
dart run ./lib/main.dart --username subscriber3 --password sub789 --client-id my-dart-client
```

### 3. Test Message Reception
Keep the Dart client running and use your Spring Boot API to send messages:

```bash
# Send message to all clients (should appear in Dart client)
curl -X POST http://localhost:8080/api/mqtt/publish/all \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from Spring Boot!"}'

# Send message to specific client (replace subscriber1 with your username)
curl -X POST http://localhost:8080/api/mqtt/publish/client/subscriber1 \
  -H "Content-Type: application/json" \
  -d '{"message": "Personal message for subscriber1"}'
```

## Command Line Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--username` | `-u` | MQTT username (required) | - |
| `--password` | `-p` | MQTT password (required) | - |
| `--host` | `-h` | MQTT broker hostname | `localhost` |
| `--port` | - | MQTT broker port | `1883` |
| `--client-id` | `-c` | MQTT client identifier | `dart-subscriber-{timestamp}` |
| `--help` | - | Show help message | - |

## Usage Examples

### Basic Usage
```bash
# Connect as subscriber1
dart run ./lib/main.dart -u subscriber1 -p sub123

# Connect as subscriber2  
dart run ./lib/main.dart -u subscriber2 -p sub456

# Connect as subscriber3
dart run ./lib/main.dart -u subscriber3 -p sub789
```

### Advanced Usage
```bash
# Connect to remote broker
dart run ./lib/main.dart -u subscriber1 -p sub123 -h 192.168.1.100 --port 1883

# Custom client ID
dart run ./lib/main.dart -u subscriber1 -p sub123 --client-id my-custom-client-id

# Show help
dart run ./lib/main.dart --help
```

## Message Output Format

The client displays received messages with different icons based on the topic:

```
📨 [PERSONAL] [2025-05-29T10:30:45.123Z] Topic: client/subscriber1 | Message: Personal message
📢 [BROADCAST] [2025-05-29T10:30:46.456Z] Topic: clients/all | Message: Broadcast message
```

### Message Types:
- **📨 [PERSONAL]** - Messages sent to `client/{your-username}`
- **📢 [BROADCAST]** - Messages sent to `clients/all`
- **📬 [MESSAGE]** - Other messages (if any)

## Graceful Shutdown

The client handles shutdown signals gracefully:

### Shutdown Process:
1. **Signal Detection** - Catches SIGINT (Ctrl+C) and SIGTERM
2. **Unsubscribe** - Cleanly unsubscribes from all topics
3. **Disconnect** - Properly disconnects from MQTT broker
4. **Exit** - Terminates the application

### Shutdown Example:
```
⚠️  Received SIGINT (Ctrl+C). Shutting down gracefully...
🛑 Starting graceful shutdown...
📤 Unsubscribing from all topics...
🔌 Disconnecting from MQTT broker...
👋 MQTT client disconnected gracefully
✅ Graceful shutdown completed
```

## Connection Events

The client logs various connection events:

```
🚀 Starting MQTT Subscriber Client
📡 Connecting to: localhost:1883
👤 Username: subscriber1
🆔 Client ID: dart-subscriber-1732901234567
🔌 Connecting to MQTT broker...
✅ Successfully connected to MQTT broker
📥 Subscribing to client-specific topic: client/subscriber1
📥 Subscribing to all-clients topic: clients/all
✅ Successfully subscribed to topic: client/subscriber1
✅ Successfully subscribed to topic: clients/all
✅ MQTT Subscriber is running. Press Ctrl+C to exit gracefully.
```

## Error Handling

### Common Errors and Solutions:

#### Authentication Failed
```
❌ Failed to connect to MQTT broker. Status: MqttConnectionState.faulted
```
**Solution**: Check username/password credentials

#### Connection Refused
```
❌ Exception during connection: SocketException: Connection refused
```
**Solution**: Ensure Mosquitto broker is running and accessible

#### Invalid Arguments
```
❌ Error: Option username is mandatory.
```
**Solution**: Provide required username and password parameters

## Integration Testing

### Complete Test Workflow:

1. **Start Mosquitto Broker**:
   ```bash
   cd mqtt-demo
   cd mqtt_mosquitto
   docker-compose up -d
   ```

2. **Start Spring Boot Publisher**:
   ```bash
   cd mqtt_publisher
   mvn spring-boot:run
   ```

3. **Start Dart Subscriber** (Terminal 1):
   ```bash
   cd mqtt_client
   dart run ./lib/main.dart -u subscriber1 -p sub123
   ```

4. **Start Another Dart Subscriber** (Terminal 2):
   ```bash
   dart run ./lib/main.dart -u subscriber2 -p sub456
   ```

5. **Test Broadcast Message**:
   ```bash
   curl -X POST http://localhost:8080/api/mqtt/publish/all \
     -H "Content-Type: application/json" \
     -d '{"message": "Test broadcast message"}'
   ```
   **Expected**: Both Dart clients should receive the message

6. **Test Personal Message**:
   ```bash
   curl -X POST http://localhost:8080/api/mqtt/publish/client/subscriber1 \
     -H "Content-Type: application/json" \
     -d '{"message": "Personal message for subscriber1"}'
   ```
   **Expected**: Only subscriber1 should receive the message

7. **Test Graceful Shutdown**:
   Press `Ctrl+C` in any Dart client terminal
   **Expected**: Clean disconnection with proper logging

## Building Executable

### Compile to Native Executable:
```bash
# Compile for current platform
dart compile exe ./lib/main.dart -o mqtt_client

# Run compiled executable
./mqtt_client -u subscriber1 -p sub123
```

### Platform-Specific Builds:
```bash
# For different platforms, compile on target platform
# Windows: mqtt_client.exe
# macOS/Linux: mqtt_client
```

## Development

### Project Structure:
```
mqtt-client/
├── lib/
│   └── main.dart           # Main application
├── pubspec.yaml            # Dependencies
├── analysis_options.yaml   # Dart linting rules
├── README.md               # This file
└── .gitignore              # Git ignore file
```

### Key Dependencies:
- **mqtt_client**: MQTT5 client library
- **args**: Command line argument parsing
- **logging**: Structured logging

## Production Considerations

### Security
- [ ] Use SSL/TLS connection (`mqtts://`)
- [ ] Store credentials securely (environment variables)
- [ ] Implement proper certificate validation

### Monitoring
- [ ] Add health check endpoint
- [ ] Implement metrics collection
- [ ] Log to structured format (JSON)

### Deployment
- [ ] Docker containerization
- [ ] Kubernetes deployment
- [ ] Process monitoring (systemd, supervisor)

## Troubleshooting

### Debug Mode
Enable verbose logging by modifying the logger level:
```dart
Logger.root.level = Level.ALL; // Shows all log levels
```

### Connection Issues
```bash
# Test MQTT connection manually
mosquitto_sub -h localhost -p 1883 -V 5 -u subscriber1 -p sub123 -t test
```

### Port Issues
Check if MQTT port is accessible:
```bash
telnet localhost 1883
```

### Memory Issues
For long-running clients, monitor memory usage:
```bash
# On macOS/Linux
ps aux | grep dart
```

## Next Steps

Your complete MQTT demo setup is now ready:
1. ✅ **Mosquitto Broker** (Complete)
2. ✅ **Spring Boot Publisher** (Complete)
3. ✅ **Dart Subscriber** (Complete)

The Dart client will receive messages published by your Spring Boot API and handle graceful shutdowns properly! 🎉