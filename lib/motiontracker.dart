import 'package:flutter/material.dart';
import 'mqtt.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'dart:convert'; // Added for json.decode

class MotionTrackerPage extends StatefulWidget {
  const MotionTrackerPage({super.key});

  @override
  State<MotionTrackerPage> createState() => _MotionTrackerPageState();
}

class _MotionTrackerPageState extends State<MotionTrackerPage> {
  final Map<String, List<Map<String, dynamic>>> motionLogsByDay = {};
  String? selectedDay;
  late AdafruitIOService mqttService;
  StreamSubscription<String>? _motionDataSub;

  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    mqttService = AdafruitIOService();
    _setupMotionDataListener();
    _connectToMqtt();
  }

  Future<void> _connectToMqtt() async {
    try {
      bool connected = await mqttService.connect();
      setState(() {
        isConnected = connected;
      });
    } catch (e) {
      setState(() {
        isConnected = false;
      });
    }
  }

  void _setupMotionDataListener() {
    // Subscribe to the motion data feed
    _motionDataSub = mqttService.motionDataStream.listen((msg) {
      _processMotionData(msg);
    });
  }

  Future<void> _fetchMotionHistory() async {
    try {
      final history = await mqttService.fetchMotionDataHistory(maxResults: 100);
      for (final item in history) {
        _addMotionLogFromHistory(item['value'], item['created_at']);
      }
      if (motionLogsByDay.isNotEmpty && selectedDay == null) {
        setState(() {
          selectedDay = motionLogsByDay.keys.first;
        });
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  void _processMotionData(String data) {
    // Parse motion data from the LD2410C sensor
    // Expected format might be JSON or specific format from the sensor
    try {
      // Try to parse as JSON first
      final jsonData = json.decode(data);
      _addMotionLogFromMqtt(jsonData);
    } catch (e) {
      // If not JSON, treat as raw string data
      _addMotionLogFromMqtt({'raw_data': data});
    }
  }

  void _addMotionLogFromHistory(String data, String createdAt) {
    final dt = DateTime.tryParse(createdAt)?.toLocal();
    if (dt == null) return;
    
    final dayKey = DateFormat('yyyy-MM-dd').format(dt);
    final motionData = _parseMotionData(data);
    
    final log = {
      'time': DateFormat('HH:mm').format(dt),
      'event': motionData['event'],
      'distance': motionData['distance'],
      'energy': motionData['energy'],
    };
    
    setState(() {
      motionLogsByDay.putIfAbsent(dayKey, () => []);
      motionLogsByDay[dayKey]!.add(log);
    });
  }

  void _addMotionLogFromMqtt(dynamic data) {
    final now = DateTime.now();
    final dayKey = DateFormat('yyyy-MM-dd').format(now);
    final motionData = _parseMotionData(data);
    
    final log = {
      'time': DateFormat('HH:mm').format(now),
      'event': motionData['event'],
      'distance': motionData['distance'],
      'energy': motionData['energy'],
    };
    
    setState(() {
      motionLogsByDay.putIfAbsent(dayKey, () => []);
      motionLogsByDay[dayKey]!.insert(0, log); // Most recent first
      selectedDay ??= dayKey;
    });
  }

  Map<String, dynamic> _parseMotionData(dynamic data) {
    // Parse motion data from LD2410C sensor
    if (data is Map) {
      // JSON format - handle structured data
      if (data.containsKey('raw_data')) {
        // Handle raw data that was wrapped in a map
        return _parseMotionData(data['raw_data']);
      }
      
      return {
        'event': _getTargetType(data),
        'distance': data['distance']?.toString() ?? data['range']?.toString() ?? 'N/A',
        'energy': data['energy']?.toString() ?? data['signal']?.toString() ?? 'N/A',
      };
    } else if (data is String) {
      // String format - parse based on expected LD2410C format
      final clean = data.trim().toUpperCase();
      
      // Handle target types from LD2410C sensor
      if (clean.contains('STATIONARY') || clean.contains('STATIC')) {
        return {
          'event': 'Stationary Target',
          'distance': _extractDistance(data),
          'energy': _extractEnergy(data),
        };
      } else if (clean.contains('MOVING') || clean.contains('MOTION')) {
        return {
          'event': 'Moving Target',
          'distance': _extractDistance(data),
          'energy': _extractEnergy(data),
        };
      } else if (clean.contains('NO TARGET') || clean.contains('CLEAR')) {
        return {
          'event': 'No Target',
          'distance': 'N/A',
          'energy': 'N/A',
        };
      } else {
        // Try to extract numeric values for distance/energy
        final numbers = RegExp(r'\d+').allMatches(data);
        if (numbers.isNotEmpty) {
          return {
            'event': 'Target Detected',
            'distance': numbers.isNotEmpty ? '${numbers.first.group(0)}cm' : 'N/A',
            'energy': numbers.length > 1 ? '${numbers.elementAt(1).group(0)}' : 'N/A',
          };
        }
        
        return {
          'event': 'Target Detected',
          'distance': 'Unknown',
          'energy': 'Unknown',
        };
      }
    }
    
    return {
      'event': 'Unknown Event',
      'distance': 'N/A',
      'energy': 'N/A',
    };
  }

  String _getTargetType(Map<dynamic, dynamic> data) {
    // Determine target type from sensor data
    if (data['stationary'] == true || data['static'] == true) {
      return 'Stationary Target';
    } else if (data['moving'] == true || data['motion'] == true) {
      return 'Moving Target';
    } else if (data['no_target'] == true || data['clear'] == true) {
      return 'No Target';
    } else {
      return 'Target Detected';
    }
  }

  String _extractDistance(String data) {
    // Extract distance from string data
    final distanceMatch = RegExp(r'(\d+)\s*(?:cm|m|meters?)', caseSensitive: false).firstMatch(data);
    if (distanceMatch != null) {
      return '${distanceMatch.group(1)}cm';
    }
    
    // Fallback to any number that might be distance
    final numbers = RegExp(r'\d+').allMatches(data);
    if (numbers.isNotEmpty) {
      return '${numbers.first.group(0)}cm';
    }
    
    return 'N/A';
  }

  String _extractEnergy(String data) {
    // Extract energy from string data
    final energyMatch = RegExp(r'energy[:\s]*(\d+)', caseSensitive: false).firstMatch(data);
    if (energyMatch != null) {
      return energyMatch.group(1)!;
    }
    
    // Fallback to second number if available
    final numbers = RegExp(r'\d+').allMatches(data);
    if (numbers.length > 1) {
      return numbers.elementAt(1).group(0)!;
    }
    
    return 'N/A';
  }

  String _friendlyDayLabel(String dayKey) {
    final today = DateTime.now();
    final date = DateTime.tryParse(dayKey);
    if (date == null) return dayKey;
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('MMM dd, yyyy').format(date);
  }





  @override
  void dispose() {
    _motionDataSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = motionLogsByDay.keys.toList()..sort((a, b) => b.compareTo(a));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motion Tracker', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF001F54),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Connection status indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: days.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.motion_photos_on,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No target data available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Target data will appear here when detected',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(0),
              itemCount: days.length,
              itemBuilder: (context, dayIdx) {
                final dayKey = days[dayIdx];
                final friendlyLabel = _friendlyDayLabel(dayKey);
                final logs = motionLogsByDay[dayKey]!;
                if (logs.isEmpty) return const SizedBox.shrink();
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        friendlyLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF001F54),
                        ),
                      ),
                    ),
                                         ...List.generate(logs.length, (index) {
                       final log = logs[index];
                       final isTargetDetected = log['event'] == 'Moving Target' || log['event'] == 'Stationary Target' || log['event'] == 'Target Detected';
                       
                       return Card(
                         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                         elevation: 2,
                         child: ListTile(
                           leading: Container(
                             width: 48,
                             height: 48,
                             decoration: BoxDecoration(
                               color: isTargetDetected ? Colors.blue[100] : Colors.grey[100],
                               borderRadius: BorderRadius.circular(24),
                             ),
                             child: Icon(
                               isTargetDetected ? Icons.radar : Icons.radar_outlined,
                               color: isTargetDetected ? Colors.blue : Colors.grey,
                               size: 24,
                             ),
                           ),
                           title: Text(
                             log['event'] ?? 'Unknown Event',
                             style: TextStyle(
                               fontWeight: FontWeight.w600,
                               color: isTargetDetected ? Colors.blue[700] : Colors.grey[700],
                             ),
                           ),
                           subtitle: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               if (log['distance'] != 'N/A') Text('Distance: ${log['distance']}'),
                               if (log['energy'] != 'N/A') Text('Energy: ${log['energy']}'),
                             ],
                           ),
                           trailing: Text(
                             log['time'] ?? '',
                             style: const TextStyle(
                               fontSize: 16,
                               fontWeight: FontWeight.w500,
                               color: Colors.black87,
                             ),
                           ),
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
