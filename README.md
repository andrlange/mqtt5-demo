# Complete MQTT5 Demo Setup

A comprehensive MQTT5 demonstration featuring **Mosquitto Broker**, **Spring Boot Publisher**, and **Dart Subscriber** with authentication, topic management, and graceful shutdown handling.

## 🏗️ Architecture Overview

```
┌─────────────────┐    REST API    ┌──────────────────┐    MQTT5     ┌─────────────────┐
│      User       │──────────────→ │  Spring Boot     │─────────────→│   Mosquitto     │
│   (curl/API)    │                │  Publisher       │              │   Broker        │
└─────────────────┘                └──────────────────┘              └─────────────────┘
                                                                               │
                                                                               │ MQTT5
                                                                               ▼
                                                                      ┌─────────────────┐
                                                                      │   Dart MQTT     │
                                                                      │   Subscribers   │
                                                                      └─────────────────┘
```

## 📦 Components

| Component | Technology                | Port | Purpose |
|-----------|---------------------------|------|---------|
| **MQTT Broker** | Mosquitto 2.0.21 (Docker) | 1883 | Message routing with authentication |
| **Publisher** | Spring Boot 3.5 + Java 21 | 8080 | REST API to MQTT5 publisher |
| **Subscriber** | Dart 3.8                  | - | Message receiver with graceful shutdown |

## 🚀 Quick Start (5 Minutes)

### Prerequisites
- **Docker Desktop** installed and running
- **Java 21+** and **Maven 3.6+**
- **Dart SDK 3.8+**

### 1. Start Mosquitto Broker
```bash
# Clone  this project

cd mqtt-demo

# Copy mosquitto files (docker-compose.yaml, config files)
# From the artifacts: docker-compose.yaml, mosquitto.conf, acl

cd mqtt_mosquitto
# Setup and start broker
chmod +x setup.sh
./setup.sh
docker-compose up -d

# Verify broker is running
docker-compose ps
```

### 2. Start Spring Boot Publisher
```bash
cd ../mqtt_publisher

# Build and run
mvn clean install
mvn spring-boot:run

# Verify API is running
curl http://localhost:8080/api/mqtt/health
```

### 3. Start Dart Subscriber
```bash
cd ../mqtt_client

# Install dependencies and run
dart pub get
dart run ./lib/main.dart -u subscriber1 -p sub123
```

### 4. Test Message Flow
```bash
# Send broadcast message (all subscribers receive)
curl -X POST http://localhost:8080/api/mqtt/publish/all \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello everyone!"}'

# Send personal message (only subscriber1 receives)
curl -X POST http://localhost:8080/api/mqtt/publish/client/subscriber1 \
  -H "Content-Type: application/json" \
  -d '{"message": "Personal message"}'
```

## 🔐 Authentication & Users

The system uses file-based authentication with 4 predefined users:

### Publisher (Spring Boot uses this)
- **Username**: `publisher`
- **Password**: `publisher123`
- **Permissions**: Can publish to any topic

### Subscribers (Dart clients use these)
- **subscriber1** / `sub123` - Can only subscribe
- **subscriber2** / `sub456` - Can only subscribe
- **subscriber3** / `sub789` - Can only subscribe

### Add New Users (Hot Reload - No Downtime)
```bash
# Add new subscriber
./add_user.sh newuser mypass123 subscriber

# Add new publisher
./add_user.sh newpub pubpass456 publisher

# Configuration reloads automatically
```

## 📡 MQTT Topics Structure

| Topic Pattern | Purpose | Publisher | Subscribers |
|---------------|---------|-----------|-------------|
| `clients/all` | Broadcast messages | Spring Boot API | All Dart clients |
| `client/{username}` | Personal messages | Spring Boot API | Specific Dart client |
| `$SYS/#` | System information | Broker | Spring Boot (logs to console) |
| `clients/status` | Connection status | Clients (will messages) | Monitoring |

## 🔌 API Endpoints (Spring Boot)

