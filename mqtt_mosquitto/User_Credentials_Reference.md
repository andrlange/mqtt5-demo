# MQTT User Credentials Reference

## Publisher User (Can Publish & Subscribe)
```
Username: publisher
Password: publisher123
Permissions: Can publish to any topic (#)
```

## Subscriber Users (Can Only Subscribe)

### Subscriber 1
```
Username: subscriber1
Password: sub123
Permissions: Can subscribe to any topic (#)
```

### Subscriber 2
```
Username: subscriber2
Password: sub456
Permissions: Can subscribe to any topic (#)
```

### Subscriber 3
```
Username: subscriber3
Password: sub789
Permissions: Can subscribe to any topic (#)
```

## Quick Test Commands

### Publish Message (as publisher)
```bash
mosquitto_pub -h localhost -p 1883 -V 5 -u publisher -P publisher123 -t demo/topic -m "Hello World"
```

### Subscribe to Messages (as any subscriber)
```bash
# As subscriber1
mosquitto_sub -h localhost -p 1883 -V 5 -u subscriber1 -P sub123 -t demo/topic

# As subscriber2  
mosquitto_sub -h localhost -p 1883 -V 5 -u subscriber2 -P sub456 -t demo/topic

# As subscriber3
mosquitto_sub -h localhost -p 1883 -V 5 -u subscriber3 -P sub789 -t demo/topic
```

### Test Permission Denied (subscriber trying to publish - should fail)
```bash
mosquitto_pub -h localhost -p 1883 -V 5 -u subscriber1 -P sub123 -t demo/topic -m "This will fail"
```

## For Spring Boot Application
Use the **publisher** credentials in your Spring Boot configuration:
```properties
mqtt.username=publisher
mqtt.password=publisher123
```

## For Dart Client
Use any of the **subscriber** credentials in your Dart MQTT client:
```dart
// Example for subscriber1
final username = 'subscriber1';
final password = 'sub123';
```