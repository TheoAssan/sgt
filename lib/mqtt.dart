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

  // StreamController for motion data messages
  final StreamController<String> _motionDataController = StreamController<String>.broadcast();
  Stream<String> get motionDataStream => _motionDataController.stream;

  // StreamController for override feed messages
  final StreamController<String> _overrideController = StreamController<String>.broadcast();
  Stream<String> get overrideStream => _overrideController.stream;

  // StreamController for power data messages
  final StreamController<String> _powerDataController = StreamController<String>.broadcast();
  Stream<String> get powerDataStream => _powerDataController.stream;

  // StreamController for energy data messages
  final StreamController<String> _energyDataController = StreamController<String>.broadcast();
  Stream<String> get energyDataStream => _energyDataController.stream;

  // Store energy consumption data for calculations
  final List<Map<String, dynamic>> _energyHistory = [];

  // Bulb wattage (set as 6 W, change as needed)
  final double bulbWattage = 6.0;

  AdafruitIOService({this.showNotification}) {
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
      // Subscribe to feeds
      _client.subscribe(defaultFeed, MqttQos.atLeastOnce);
      final motionDataFeed = '${dotenv.env['AIO_USERNAME']}/feeds/ld2410c-feeds.data-log';
      _client.subscribe(motionDataFeed, MqttQos.atLeastOnce);
      final overrideFeed = '${dotenv.env['AIO_USERNAME']}/feeds/ld2410c-feeds.override';
      _client.subscribe(overrideFeed, MqttQos.atLeastOnce);
      final powerFeed = '${dotenv.env['AIO_USERNAME']}/feeds/ld2410c-feeds.power';
      _client.subscribe(powerFeed, MqttQos.atLeastOnce);
      final energyFeed = '${dotenv.env['AIO_USERNAME']}/feeds/ld2410c-feeds.power';
      _client.subscribe(energyFeed, MqttQos.atLeastOnce);

      _client.updates?.listen((events) {
        final rec = events.first;
        final msg = rec.payload as MqttPublishMessage;
        final text = MqttPublishPayload.bytesToStringAsString(msg.payload.message);
        final topic = rec.topic;

        if (topic == defaultFeed) {
          _rawLightStateController.add(text);
          final clean = text.trim().toUpperCase();
          if (clean == 'LIGHT ON(MANUAL)' || clean == 'LIGHT ON(AUTO)' || clean == 'ON') {
            _lightStateController.add(true);
          } else if (clean == 'LIGHT OFF(MANUAL)' || clean == 'LIGHT OFF(AUTO)' || clean == 'OFF') {
            _lightStateController.add(false);
          }
        } else if (topic == motionDataFeed) {
          _motionDataController.add(text);
        } else if (topic == overrideFeed) {
          _overrideController.add(text);
        } else if (topic == powerFeed) {
          _powerDataController.add(text);
        } else if (topic == energyFeed) {
          // Convert NodeMCU energy values to kWh using bulb wattage and elapsed time
          final adjustedEnergy = _calculateEnergyFromWatts(double.tryParse(text) ?? 0.0);
          _energyDataController.add(adjustedEnergy.toStringAsFixed(6));
          _storeEnergyData(adjustedEnergy.toString(), DateTime.now());
        }
      });
      return true;
    } else {
      showNotification?.call('❌ MQTT connect status: ${_client.connectionStatus}');
      _client.disconnect();
      return false;
    }
  }

  /// Convert raw watt value to kWh based on bulb wattage and elapsed time
  double _calculateEnergyFromWatts(double nodeMCUValue) {
    // NodeMCU value represents instantaneous watts (W)
    // kWh = W × hours / 1000
    // For small time steps, assume ~1 second interval: hours = 1 / 3600
    double hours = 1 / 3600;
    return bulbWattage * hours; // 6W × 1 sec ≈ 0.001666 kWh
  }

  void _storeEnergyData(String energyValue, DateTime timestamp) {
    try {
      final value = double.tryParse(energyValue) ?? 0.0;
      _energyHistory.add({
        'timestamp': timestamp,
        'value': value,
        'created_at': timestamp.toIso8601String(),
      });
      if (_energyHistory.length > 1000) _energyHistory.removeAt(0);
    } catch (e) {
      showNotification?.call('❌ Error storing energy data: $e');
    }
  }

  void publish(String topic, String message) {
    if (_client.connectionStatus?.state != MqttConnectionState.connected) {
      showNotification?.call('⚠️ Not connected to MQTT');
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addBuffer(Uint8Buffer()..addAll(utf8.encode(message)));
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  Future<List<Map<String, dynamic>>> fetchLightStateHistory({int maxResults = 100}) async {
    final url = Uri.https('io.adafruit.com', '/api/v2/$username/feeds/ld2410c-feeds.light-state/data', {'limit': maxResults.toString()});
    final response = await http.get(url, headers: {'X-AIO-Key': aioKey});
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, dynamic>>((item) => {
        'created_at': item['created_at'],
        'value': item['value'],
      }).toList();
    } else throw Exception('Failed to fetch history: ${response.statusCode}');
  }

  // --- other fetch*History methods unchanged ---
  Future<List<Map<String, dynamic>>> fetchMotionDataHistory({int maxResults = 100}) async {
    final url = Uri.https('io.adafruit.com', '/api/v2/$username/feeds/ld2410c-feeds.data-log/data', {'limit': maxResults.toString()});
    final response = await http.get(url, headers: {'X-AIO-Key': aioKey});
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, dynamic>>((item) => {
        'created_at': item['created_at'],
        'value': item['value'],
      }).toList();
    } else throw Exception('Failed to fetch motion data history: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> fetchOverrideHistory({int maxResults = 100}) async {
    final url = Uri.https('io.adafruit.com', '/api/v2/$username/feeds/ld2410c-feeds.override/data', {'limit': maxResults.toString()});
    final response = await http.get(url, headers: {'X-AIO-Key': aioKey});
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, dynamic>>((item) => {
        'created_at': item['created_at'],
        'value': item['value'],
      }).toList();
    } else throw Exception('Failed to fetch override history: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> fetchPowerHistory({int maxResults = 100}) async {
    final url = Uri.https('io.adafruit.com', '/api/v2/$username/feeds/ld2410c-feeds.power/data', {'limit': maxResults.toString()});
    final response = await http.get(url, headers: {'X-AIO-Key': aioKey});
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, dynamic>>((item) => {
        'created_at': item['created_at'],
        'value': item['value'],
      }).toList();
    } else throw Exception('Failed to fetch power history: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> fetchEnergyHistory({int maxResults = 100}) async {
    final url = Uri.https('io.adafruit.com', '/api/v2/$username/feeds/ld2410c-feeds.power/data', {'limit': maxResults.toString()});
    final response = await http.get(url, headers: {'X-AIO-Key': aioKey});
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, dynamic>>((item) => {
        'created_at': item['created_at'],
        'value': item['value'],
      }).toList();
    } else throw Exception('Failed to fetch energy history: ${response.statusCode}');
  }

  Future<Map<String, double>> calculatePowerStats() async {
    try {
      final energyHistory = await fetchEnergyHistory(maxResults: 1000);
      final allEnergyData = [..._energyHistory, ...energyHistory.map((item) => {
        'timestamp': DateTime.parse(item['created_at']),
        'value': double.tryParse(item['value'].toString()) ?? 0.0,
        'created_at': item['created_at'],
      })];

      if (allEnergyData.isEmpty) {
        return {'today': 0.0, 'thisWeek': 0.0, 'thisMonth': 0.0, 'total': 0.0};
      }

      allEnergyData.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      double todayConsumption = 0.0;
      double weekConsumption = 0.0;
      double monthConsumption = 0.0;
      double totalConsumption = 0.0;

      for (int i = 0; i < allEnergyData.length; i++) {
        final currentEntry = allEnergyData[i];
        final currentValue = currentEntry['value'] as double;
        final currentTime = currentEntry['timestamp'] as DateTime;

        if (i == allEnergyData.length - 1) totalConsumption = currentValue;

        if (currentTime.isAfter(todayStart)) todayConsumption = currentValue - _getBaselineValue(allEnergyData, todayStart);
        if (currentTime.isAfter(weekStart)) weekConsumption = currentValue - _getBaselineValue(allEnergyData, weekStart);
        if (currentTime.isAfter(monthStart)) monthConsumption = currentValue - _getBaselineValue(allEnergyData, monthStart);
      }

      return {'today': todayConsumption, 'thisWeek': weekConsumption, 'thisMonth': monthConsumption, 'total': totalConsumption};
    } catch (e) {
      showNotification?.call('❌ Failed to fetch power stats: $e');
      return {'today': 0.0, 'thisWeek': 0.0, 'thisMonth': 0.0, 'total': 0.0};
    }
  }

  double _getBaselineValue(List<Map<String, dynamic>> energyData, DateTime periodStart) {
    for (int i = energyData.length - 1; i >= 0; i--) {
      final entry = energyData[i];
      final entryTime = entry['timestamp'] as DateTime;
      if (entryTime.isBefore(periodStart)) return entry['value'] as double;
    }
    return 0.0;
  }

  void _onConnected() => showNotification?.call('🔗 MQTT Connected');
  void _onDisconnected() => showNotification?.call('🔌 MQTT Disconnected');
  void _onSubscribed(String topic) {}

  void dispose() {
    _lightStateController.close();
    _rawLightStateController.close();
    _motionDataController.close();
    _overrideController.close();
    _powerDataController.close();
    _energyDataController.close();
    _client.disconnect();
  }

  void disconnect() {
    _client.disconnect();
  }
}