### Publish Messages
```bash
# Broadcast to all clients
POST /api/mqtt/publish/all
curl -X POST http://localhost:8080/api/mqtt/publish/all \
  -H "Content-Type: application/json" \
  -d '{"message": "Broadcast message", "qos": 1}'

# Send to specific client
POST /api/mqtt/publish/client/{user}
curl -X POST http://localhost:8080/api/mqtt/publish/client/subscriber1 \
  -H "Content-Type: application/json" \
  -d '{"message": "Personal message"}'

# Subscribe to system topics (logs to Spring Boot console)
POST /api/mqtt/subscribe/sys
curl -X POST http://localhost:8080/api/mqtt/subscribe/sys
```

### Management
```bash
# Health check
GET /api/mqtt/health

# List known clients
GET /api/mqtt/clients

# Add new client to known list
POST /api/mqtt/clients/{client}
```

## 💻 Dart Subscriber Usage

### Basic Usage
```bash
# Connect with different subscribers
dart run ./lib/main.dart -u subscriber1 -p sub123
dart run ./lib/main.dart -u subscriber2 -p sub456 -h localhost --port 1883
dart run ./lib/main.dart --username subscriber3 --password sub789
```

### Message Output Format
```
📨 [PERSONAL] [2025-05-29T10:30:45.123Z] Topic: client/subscriber1 | Message: Personal message
📢 [BROADCAST] [2025-05-29T10:30:46.456Z] Topic: clients/all | Message: Broadcast message
```

### Graceful Shutdown
Press **Ctrl+C** in any Dart subscriber:
```
⚠️  Received SIGINT (Ctrl+C). Shutting down gracefully...
🛑 Starting graceful shutdown...
📤 Unsubscribing from all topics...
🔌 Disconnecting from MQTT broker...
✅ Graceful shutdown completed
```

## 🧪 Complete Test Workflow

### 1. Start All Services
```bash
# Terminal 1: Mosquitto
cd mqtt-demo
cd mqtt_mosquitto
./setup.sh # if not already done
docker-compose up -d

# Terminal 2: Spring Boot  
cd mqtt-demo
cd mqtt_publisher
mvn spring-boot:run

# Terminal 3: Dart Subscriber 1
cd mqtt-demo
cd mqtt_client
dart run ./lib/main.dart -u subscriber1 -p sub123

# Terminal 4: Dart Subscriber 2
cd mqtt-demo
cd mqtt_client
dart run ./lib/main.dart -u subscriber2 -p sub456
```

### 2. Test Message Broadcasting
```bash
# Terminal 5: Send messages
# Broadcast (both subscribers receive)
curl -X POST http://localhost:8080/api/mqtt/publish/all \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello everyone!"}'

# Personal message (only subscriber1 receives)
curl -X POST http://localhost:8080/api/mqtt/publish/client/subscriber1 \
  -H "Content-Type: application/json" \
  -d '{"message": "Personal for subscriber1"}'

# Unknown client (should return 404 error)
curl -X POST http://localhost:8080/api/mqtt/publish/client/unknown \
  -H "Content-Type: application/json" \
  -d '{"message": "This will fail"}'
```

### 3. Test System Monitoring
```bash
# Subscribe to system topics in Spring Boot
curl -X POST http://localhost:8080/api/mqtt/subscribe/sys

# Check Spring Boot logs for system information:
# 📊 System Info [$SYS/broker/version]: mosquitto version 2.0.21
# 📊 System Info [$SYS/broker/clients/connected]: 3
```

### 4. Test Graceful Shutdown
Press **Ctrl+C** in any Dart subscriber terminal and observe clean disconnection.

## 🔧 Configuration

### Mosquitto (docker-compose.yaml)
```yaml
services:
  mosquitto:
    image: eclipse-mosquitto:2.0.21
    ports:
      - "1883:1883"    # MQTT
      - "8883:8883"    # SSL (future)
      - "9001:9001"    # WebSocket
```

### Spring Boot (application.yml)
```yaml
mqtt:
  broker:
    url: tcp://localhost:1883
    username: publisher
    password: publisher123
```

### Dart Subscriber (Command Line)
```bash
dart run ./lib/main.dart \
  --username subscriber1 \
  --password sub123 \
  --host localhost \
  --port 1883 \
  --client-id dart-subscriber-1
```

## 🚨 Error Handling & Validation

