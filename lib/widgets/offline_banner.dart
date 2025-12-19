import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final DateTime? lastSyncTime;

  const OfflineBanner({super.key, this.lastSyncTime});

  String _formatLastSync() {
    if (lastSyncTime == null) return 'Never synced';

    final now = DateTime.now();
    final difference = now.difference(lastSyncTime!);

    if (difference.inMinutes < 1) {
      return 'Last synced: Just now';
    } else if (difference.inMinutes < 60) {
      return 'Last synced: ${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return 'Last synced: ${difference.inHours} hours ago';
    } else {
      return 'Last synced: ${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade700, Colors.orange.shade600],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            'Offline Mode - ${_formatLastSync()}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
