import 'package:flutter/material.dart';

enum SensorStatus { normal, warning, critical }

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final SensorStatus status;
  final String lastUpdated;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.status,
    required this.lastUpdated,
  });

  Color _statusColor() {
    switch (status) {
      case SensorStatus.normal:
        return Colors.green;
      case SensorStatus.warning:
        return Colors.orange;
      case SensorStatus.critical:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Icon(Icons.circle, color: _statusColor(), size: 14),
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Last: $lastUpdated',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class SensorDetailTile extends StatelessWidget {
  final String title;
  final String value;
  final String lastUpdated;
  final SensorStatus status;
  const SensorDetailTile(
      {super.key,
      required this.title,
      required this.value,
      required this.lastUpdated,
      required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case SensorStatus.normal:
        color = Colors.green;
        break;
      case SensorStatus.warning:
        color = Colors.orange;
        break;
      case SensorStatus.critical:
        color = Colors.red;
        break;
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(Icons.sensors, color: color)),
        title: Text(title),
        subtitle: Text('Value: $value • Updated: $lastUpdated'),
        trailing:
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
      ),
    );
  }
}
