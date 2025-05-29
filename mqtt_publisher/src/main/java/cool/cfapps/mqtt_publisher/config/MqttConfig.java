package cool.cfapps.mqtt_publisher.config;

import org.eclipse.paho.mqttv5.client.MqttClient;
import org.eclipse.paho.mqttv5.client.MqttConnectionOptions;
import org.eclipse.paho.mqttv5.client.persist.MemoryPersistence;
import org.eclipse.paho.mqttv5.common.MqttException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Configuration
public class MqttConfig {

    @Value("${mqtt.broker.url}")
    private String brokerUrl;

    @Value("${mqtt.broker.client-id}")
    private String clientId;

    @Value("${mqtt.broker.username}")
    private String username;

    @Value("${mqtt.broker.password}")
    private String password;

    @Value("${mqtt.broker.auto-reconnect:true}")
    private boolean autoReconnect;

    @Value("${mqtt.broker.clean-start:true}")
    private boolean cleanStart;

    @Value("${mqtt.broker.session-expiry-interval:3600}")
    private long sessionExpiryInterval;

    @Value("${mqtt.broker.keep-alive-interval:60}")
    private int keepAliveInterval;

    @Value("${mqtt.broker.connection-timeout:10}")
    private int connectionTimeout;

    private MqttClient mqttClient;

    @Bean
    @Primary
    public MqttClient mqttClient() throws MqttException {
        log.info("Initializing MQTT5 Client...");
        log.info("Broker URL: {}", brokerUrl);
        log.info("Client ID: {}", clientId);
        log.info("Username: {}", username);

        // Create MQTT5 client with memory persistence
        MemoryPersistence persistence = new MemoryPersistence();
        mqttClient = new MqttClient(brokerUrl, clientId, persistence);

        // Configure connection options for MQTT5
        MqttConnectionOptions options = new MqttConnectionOptions();
        options.setUserName(username);
        options.setPassword(password.getBytes());
        options.setAutomaticReconnect(autoReconnect);
        options.setCleanStart(cleanStart);
        options.setSessionExpiryInterval(sessionExpiryInterval);
        options.setKeepAliveInterval(keepAliveInterval);
        options.setConnectionTimeout(connectionTimeout);

        // Connect to broker
        try {
            log.info("Connecting to MQTT broker...");
            mqttClient.connect(options);
            log.info("✅ Successfully connected to MQTT broker");
        } catch (MqttException e) {
            log.error("❌ Failed to connect to MQTT broker: {}", e.getMessage());
            throw e;
        }

        return mqttClient;
    }

    @PreDestroy
    public void disconnect() {
        if (mqttClient != null && mqttClient.isConnected()) {
            try {
                log.info("Disconnecting from MQTT broker...");
                mqttClient.disconnect();
                mqttClient.close();
                log.info("✅ Successfully disconnected from MQTT broker");
            } catch (MqttException e) {
                log.error("❌ Error disconnecting from MQTT broker: {}", e.getMessage());
            }
        }
    }
}
