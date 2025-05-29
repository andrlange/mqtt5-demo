# Spring Boot 3.5 MQTT5 Publisher

A Spring Boot application that connects to Mosquitto MQTT broker as a producer with REST API endpoints to publish messages.

## Features

✅ **MQTT5 Connection** - Connects to Mosquitto using MQTT v5.0 protocol  
✅ **Publish to All Clients** - API endpoint for `clients/all` topic  
✅ **Publish to Specific Client** - API endpoint for `client/{USER}` topic  
✅ **System Topic Subscription** - Subscribe to `$SYS/#` with console logging  
✅ **Client Validation** - Logs error if client doesn't exist  
✅ **Automatic Reconnection** - Handles connection failures gracefully  
✅ **Health Monitoring** - Health check endpoints and metrics

## Project Structure

```
src/main/java/cool/cfapps/mqtt_broker/
├── MqttBrokerApplication.java             # Main application class
├── config/
│   └── MqttConfig.java                    # MQTT5 client configuration
├── controller/
│   └── MqttController.java                # REST API endpoints
├── services/
│   └── MqttService.java                   # MQTT operations service
└── dto/
    ├── MessageRequest.java                # Request DTO
    └── ApiResponse.java                   # Response DTO
```

## Prerequisites

1. **Java 21** or higher
2. **Maven 3.6+**
3. **Mosquitto MQTT Broker** running with authentication
4. **Docker** (for Mosquitto setup)

## Quick Start

### 1. Setup Mosquitto Broker
Follow the Mosquitto setup instructions to have your broker running with these credentials:
- **Publisher**: `publisher` / `publisher123`
- **Subscribers**: `subscriber1`, `subscriber2`, `subscriber3`

### 2. Clone & Build
```bash
# Create project directory
mkdir mqtt_publisher
cd mqtt_publisher

# Create the Maven project structure and copy all Java files
# Copy pom.xml and application.yml from the artifacts
```


### 3. Run Application
```bash
# Build and run
mvn clean install
mvn spring-boot:run

# Or run the JAR
mvn clean package
java -jar target/mqtt-broker-1.0.0.jar
```

### 4. Test API Endpoints
```bash
# Health check
curl http://localhost:8080/api/mqtt/health

# Publish to all clients
curl -X POST http://localhost:8080/api/mqtt/publish/all \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello World!"}'
```

## Configuration

### MQTT Settings (application.yml)
```yaml
mqtt:
  broker:
    url: tcp://localhost:1883          # Mosquitto broker URL
    client-id: spring-boot-publisher   # Unique client ID
    username: publisher                # MQTT username
    password: publisher123             # MQTT password
    auto-reconnect: true               # Auto reconnect on failure
    clean-start: true                  # Clean session on connect
```

### Known Clients Management
The application maintains a list of known clients. By default, it includes:
- `subscriber1`
- `subscriber2`
- `subscriber3`

Add new clients via API: `POST /api/mqtt/clients/{client}`

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/mqtt/publish/all` | Publish to `clients/all` topic |
| `POST` | `/api/mqtt/publish/client/{user}` | Publish to `client/{user}` topic |
| `POST` | `/api/mqtt/subscribe/sys` | Subscribe to `$SYS/#` system topics |
| `GET` | `/api/mqtt/clients` | Get list of known clients |
| `POST` | `/api/mqtt/clients/{client}` | Add new client to known list |
| `GET` | `/api/mqtt/health` | Service health check |

## Testing

### 1. Test with Mosquitto Clients
```bash
# Subscribe to messages (Terminal 1)
mosquitto_sub -h localhost -p 1883 -V 5 -u subscriber1 -P sub123 -t clients/all

# Subscribe to client-specific messages (Terminal 2)  
mosquitto_sub -h localhost -p 1883 -V 5 -u subscriber1 -P sub123 -t client/subscriber1

# Publish via API (Terminal 3)
curl -X POST http://localhost:8080/api/mqtt/publish/all \
  -H "Content-Type: application/json" \
  -d '{"message": "API Test Message"}'
```

### 2. Test System Topics
```bash
# Subscribe to system topics
curl -X POST http://localhost:8080/api/mqtt/subscribe/sys

# Check application logs for system information:
# 📊 System Info [$SYS/broker/version]: mosquitto version 2.0.21
# 📊 System Info [$SYS/broker/clients/connected]: 3
```

### 3. Test Error Handling
```bash
# Try to publish to unknown client (should return 404)
curl -X POST http://localhost:8080/api/mqtt/publish/client/unknown \
  -H "Content-Type: application/json" \
  -d '{"message": "This will fail"}'

# Response: {"success": false, "error": "Client 'unknown' does not exist"}
```

## Logging

The application provides detailed logging:

```
2025-05-29 10:30:45 - ✅ Successfully connected to MQTT broker
2025-05-29 10:30:46 - 📤 Publishing message to all clients: Hello World!
2025-05-29 10:30:47 - 📊 System Info [$SYS/broker/uptime]: 1234 seconds
2025-05-29 10:30:48 - ❌ Client 'unknown' does not exist in topic 'client/unknown'
```

## Monitoring

### Health Check
```bash
curl http://localhost:8080/actuator/health
```

### Metrics
```bash  
curl http://localhost:8080/actuator/metrics
```

## Production Considerations

### Security
- [ ] Use SSL/TLS for MQTT connection (`mqtts://`)
- [ ] Implement proper authentication/authorization
- [ ] Secure REST API endpoints
- [ ] Use environment variables for sensitive config

### Database Integration
- [ ] Replace in-memory client list with database
- [ ] Store message history
- [ ] User management system

### Monitoring & Observability
- [ ] Add Micrometer metrics
- [ ] Implement distributed tracing
- [ ] Add custom health indicators
- [ ] Log aggregation (ELK stack)

### High Availability
- [ ] Multiple MQTT broker instances
- [ ] Connection pooling
- [ ] Circuit breaker pattern
- [ ] Graceful shutdown handling

## Troubleshooting

### Connection Issues
```bash
# Check if Mosquitto is running
docker-compose ps

# Test MQTT connection manually
mosquitto_pub -h localhost -p 1883 -V 5 -u publisher -P publisher123 -t test -m "test"
```

### Authentication Errors
- Verify credentials in `application.yml`
- Check Mosquitto password file
- Ensure publisher user has write permissions

### Port Conflicts
- Default Spring Boot port: `8080`
- Default MQTT port: `1883`
- Change ports in configuration if needed

## Next Steps

Once this Spring Boot MQTT publisher is working:
1. ✅ **Mosquitto Broker** (Complete)
2. ✅ **Spring Boot Publisher** (Complete)
3. 🚀 **Dart MQTT Subscriber** (Next: Create Dart client to receive messages)

The Spring Boot application is now ready to publish MQTT5 messages to your Mosquitto broker! 🎉