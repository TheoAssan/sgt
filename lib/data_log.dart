import 'package:flutter/material.dart';

class DataLogPage extends StatelessWidget {
  // Example data log entries. Replace with real data from your backend or Adafruit IO.
  final List<Map<String, String>> logs = [
    {
      'time': '2025-08-08 10:15',
      'event': 'Motion Detected',
      'detail': 'G6'
    },
    {
      'time': '2025-08-08 10:10',
      'event': 'Light Turned ON',
      'detail': 'Manual'
    },
    {
      'time': '2025-08-08 09:55',
      'event': 'Light Turned OFF',
      'detail': 'Auto (No Motion)'
    },
    {
      'time': '2025-08-08 09:30',
      'event': 'Motion Detected,Light ON',
      'detail': 'G6'
    },
    // Add more entries as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Log', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF001F54),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final log = logs[index];
          return ListTile(
            leading: Icon(
              log['event']!.contains('Motion')
                  ? Icons.directions_run
                  : Icons.lightbulb,
              color: log['event']!.contains('OFF')
                  ? Colors.grey
                  : Colors.amber,
            ),
            title: Text(log['event'] ?? ''),
            subtitle: Text('${log['detail']}'),
            trailing: Text(
              log['time'] ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          );
        },
      ),
    );
  }
}