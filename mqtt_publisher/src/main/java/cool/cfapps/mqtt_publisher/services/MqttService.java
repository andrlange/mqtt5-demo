package cool.cfapps.mqtt_publisher.services;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.eclipse.paho.mqttv5.client.IMqttToken;
import org.eclipse.paho.mqttv5.client.MqttCallback;
import org.eclipse.paho.mqttv5.client.MqttClient;
import org.eclipse.paho.mqttv5.client.MqttDisconnectResponse;
import org.eclipse.paho.mqttv5.common.MqttException;
import org.eclipse.paho.mqttv5.common.MqttMessage;
import org.eclipse.paho.mqttv5.common.packet.MqttProperties;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import lombok.extern.slf4j.Slf4j;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
public class MqttService implements MqttCallback {

    private final MqttClient mqttClient;
    private final ObjectMapper objectMapper;

    // Track known clients (in real app, this would be from database)
    private final Set<String> knownClients = ConcurrentHashMap.newKeySet();

    @Value("${mqtt.topics.all-clients}")
    private String allClientsTopic;

    @Value("${mqtt.topics.client-prefix}")
    private String clientTopicPrefix;

    @Value("${mqtt.topics.sys-topic}")
    private String sysTopic;

    public MqttService(MqttClient mqttClient, ObjectMapper objectMapper) {
        this.mqttClient = mqttClient;
        this.objectMapper = objectMapper;

        // Set callback for handling MQTT events
        mqttClient.setCallback(this);

        // Initialize with some demo clients
        knownClients.add("subscriber1");
        knownClients.add("subscriber2");
        knownClients.add("subscriber3");

        log.info("MQTT Service initialized with known clients: {}", knownClients);
    }

    /**
     * Publish message to all clients
     */
    public void publishToAllClients(String message) throws MqttException {
        log.info("Publishing message to all clients: {}", message);
        publishMessage(allClientsTopic, message, 1, false);
        log.info("✅ Message published to topic: {}", allClientsTopic);
    }

    /**
     * Publish message to specific client
     */
    public void publishToClient(String user, String message) throws MqttException {
        String topic = clientTopicPrefix + user;

        // Check if client exists (in real app, check database)
        if (!knownClients.contains(user)) {
            log.error("❌ Client '{}' does not exist in topic '{}'", user, topic);
            throw new IllegalArgumentException("Client '" + user + "' does not exist");
        }

        log.info("Publishing message to client '{}' on topic '{}': {}", user, topic, message);
        publishMessage(topic, message, 1, false);
        log.info("✅ Message published to client '{}' on topic: {}", user, topic);
    }

    /**
     * Subscribe to $SYS/# topics and log system information
     */
    public void subscribeToSystemTopics() throws MqttException {
        log.info("Subscribing to system topics: {}", sysTopic);

        mqttClient.subscribe(sysTopic, 0);
        log.info("✅ Successfully subscribed to system topics: {}", sysTopic);
    }

    /**
     * Add a new client to known clients list
     */
    public void addKnownClient(String client) {
        knownClients.add(client);
        log.info("Added new client: {}. Known clients: {}", client, knownClients);
    }

    /**
     * Get list of known clients
     */
    public Set<String> getKnownClients() {
        return Set.copyOf(knownClients);
    }

    /**
     * Generic method to publish MQTT message
     */
    private void publishMessage(String topic, String message, int qos, boolean retained) throws MqttException {
        if (!mqttClient.isConnected()) {
            log.error("❌ MQTT client is not connected");
            throw new MqttException(MqttException.REASON_CODE_CLIENT_EXCEPTION);
        }

        MqttMessage mqttMessage = new MqttMessage(message.getBytes());
        mqttMessage.setQos(qos);
        mqttMessage.setRetained(retained);

        try {
            mqttClient.publish(topic, mqttMessage);
            log.debug("Message published successfully to topic: {}", topic);
        } catch (MqttException e) {
            log.error("❌ Failed to publish message to topic '{}': {}", topic, e.getMessage());
            throw e;
        }
    }

    // MqttCallback implementation
    @Override
    public void disconnected(MqttDisconnectResponse disconnectResponse) {
        log.warn("🔌 MQTT client disconnected: {}", disconnectResponse.getReasonString());
    }

    @Override
    public void mqttErrorOccurred(MqttException exception) {
        log.error("❌ MQTT error occurred: {}", exception.getMessage());
    }

    @Override
    public void messageArrived(String topic, MqttMessage message) throws Exception {
        String payload = new String(message.getPayload());

        // Log $SYS messages with info level
        if (topic.startsWith("$SYS/")) {
            log.info("📊 System Info [{}]: {}", topic, payload);
        } else {
            log.debug("📨 Message received [{}]: {}", topic, payload);
        }
    }

    @Override
    public void deliveryComplete(IMqttToken token) {
        try {
            String[] topics = token.getTopics();
            if (topics != null && topics.length > 0) {
                log.debug("✅ Message delivery completed for topics: {}", String.join(", ", topics));
            }
        } catch (Exception e) {
            log.debug("✅ Message delivery completed (topic info unavailable)");
        }
    }

    @Override
    public void connectComplete(boolean reconnect, String serverURI) {
        if (reconnect) {
            log.info("🔄 Reconnected to MQTT broker: {}", serverURI);
        } else {
            log.info("🔗 Connected to MQTT broker: {}", serverURI);
        }
    }

    @Override
    public void authPacketArrived(int reasonCode, MqttProperties properties) {
        log.debug("🔐 Auth packet arrived with reason code: {}", reasonCode);
    }
}
