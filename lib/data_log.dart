import 'package:flutter/material.dart';
import 'mqtt.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class DataLogPage extends StatefulWidget {
  const DataLogPage({super.key});

  @override
  State<DataLogPage> createState() => _DataLogPageState();
}

class _DataLogPageState extends State<DataLogPage> {
  final Map<String, List<Map<String, String>>> logsByDay = {};
  String? selectedDay;
  late AdafruitIOService mqttService;
  StreamSubscription<bool>? _lightStateSub;
  StreamSubscription<String>? _rawMqttSub;
  String hourFilter = 'all'; // 'all', '6', '12', '24'

  @override
  void initState() {
    super.initState();
    mqttService = AdafruitIOService();
    _fetchHistory();
    // Listen to raw MQTT messages for logging
    _rawMqttSub = mqttService.rawLightStateStream.listen((msg) {
      _addLogFromMqtt(msg);
    });
    // Optionally, connect if not already connected
    mqttService.connect();
  }

  Future<void> _fetchHistory() async {
    try {
      final history = await mqttService.fetchLightStateHistory(maxResults: 100);
      for (final item in history) {
        _addLogFromHistory(item['value'], item['created_at']);
      }
      if (logsByDay.isNotEmpty && selectedDay == null) {
        setState(() {
          selectedDay = logsByDay.keys.first;
        });
      }
    } catch (e) {
      // Optionally handle error
    }
  }

  void _addLogFromHistory(String msg, String createdAt) {
    final dt = DateTime.tryParse(createdAt)?.toLocal();
    if (dt == null) return;
    final dayKey = DateFormat('yyyy-MM-dd').format(dt);
    String? event;
    String? detail;
    final clean = msg.trim().toUpperCase();
    if (clean.contains('LIGHT ON')) {
      event = 'Light Turned ON';
      if (clean.contains('MANUAL')) {
        detail = 'Manual';
      } else if (clean.contains('AUTO')) {
        detail = 'Auto';
      } else {
        detail = 'Unknown';
      }
    } else if (clean.contains('LIGHT OFF')) {
      event = 'Light Turned OFF';
      if (clean.contains('MANUAL')) {
        detail = 'Manual';
      } else if (clean.contains('AUTO')) {
        detail = 'Auto';
      } else {
        detail = 'Unknown';
      }
    } else {
      // Not a light ON/OFF event, ignore
      return;
    }
    final log = {
      'time': DateFormat('HH:mm').format(dt),
      'event': event,
      'detail': detail,
    };
    setState(() {
      logsByDay.putIfAbsent(dayKey, () => []);
      logsByDay[dayKey]!.add(log); // Add to end for history
    });
  }

  void _addLogFromMqtt(String msg) {
    final now = DateTime.now();
    final dayKey = DateFormat('yyyy-MM-dd').format(now);
    String? event;
    String? detail;
    final clean = msg.trim().toUpperCase();
    if (clean.contains('LIGHT ON')) {
      event = 'Light Turned ON';
      if (clean.contains('MANUAL')) {
        detail = 'Manual';
      } else if (clean.contains('AUTO')) {
        detail = 'Auto';
      } else {
        detail = 'Unknown';
      }
    } else if (clean.contains('LIGHT OFF')) {
      event = 'Light Turned OFF';
      if (clean.contains('MANUAL')) {
        detail = 'Manual';
      } else if (clean.contains('AUTO')) {
        detail = 'Auto';
      } else {
        detail = 'Unknown';
      }
    } else {
      // Not a light ON/OFF event, ignore
      return;
    }
    final log = {
      'time': DateFormat('HH:mm').format(now),
      'event': event,
      'detail': detail,
    };
    setState(() {
      logsByDay.putIfAbsent(dayKey, () => []);
      logsByDay[dayKey]!.insert(0, log); // Most recent first
      selectedDay ??= dayKey;
    });
  }

  String _friendlyDayLabel(String dayKey) {
    final today = DateTime.now();
    final date = DateTime.tryParse(dayKey);
    if (date == null) return dayKey;
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  List<Map<String, String>> _filterLogsByHour(List<Map<String, String>> logs, String dayKey) {
    if (hourFilter == 'all') return logs;
    final now = DateTime.now();
    final date = DateTime.tryParse(dayKey);
    if (date == null) return logs;
    final cutoff = now.subtract(Duration(hours: int.parse(hourFilter)));
    return logs.where((log) {
      final logTime = DateFormat('yyyy-MM-dd HH:mm').parse('$dayKey ${log['time']}');
      return logTime.isAfter(cutoff);
    }).toList();
  }

  @override
  void dispose() {
    _lightStateSub?.cancel();
    _rawMqttSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = logsByDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Log', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF001F54),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              setState(() {
                hourFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: '6', child: Text('Last 6 hours')),
              const PopupMenuItem(value: '12', child: Text('Last 12 hours')),
              const PopupMenuItem(value: '24', child: Text('Last 24 hours')),
            ],
          ),
        ],
      ),
      body: days.isEmpty
          ? const Center(child: Text('No logs available.'))
          : ListView.builder(
              padding: const EdgeInsets.all(0),
              itemCount: days.length,
              itemBuilder: (context, dayIdx) {
                final dayKey = days[dayIdx];
                final friendlyLabel = _friendlyDayLabel(dayKey);
                final logs = _filterLogsByHour(logsByDay[dayKey]!, dayKey);
                if (logs.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        friendlyLabel,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F54)),
                      ),
                    ),
                    ...List.generate(logs.length, (index) {
                      final log = logs[index];
                      return ListTile(
                        leading: Icon(
                          log['event']!.contains('ON')
                              ? Icons.lightbulb
                              : Icons.lightbulb_outline,
                          color: log['event']!.contains('OFF')
                              ? Colors.grey
                              : Colors.amber,
                        ),
                        title: Text(log['event'] ?? ''),
                        subtitle: Text('Mode: ${log['detail']}'),
                        trailing: Text(
                          log['time'] ?? '',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}