package cool.cfapps.mqtt_publisher.controller;

import cool.cfapps.mqtt_publisher.dto.ApiResponse;
import cool.cfapps.mqtt_publisher.dto.MessageRequest;
import cool.cfapps.mqtt_publisher.services.MqttService;
import org.eclipse.paho.mqttv5.common.MqttException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;

import java.time.LocalDateTime;
import java.util.Set;

@Slf4j
@RestController
@RequestMapping("/api/mqtt")
@CrossOrigin(origins = "*") // Configure properly for production
public class MqttController {

    private final MqttService mqttService;

    @Autowired
    public MqttController(MqttService mqttService) {
        this.mqttService = mqttService;
    }

    /**
     * API endpoint to publish message for all clients in topic clients/all
     * POST /api/mqtt/publish/all
     */
    @PostMapping("/publish/all")
    public ResponseEntity<ApiResponse> publishToAllClients(@Valid @RequestBody MessageRequest request) {
        try {
            log.info("📤 Publishing message to all clients: {}", request.getMessage());
            mqttService.publishToAllClients(request.getMessage());

            ApiResponse response = ApiResponse.builder()
                    .success(true)
                    .message("Message published to all clients successfully")
                    .data("Topic: clients/all")
                    .timestamp(LocalDateTime.now())
                    .build();

            return ResponseEntity.ok(response);

        } catch (MqttException e) {
            log.error("❌ Failed to publish message to all clients: {}", e.getMessage());

            ApiResponse response = ApiResponse.builder()
                    .success(false)
                    .message("Failed to publish message to all clients")
                    .error(e.getMessage())
                    .timestamp(LocalDateTime.now())
                    .build();

            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    /**
     * API endpoint to publish message for a client in topic client/USER
     * POST /api/mqtt/publish/client/{user}
     */
    @PostMapping("/publish/client/{user}")
    public ResponseEntity<ApiResponse> publishToClient(
            @PathVariable String user,
            @Valid @RequestBody MessageRequest request) {
        try {
            log.info("📤 Publishing message to client '{}': {}", user, request.getMessage());
            mqttService.publishToClient(user, request.getMessage());

            ApiResponse response = ApiResponse.builder()
                    .success(true)
                    .message("Message published to client successfully")
                    .data("Topic: client/" + user + ", Client: " + user)
                    .timestamp(LocalDateTime.now())
                    .build();

            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {
            log.error("❌ Client '{}' does not exist: {}", user, e.getMessage());

            ApiResponse response = ApiResponse.builder()
                    .success(false)
                    .message("Client does not exist")
                    .error("Client '" + user + "' does not exist in topic 'client/" + user + "'")
                    .timestamp(LocalDateTime.now())
                    .build();

            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);

        } catch (MqttException e) {
            log.error("❌ Failed to publish message to client '{}': {}", user, e.getMessage());

            ApiResponse response = ApiResponse.builder()
                    .success(false)
                    .message("Failed to publish message to client")
                    .error(e.getMessage())
                    .timestamp(LocalDateTime.now())
                    .build();

            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    /**
     * API endpoint to subscribe to $SYS/# and dump to console log.info
     * POST /api/mqtt/subscribe/sys
     */
    @PostMapping("/subscribe/sys")
    public ResponseEntity<ApiResponse> subscribeToSystemTopics() {
        try {
            log.info("📥 Subscribing to system topics $SYS/#");
            mqttService.subscribeToSystemTopics();

            ApiResponse response = ApiResponse.builder()
                    .success(true)
                    .message("Successfully subscribed to system topics")
                    .data("Topic: $SYS/# - Check logs for system information")
                    .timestamp(LocalDateTime.now())
                    .build();

            return ResponseEntity.ok(response);

        } catch (MqttException e) {
            log.error("❌ Failed to subscribe to system topics: {}", e.getMessage());

            ApiResponse response = ApiResponse.builder()
                    .success(false)
                    .message("Failed to subscribe to system topics")
                    .error(e.getMessage())
                    .timestamp(LocalDateTime.now())
                    .build();

            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    /**
     * Get list of known clients
     * GET /api/mqtt/clients
     */
    @GetMapping("/clients")
    public ResponseEntity<ApiResponse> getKnownClients() {
        Set<String> clients = mqttService.getKnownClients();

        ApiResponse response = ApiResponse.builder()
                .success(true)
                .message("Known clients retrieved successfully")
                .data(clients)
                .timestamp(LocalDateTime.now())
                .build();

        return ResponseEntity.ok(response);
    }

    /**
     * Add a new client to known clients list
     * POST /api/mqtt/clients/{client}
     */
    @PostMapping("/clients/{client}")
    public ResponseEntity<ApiResponse> addKnownClient(@PathVariable String client) {
        mqttService.addKnownClient(client);

        ApiResponse response = ApiResponse.builder()
                .success(true)
                .message("Client added successfully")
                .data("Added client: " + client)
                .timestamp(LocalDateTime.now())
                .build();

        return ResponseEntity.ok(response);
    }

    /**
     * Health check endpoint
     * GET /api/mqtt/health
     */
    @GetMapping("/health")
    public ResponseEntity<ApiResponse> healthCheck() {
        ApiResponse response = ApiResponse.builder()
                .success(true)
                .message("MQTT Publisher Service is running")
                .data("Service Status: UP")
                .timestamp(LocalDateTime.now())
                .build();

        return ResponseEntity.ok(response);
    }
}
