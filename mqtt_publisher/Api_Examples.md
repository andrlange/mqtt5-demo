# Spring Boot MQTT5 Publisher API Examples

## Prerequisites
1. Mosquitto broker running on `localhost:1883`
2. Publisher user credentials: `publisher` / `publisher123`
3. Spring Boot application running on `localhost:8080`

## API Endpoints

### 1. Publish Message to All Clients
**POST** `/api/mqtt/publish/all`

Publishes a message to the `clients/all` topic for all subscribers.

```bash
curl -X POST http://localhost:8080/api/mqtt/publish/all \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello to all clients!",
    "qos": 1,
    "retained": false
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Message published to all clients successfully",
  "data": "Topic: clients/all",
  "timestamp": "2025-05-29T10:30:45.123"
}
```

### 2. Publish Message to Specific Client
**POST** `/api/mqtt/publish/client/{user}`

Publishes a message to the `client/{user}` topic for a specific user.

```bash
# Publish to known client (user1)
curl -X POST http://localhost:8080/api/mqtt/publish/client/subsciber1 \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Personal message for subsciber1",
    "qos": 1,
    "retained": false
  }'
```

**Success Response:**
```json
{
  "success": true,
  "message": "Message published to client successfully",
  "data": "Topic: client/subsciber1, Client: subsciber1",
  "timestamp": "2025-05-29T10:30:45.123"
}
```

**Error Response (Unknown Client):**
```bash
# Try to publish to unknown client
curl -X POST http://localhost:8080/api/mqtt/publish/client/unknown \
  -H "Content-Type: application/json" \
  -d '{
    "message": "This will fail"
  }'
```

```json
{
  "success": false,
  "message": "Client does not exist",
  "error": "Client 'unknown' does not exist in topic 'client/unknown'",
  "timestamp": "2025-05-29T10:30:45.123"
}
```

### 3. Subscribe to System Topics ($SYS/#)
**POST** `/api/mqtt/subscribe/sys`

Subscribes to `$SYS/#` topics and logs system information to console.

```bash
curl -X POST http://localhost:8080/api/mqtt/subscribe/sys \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "success": true,
  "message": "Successfully subscribed to system topics",
  "data": "Topic: $SYS/# - Check logs for system information",
  "timestamp": "2025-05-29T10:30:45.123"
}
```

**Log Output Example:**
```
2025-05-29 10:30:45 - 📊 System Info [$SYS/broker/version]: mosquitto version 2.0.21
2025-05-29 10:30:45 - 📊 System Info [$SYS/broker/uptime]: 1234 seconds
2025-05-29 10:30:45 - 📊 System Info [$SYS/broker/clients/connected]: 3
```

### 4. Get Known Clients
**GET** `/api/mqtt/clients`

Returns list of known clients.

```bash
curl -X GET http://localhost:8080/api/mqtt/clients
```

**Response:**
```json
{
  "success": true,
  "message": "Known clients retrieved successfully",
  "data": ["subsciber1", "subsciber2", "subsciber3"],
  "timestamp": "2025-05-29T10:30:45.123"
}
```

### 5. Add New Client
**POST** `/api/mqtt/clients/{client}`

Adds a new client to the known clients list.

```bash
curl -X POST http://localhost:8080/api/mqtt/clients/newuser \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "success": true,
  "message": "Client added successfully",
  "data": "Added client: newuser",
  "timestamp": "2025-05-29T10:30:45.123"
}
```

### 6. Health Check
**GET** `/api/mqtt/health`

Checks if the service is running.

```bash
curl -X GET http://localhost:8080/api/mqtt/health
```

**Response:**
```json
{
  "success": true,
  "message": "MQTT Publisher Service is running",
  "data": "Service Status: UP",
  "timestamp": "2025-05-29T10:30:45.123"
}
```

## Testing Workflow

### 1. Start Services
```bash
# Start Mosquitto broker
cd mqtt-demo
docker-compose up -d

# Start Spring Boot application
cd spring-boot-mqtt-publisher
mvn spring-boot:run
```

### 2. Subscribe to Test Messages (using mosquitto_sub)
```bash
# Terminal 1: Subscribe to all clients
mosquitto_sub -h localhost -p 1883 -V 5 -u subscriber1 -P sub123 -t clients/all

# Terminal 2: Subscribe to specific client
mosquitto_sub -h localhost -p 1883 -V 5 -u subscriber2 -P sub456 -t client/subscriber2

# Terminal 3: Subscribe to system topics (as publisher to see all)
mosquitto_sub -h localhost -p 1883 -V 5 -u publisher -P publisher123 -t '$SYS/#'
```

### 3. Test API Endpoints
```bash
# Test 1: Publish to all
curl -X POST http://localhost:8080/api/mqtt/publish/all \
  -H "Content-Type: application/json" \
  -d '{"message": "Broadcast message"}'

# Test 2: Publish to specific client
curl -X POST http://localhost:8080/api/mqtt/publish/client/subscriber1 \
  -H "Content-Type: application/json" \
  -d '{"message": "Private message"}'

# Test 3: Subscribe to system topics
curl -X POST http://localhost:8080/api/mqtt/subscribe/sys

# Test 4: Try unknown client (should fail)
curl -X POST http://localhost:8080/api/mqtt/publish/client/nonexistent \
  -H "Content-Type: application/json" \
  -d '{"message": "This should fail"}'
```

### 4. Monitor Logs
Check Spring Boot application logs to see:
- MQTT connection status
- Published messages
- System topic information
- Error messages for unknown clients

## Error Handling

### Validation Errors
```bash
# Empty message (should fail)
curl -X POST http://localhost:8080/api/mqtt/publish/all \
  -H "Content-Type: application/json" \
  -d '{"message": ""}'
```

### MQTT Connection Issues
- Check if Mosquitto broker is running
- Verify credentials in `application.yml`
- Check network connectivity

### Known Client Management
- Use `/api/mqtt/clients/{client}` to add new clients
- Check `/api/mqtt/clients` to see current list
- Real implementation should use database for client management