import 'package:flutter/material.dart';
import '../services/database_service.dart';

// Enum to define the severity of an alert
enum AlertSeverity { critical, warning, info }

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;
  AlertSeverity? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _loading = true);
    final alerts = await _databaseService.getAlertHistory(limit: 50);
    setState(() {
      _alerts = alerts;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  AlertSeverity _parseSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return AlertSeverity.critical;
      case 'warning':
        return AlertSeverity.warning;
      default:
        return AlertSeverity.info;
    }
  }

  IconData _getIconForSeverity(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.error_outline;
      case AlertSeverity.warning:
        return Icons.warning_amber_outlined;
      case AlertSeverity.info:
        return Icons.info_outline;
    }
  }

  Color _getColorForSeverity(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red[700]!;
      case AlertSeverity.warning:
        return Colors.orange[700]!;
      case AlertSeverity.info:
        return Colors.blue[700]!;
    }
  }

  String _formatTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAlerts = _alerts.where((alert) {
      if (_selectedFilter == null) return true;
      return _parseSeverity(alert['severity'] as String?) == _selectedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Alerts & Notifications',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear all alerts',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear All Alerts'),
                  content:
                  const Text('Are you sure you want to delete all alerts?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Clear All',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _databaseService.clearAllAlerts();
                _loadAlerts();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildFilterBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredAlerts.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: _loadAlerts,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = filteredAlerts[index];
                    final alertId = alert['id'] as int?;
                    return Dismissible(
                      key: Key('alert_${alertId ?? index}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete,
                            color: Colors.white),
                      ),
                      onDismissed: (direction) async {
                        if (alertId != null) {
                          await _databaseService.deleteAlert(alertId);
                          setState(() {
                            _alerts.removeWhere(
                                    (a) => a['id'] == alertId);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Alert deleted'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: _buildAlertCard(alert),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFilterChip('All', null),
          _buildFilterChip('Critical', AlertSeverity.critical),
          _buildFilterChip('Warning', AlertSeverity.warning),
          _buildFilterChip('Info', AlertSeverity.info),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, AlertSeverity? severity) {
    final isSelected = _selectedFilter == severity;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = severity;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.green[100],
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.green[800] : Colors.black54,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.green[700]! : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severity = _parseSeverity(alert['severity'] as String?);
    final sensorType = alert['sensor_type'] as String? ?? 'System';
    final message = alert['message'] as String? ?? 'No details';
    final timestamp = alert['timestamp'] as int? ?? 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getColorForSeverity(severity).withOpacity(0.8),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForSeverity(severity),
                  color: _getColorForSeverity(severity),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sensorType,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatTime(timestamp),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                message,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_active_outlined,
              size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Alerts Yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Alerts will appear when sensor values go out of range',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}