### Client Validation
```bash
# Unknown client returns 404
curl -X POST http://localhost:8080/api/mqtt/publish/client/unknown \
  -H "Content-Type: application/json" \
  -d '{"message": "This fails"}'

# Response:
{
  "success": false,
  "message": "Client does not exist", 
  "error": "Client 'unknown' does not exist in topic 'client/unknown'"
}
```

### Connection Issues
- **MQTT Connection Failed**: Check if Mosquitto is running and credentials are correct
- **API Not Responding**: Verify Spring Boot is running on port 8080
- **Permission Denied**: Check user permissions in ACL file

## 📊 Monitoring & Logs

### Mosquitto Logs
```bash
docker-compose logs -f mosquitto
```

### Spring Boot Logs
```
✅ Successfully connected to MQTT broker
📤 Publishing message to all clients: Hello World!
📊 System Info [$SYS/broker/uptime]: 1234 seconds
❌ Client 'unknown' does not exist in topic 'client/unknown'
```

### Dart Client Logs
```
🚀 Starting MQTT Subscriber Client
✅ Successfully connected to MQTT broker
📨 [PERSONAL] [timestamp] Topic: client/subscriber1 | Message: Personal message
📢 [BROADCAST] [timestamp] Topic: clients/all | Message: Broadcast message
```

## 🔮 Advanced Features

### SSL/TLS Support (Future)
```bash
# Generate self-signed certificates
openssl req -new -x509 -days 365 -extensions v3_ca -keyout ca.key -out ca.crt
# Update mosquitto.conf SSL section
# Restart broker with SSL enabled
```

### Database Integration
- Replace in-memory client list with PostgreSQL/MySQL
- Store message history and analytics
- User management with proper authentication

### Scalability
- Multiple Mosquitto broker instances
- Load balancing with HAProxy
- Message persistence and clustering

## 🛠️ Development Setup

### Project Structure
```
mqtt-demo/
├── mosquitto/
│   ├── docker-compose.yaml
│   ├── vols/mosquitto/config/
│   └── setup scripts
├── spring-boot-mqtt-publisher/
│   ├── src/main/java/
│   ├── pom.xml
│   └── application.yml
└── dart-mqtt-subscriber/
    ├── main.dart
    ├── pubspec.yaml
    └── helper scripts
```

### Contributing
1. Fork the repository
2. Create feature branch
3. Add tests for new functionality
4. Ensure all components work together
5. Submit pull request

## 🐛 Troubleshooting

### Common Issues

**Docker Connection Refused**
```bash
# Solution: Start Docker Desktop and check container status
docker ps
docker-compose up -d
```

**MQTT Authentication Failed**
```bash
# Solution: Verify credentials and recreate password file
./add_user.sh publisher publisher123 publisher
docker-compose restart mosquitto
```

**Spring Boot Can't Connect**
```bash
# Solution: Check application.yml credentials and broker status
curl http://localhost:8080/actuator/health
```

**Dart Compilation Errors**
```bash
# Solution: Check Dart version and dependencies
dart --version
dart pub get
dart analyze
```

## 📚 Further Reading

- [MQTT 5.0 Specification](https://docs.oasis-open.org/mqtt/mqtt/v5.0/mqtt-v5.0.html)
- [Eclipse Mosquitto Documentation](https://mosquitto.org/documentation/)
- [Spring Boot MQTT Integration](https://spring.io/guides/gs/messaging-rabbitmq/)
- [Dart MQTT Client Package](https://pub.dev/packages/mqtt_client)

## 🎉 Success Criteria

When everything is working correctly, you should see:

1. ✅ **Mosquitto broker** running with authentication
2. ✅ **Spring Boot API** responding to health checks
3. ✅ **Dart subscribers** connected and receiving messages
4. ✅ **Message flow** working: API → Broker → Subscribers
5. ✅ **Error handling** for unknown clients
6. ✅ **Graceful shutdown** when pressing Ctrl+C
7. ✅ **System monitoring** via $SYS/# topics

**Your complete MQTT5 demo environment is ready!** 🚀

---

*Built with ❤️ using Eclipse Mosquitto, Spring Boot 3.4, and Dart 3.8*