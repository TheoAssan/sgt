// mqtt.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' show SecurityContext;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_data.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AdafruitIOService {
  // Adafruit IO MQTT (TLS)
  final String server = 'io.adafruit.com';
  final int port = 8883;

  // Load credentials from .env
  final String username = dotenv.env['AIO_USERNAME'] ?? '';
  final String aioKey   = dotenv.env['AIO_KEY'] ?? '';

  // Default feed
  late final String defaultFeed =
      '${dotenv.env['AIO_USERNAME']}/feeds/ld2410c-feeds.light-state';

  late MqttServerClient _client;

  /// Optional UI notifier (SnackBar) passed from HomePage
  final void Function(String message)? showNotification;

  // StreamController for light state
  final StreamController<bool> _lightStateController = StreamController<bool>.broadcast();
  Stream<bool> get lightStateStream => _lightStateController.stream;

  // StreamController for raw light state messages
  final StreamController<String> _rawLightStateController = StreamController<String>.broadcast();
  Stream<String> get rawLightStateStream => _rawLightStateController.stream;

  AdafruitIOService({this.showNotification}) {
    final clientId = 'flutterClient_${DateTime.now().second}';
    _client = MqttServerClient.withPort(
        server, 'flutterClient${DateTime.now().second}', port)
      ..logging(on: false)
      ..keepAlivePeriod = 30
      ..secure = true
      ..securityContext = SecurityContext.defaultContext
      ..onConnected = _onConnected
      ..onDisconnected = _onDisconnected
      ..onSubscribed = _onSubscribed;
  }

  Future<bool> connect() async {
    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutterClient${DateTime.now().second}')
        .withWillQos(MqttQos.atMostOnce)
        .authenticateAs(username, aioKey)
        .startClean();

    _client.connectionMessage = connMess;

    try {
      await _client.connect();
    } catch (e) {
      _client.disconnect();
      showNotification?.call('❌ MQTT connect failed: $e');
      return false;
    }

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      // Optional: auto-subscribe so you can listen for device echoes
      _client.subscribe(defaultFeed, MqttQos.atLeastOnce);
      _client.updates?.listen((events) {
        final rec = events.first;
        final msg = rec.payload as MqttPublishMessage;
        final text = MqttPublishPayload.bytesToStringAsString(msg.payload.message);
        _rawLightStateController.add(text); // <-- broadcast raw message only, no notification

        // Broadcast light state (supports MANUAL, AUTO, or plain ON/OFF)
        final clean = text.trim().toUpperCase();
        if (clean == 'LIGHT ON(MANUAL)' || clean == 'LIGHT ON(AUTO)' || clean == 'ON') {
          _lightStateController.add(true);
        } else if (clean == 'LIGHT OFF(MANUAL)' || clean == 'LIGHT OFF(AUTO)' || clean == 'OFF') {
          _lightStateController.add(false);
        }
      });
      return true;
    } else {
      showNotification?.call('❌ MQTT connect status: ${_client.connectionStatus}');
      _client.disconnect();
      return false;
    }
  }

  /// Publish a text message to a topic (uses Uint8Buffer as required by mqtt_client).
  void publish(String topic, String message) {
    if (_client.connectionStatus?.state != MqttConnectionState.connected) {
      showNotification?.call('⚠️ Not connected to MQTT');
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addBuffer(Uint8Buffer()..addAll(utf8.encode(message)));
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  /// Fetch historical data from Adafruit IO REST API for the light-state feed
  Future<List<Map<String, dynamic>>> fetchLightStateHistory({int maxResults = 100}) async {
    final url = Uri.https(
      'io.adafruit.com',
      '/api/v2/$username/feeds/ld2410c-feeds.light-state/data',
      {'limit': maxResults.toString()},
    );
    final response = await http.get(
      url,
      headers: {'X-AIO-Key': aioKey},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, dynamic>>((item) => {
        'created_at': item['created_at'],
        'value': item['value'],
      }).toList();
    } else {
      throw Exception('Failed to fetch history: \\${response.statusCode}');
    }
  }

  void _onConnected() => showNotification?.call('🔗 MQTT Connected');
  void _onDisconnected() => showNotification?.call('🔌 MQTT Disconnected');
  void _onSubscribed(String topic) {/* No notification */}

  void dispose() {
    _lightStateController.close();
    _rawLightStateController.close();
    _client.disconnect();
  }

  void disconnect() {
    _client.disconnect();
  }
}
