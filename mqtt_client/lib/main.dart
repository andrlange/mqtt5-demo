import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:typed_data/typed_buffers.dart';

// Global variables for graceful shutdown
late MqttServerClient client;
bool isShuttingDown = false;
final Logger _logger = Logger('MqttSubscriber');

void main(List<String> arguments) async {
  // Setup logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(
      '${record.time} [${record.level.name}] ${record.loggerName}: ${record.message}',
    );
  });

  // Parse command line arguments
  final parser = ArgParser()
    ..addOption('username', abbr: 'u', help: 'MQTT username', mandatory: true)
    ..addOption('password', abbr: 'p', help: 'MQTT password', mandatory: true)
    ..addOption(
      'host',
      abbr: 'h',
      help: 'MQTT broker host',
      defaultsTo: 'localhost',
    )
    ..addOption('port', help: 'MQTT broker port', defaultsTo: '1883')
    ..addOption(
      'client-id',
      abbr: 'c',
      help: 'MQTT client ID',
      defaultsTo: 'dart-subscriber-${DateTime.now().millisecondsSinceEpoch}',
    )
    ..addFlag('help', negatable: false, help: 'Show this help message');

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      _showUsage(parser);
      return;
    }

    final username = results['username'] as String;
    final password = results['password'] as String;
    final host = results['host'] as String;
    final port = int.parse(results['port'] as String);
    final clientId = results['client-id'] as String;

    _logger.info('🚀 Starting MQTT Subscriber Client');
    _logger.info('📡 Connecting to: $host:$port');
    _logger.info('👤 Username: $username');
    _logger.info('🆔 Client ID: $clientId');

    // Setup signal handlers for graceful shutdown
    _setupSignalHandlers();

    // Connect to MQTT broker
    await _connectToMqtt(host, port, clientId, username, password);

    // Subscribe to topics
    await _subscribeToTopics(username);

    // Keep the program running
    _logger.info(
      '✅ MQTT Subscriber is running. Press Ctrl+C to exit gracefully.',
    );
    await _keepAlive();
  } catch (e) {
    _logger.severe('❌ Error: $e');
    _showUsage(parser);
    exit(1);
  }
}

void _showUsage(ArgParser parser) {
  print('Dart MQTT5 Subscriber Client');
  print('');
  print('Usage: dart run main.dart -u <username> -p <password> [options]');
  print('');
  print('Options:');
  print(parser.usage);
  print('');
  print('Examples:');
  print('  dart run main.dart -u subscriber1 -p sub123');
  print(
    '  dart run main.dart -u subscriber2 -p sub456 -h 192.168.1.100 --port 1883',
  );
  print(
    '  dart run main.dart --username subscriber3 --password sub789 --client-id my-client',
  );
}

Future<void> _connectToMqtt(
  String host,
  int port,
  String clientId,
  String username,
  String password,
) async {
  // Create MQTT client
  client = MqttServerClient(host, clientId, maxConnectionAttempts: 1);
  client.port = port;
  client.logging(on: false); // We handle our own logging
  client.keepAlivePeriod = 60;
  client.autoReconnect = true;
  client.resubscribeOnAutoReconnect = true;

  final will = utf8.encode('$username disconnected');
  Uint8Buffer willBuff = Uint8Buffer(will.length);
  int index = 0;
  will.map((ele) => willBuff[index++] = ele);
  // Setup connection message
  final connMessage = MqttConnectMessage()
      .withClientIdentifier(clientId)
      .withWillTopic('clients/status')
      .withWillPayload(willBuff)
      .startClean()
      .keepAliveFor(60)
      .authenticateAs(username, password);

  client.connectionMessage = connMessage;

  // Setup event handlers
  client.onConnected = _onConnected;
  client.onDisconnected = _onDisconnected;
  client.onUnsubscribed = _onUnsubscribed;
  client.onSubscribed = _onSubscribed;
  client.onSubscribeFail = _onSubscribeFail;
  client.onAutoReconnect = _onAutoReconnect;
  client.onAutoReconnected = _onAutoReconnected;

  try {
    _logger.info('🔌 Connecting to MQTT broker...');
    final status = await client.connect();

    if (status?.state == MqttConnectionState.connected) {
      _logger.info('✅ Successfully connected to MQTT broker');
    } else {
      _logger.severe(
        '❌ Failed to connect to MQTT broker. Status: ${status?.state}',
      );
      exit(1);
    }
  } catch (e) {
    _logger.severe('❌ Exception during connection: $e');
    exit(1);
  }
}

