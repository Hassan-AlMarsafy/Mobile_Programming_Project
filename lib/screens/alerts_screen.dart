import 'package:flutter/material.dart';

// A model for our placeholder alerts
class Alert {
  final String title;
  final String description;
  final String time;
  final AlertSeverity severity;
  bool isAcknowledged;

  Alert({
    required this.title,
    required this.description,
    required this.time,
    required this.severity,
    this.isAcknowledged = false,
  });
}

// Enum to define the severity of an alert
enum AlertSeverity { critical, warning, info }

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // --- Placeholder Data ---
  final List<Alert> _alerts = [
    Alert(
      title: 'Critical: pH Level Too Low',
      description: 'The pH level has dropped to 5.2, which is outside the optimal range.',
      time: '2 mins ago',
      severity: AlertSeverity.critical,
    ),
    Alert(
      title: 'Warning: Water Temperature High',
      description: 'Water temperature is currently at 28.5°C. Consider cooling measures.',
      time: '15 mins ago',
      severity: AlertSeverity.warning,
      isAcknowledged: true,
    ),
    Alert(
      title: 'Nutrient Solution Mixed',
      description: 'The nutrient pump successfully completed its scheduled cycle.',
      time: '1 hour ago',
      severity: AlertSeverity.info,
      isAcknowledged: true,
    ),
    Alert(
      title: 'Warning: Humidity Fluctuation',
      description: 'Humidity dropped by 15% in the last hour.',
      time: '3 hours ago',
      severity: AlertSeverity.warning,
    ),
  ];

  // State for filtering
  AlertSeverity? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --- Helper Methods ---
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

  @override
  Widget build(BuildContext context) {
    final filteredAlerts = _alerts.where((alert) {
      return _selectedFilter == null || alert.severity == _selectedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Alerts & Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildFilterBar(), // Filter UI
            Expanded(
              child: filteredAlerts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filteredAlerts.length,
                itemBuilder: (context, index) {
                  final alert = filteredAlerts[index];
                  return _buildAlertCard(alert);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New Widget: Filtering Bar
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

  // New Widget: Alert Card
  Widget _buildAlertCard(Alert alert) {
    final cardColor = alert.isAcknowledged ? Colors.white : Colors.green[50];
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getColorForSeverity(alert.severity).withOpacity(0.8),
          width: 1.5,
        ),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForSeverity(alert.severity),
                  color: _getColorForSeverity(alert.severity),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alert.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  alert.time,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                alert.description,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ),
            if (!alert.isAcknowledged) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        alert.isAcknowledged = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Alert "${alert.title}" acknowledged.'),
                          backgroundColor: Colors.green[700],
                        ),
                      );
                    },
                    child: Text(
                      'Acknowledge',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // New Widget: Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_active_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Alerts Here',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no alerts matching your filter.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
