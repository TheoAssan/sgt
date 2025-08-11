import 'package:flutter/material.dart';

class PowerConsumptionPage extends StatelessWidget {
  const PowerConsumptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Example static data, replace with real data as needed
    final List<Map<String, String>> powerData = [
      {'period': 'Today', 'consumption': '0.8 kWh'},
      {'period': 'This Week', 'consumption': '5.2 kWh'},
      {'period': 'This Month', 'consumption': '22.4 kWh'},
      {'period': 'Total', 'consumption': '120 kWh'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Power Consumption', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF001F54),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: powerData.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final entry = powerData[index];
          return ListTile(
            leading: Icon(Icons.bolt, color: Colors.amber),
            title: Text(entry['period'] ?? ''),
            trailing: Text(
              entry['consumption'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          );
        },
      ),
    );
  }
}