Future<void> _subscribeToTopics(String username) async {
  try {
    // Subscribe to client-specific topic
    final clientTopic = 'client/$username';
    _logger.info('📥 Subscribing to client-specific topic: $clientTopic');
    client.subscribe(clientTopic, MqttQos.exactlyOnce);

    // Subscribe to all-clients topic
    const allClientsTopic = 'clients/all';
    _logger.info('📥 Subscribing to all-clients topic: $allClientsTopic');
    client.subscribe(allClientsTopic, MqttQos.exactlyOnce);

    // Listen for incoming messages
    client.updates.listen(_onMessageReceived);

    _logger.info('✅ Successfully subscribed to topics');
  } catch (e) {
    _logger.severe('❌ Error subscribing to topics: $e');
    exit(1);
  }
}

void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> messages) {
  for (final message in messages) {
    final topic = message.topic ?? '';

    final recMess = message.payload as MqttPublishMessage;
    final msg = MqttUtilities.bytesToStringAsString(recMess.payload.message!);
    final timestamp = DateTime.now().toIso8601String();

    // Log message with different icons based on topic
    if (topic.startsWith('client/') && !topic.endsWith('/all')) {
      _logger.info(
        '📨 [PERSONAL] [$timestamp] Topic: $topic | Message: $msg',
      );
    } else if (topic == 'clients/all') {
      _logger.info(
        '📢 [BROADCAST] [$timestamp] Topic: $topic | Message: $msg',
      );
    } else {
      _logger.info(
        '📬 [MESSAGE] [$timestamp] Topic: $topic | Message: $msg',
      );
    }
  }
}

// Event handlers
void _onConnected() {
  _logger.info('🔗 MQTT client connected');
}

void _onDisconnected() {
  if (!isShuttingDown) {
    _logger.warning('🔌 MQTT client disconnected unexpectedly');
  } else {
    _logger.info('👋 MQTT client disconnected gracefully');
  }
}

void _onSubscribed(MqttSubscription subscription) {
  _logger.info(
    '✅ Successfully subscribed to topic: ${subscription.topic.rawTopic}',
  );
}

void _onSubscribeFail(MqttSubscription subscription) {
  _logger.severe(
    '❌ Failed to subscribe to topic: ${subscription.topic.rawTopic}',
  );
}

void _onUnsubscribed(MqttSubscription subscription) {
  _logger.info('📤 Unsubscribed from topic: ${subscription.topic.rawTopic}');
}

void _onAutoReconnect() {
  _logger.info('🔄 Auto-reconnecting to MQTT broker...');
}

void _onAutoReconnected() {
  _logger.info('🔄 Auto-reconnected to MQTT broker');
}

void _setupSignalHandlers() {
  // Handle Ctrl+C (SIGINT)
  ProcessSignal.sigint.watch().listen((_) async {
    _logger.info('⚠️  Received SIGINT (Ctrl+C). Shutting down gracefully...');
    await _gracefulShutdown();
  });

  // Handle SIGTERM (if supported)
  try {
    ProcessSignal.sigterm.watch().listen((_) async {
      _logger.info('⚠️  Received SIGTERM. Shutting down gracefully...');
      await _gracefulShutdown();
    });
  } catch (e) {
    // SIGTERM might not be supported on all platforms
    _logger.info('ℹ️  SIGTERM handling not supported on this platform');
  }
}

Future<void> _gracefulShutdown() async {
  if (isShuttingDown) return;

  isShuttingDown = true;

  try {
    _logger.info('🛑 Starting graceful shutdown...');

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      // Unsubscribe from all topics
      _logger.info('📤 Unsubscribing from all topics...');
      client.unsubscribeStringTopic('client/*');
      client.unsubscribeStringTopic('clients/all');

      // Wait a bit for unsubscribe to complete
      await Future.delayed(const Duration(milliseconds: 500),()=> null);

      // Disconnect from broker
      _logger.info('🔌 Disconnecting from MQTT broker...');
      client.disconnect();

      // Wait for disconnection
      await Future.delayed(const Duration(milliseconds: 1000),()=> null);
    }

    _logger.info('✅ Graceful shutdown completed');
  } catch (e) {
    _logger.severe('❌ Error during graceful shutdown: $e');
  } finally {
    exit(0);
  }
}

Future<void> _keepAlive() async {
  // Keep the program running until shutdown
  while (!isShuttingDown) {
    await Future.delayed(const Duration(milliseconds: 1000),()=> null);
  }
}
