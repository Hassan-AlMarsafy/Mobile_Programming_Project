import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/notification_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  NotificationPreferences _preferences =
      NotificationPreferences.defaultPreferences();
  List<NotificationHistoryItem> _history = [];
  bool _isLoading = true;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadHistory();
  }

  Future<void> _loadPreferences() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs =
          await _firestoreService.getNotificationPreferences(user.uid);
      setState(() {
        _preferences = prefs ?? NotificationPreferences.defaultPreferences();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadHistory() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final history = await _firestoreService.getNotificationHistory(user.uid);
      setState(() {
        _history = history;
        _isLoadingHistory = false;
      });
    } else {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _savePreferences() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final updatedPrefs = _preferences.copyWith(
      lastUpdated: DateTime.now(),
    );

    await _firestoreService.saveNotificationPreferences(
        user.uid, updatedPrefs);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification settings saved'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Container(
                    color: Theme.of(context).cardColor,
                    child: TabBar(
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor:
                          Theme.of(context).textTheme.bodyMedium?.color,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      tabs: const [
                        Tab(text: 'Categories'),
                        Tab(text: 'Settings'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCategoriesTab(),
                        _buildSettingsTab(),
                        _buildHistoryTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoriesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Alert Categories',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose which types of alerts you want to receive',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _buildCategoryTile(
          icon: Icons.thermostat,
          title: 'Temperature Alerts',
          subtitle: 'High/low temperature warnings',
          value: _preferences.temperatureAlerts,
          onChanged: (val) {
            setState(() => _preferences =
                _preferences.copyWith(temperatureAlerts: val));
            _savePreferences();
          },
          color: Colors.red,
        ),
        _buildCategoryTile(
          icon: Icons.water_drop,
          title: 'Water Level Alerts',
          subtitle: 'Low water level warnings',
          value: _preferences.waterLevelAlerts,
          onChanged: (val) {
            setState(() =>
                _preferences = _preferences.copyWith(waterLevelAlerts: val));
            _savePreferences();
          },
          color: Colors.blue,
        ),
        _buildCategoryTile(
          icon: Icons.science,
          title: 'pH Level Alerts',
          subtitle: 'pH balance warnings',
          value: _preferences.phAlerts,
          onChanged: (val) {
            setState(() => _preferences = _preferences.copyWith(phAlerts: val));
            _savePreferences();
          },
          color: Colors.purple,
        ),
        _buildCategoryTile(
          icon: Icons.local_drink,
          title: 'Nutrient Alerts',
          subtitle: 'EC/TDS level warnings',
          value: _preferences.nutrientAlerts,
          onChanged: (val) {
            setState(() =>
                _preferences = _preferences.copyWith(nutrientAlerts: val));
            _savePreferences();
          },
          color: Colors.orange,
        ),
        _buildCategoryTile(
          icon: Icons.settings,
          title: 'System Alerts',
          subtitle: 'Device and connectivity issues',
          value: _preferences.systemAlerts,
          onChanged: (val) {
            setState(() =>
                _preferences = _preferences.copyWith(systemAlerts: val));
            _savePreferences();
          },
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Severity Filter',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose which alert levels to receive',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('All Alerts'),
                subtitle: const Text('Receive all notifications'),
                value: 'all',
                groupValue: _preferences.severityFilter,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) {
                  setState(() =>
                      _preferences = _preferences.copyWith(severityFilter: val));
                  _savePreferences();
                },
              ),
              RadioListTile<String>(
                title: const Text('Warnings & Critical'),
                subtitle: const Text('Skip informational alerts'),
                value: 'warnings',
                groupValue: _preferences.severityFilter,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) {
                  setState(() =>
                      _preferences = _preferences.copyWith(severityFilter: val));
                  _savePreferences();
                },
              ),
              RadioListTile<String>(
                title: const Text('Critical Only'),
                subtitle: const Text('Only urgent alerts'),
                value: 'critical',
                groupValue: _preferences.severityFilter,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) {
                  setState(() =>
                      _preferences = _preferences.copyWith(severityFilter: val));
                  _savePreferences();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Sound & Vibration',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Sound'),
                subtitle: const Text('Play sound for notifications'),
                value: _preferences.soundEnabled,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) {
                  setState(() =>
                      _preferences = _preferences.copyWith(soundEnabled: val));
                  _savePreferences();
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Vibration'),
                subtitle: const Text('Vibrate for notifications'),
                value: _preferences.vibrationEnabled,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) {
                  setState(() => _preferences =
                      _preferences.copyWith(vibrationEnabled: val));
                  _savePreferences();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Quiet Hours',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mute notifications during specific hours',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Enable Quiet Hours'),
                subtitle: Text(
                  _preferences.quietHoursEnabled
                      ? 'From ${_preferences.quietHoursStart}:00 to ${_preferences.quietHoursEnd}:00'
                      : 'Notifications allowed at all times',
                ),
                value: _preferences.quietHoursEnabled,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) {
                  setState(() => _preferences =
                      _preferences.copyWith(quietHoursEnabled: val));
                  _savePreferences();
                },
              ),
              if (_preferences.quietHoursEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.nightlight_round),
                  title: const Text('Start Time'),
                  trailing: Text(
                    '${_preferences.quietHoursStart}:00',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _selectQuietHourTime(true),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.wb_sunny),
                  title: const Text('End Time'),
                  trailing: Text(
                    '${_preferences.quietHoursEnd}:00',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _selectQuietHourTime(false),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No Notifications Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your notification history will appear here',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _history[index];
        return _buildHistoryItem(item);
      },
    );
  }

  Widget _buildCategoryTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        activeColor: Theme.of(context).colorScheme.primary,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildHistoryItem(NotificationHistoryItem item) {
    Color severityColor;
    IconData severityIcon;

    switch (item.severity) {
      case 'critical':
        severityColor = Colors.red;
        severityIcon = Icons.error;
        break;
      case 'warning':
        severityColor = Colors.orange;
        severityIcon = Icons.warning;
        break;
      default:
        severityColor = Colors.blue;
        severityIcon = Icons.info;
    }

    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: severityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(severityIcon, color: severityColor),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: item.read ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.message),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy • hh:mm a').format(item.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _selectQuietHourTime(bool isStart) async {
    final currentHour =
        isStart ? _preferences.quietHoursStart : _preferences.quietHoursEnd;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _preferences = _preferences.copyWith(quietHoursStart: picked.hour);
        } else {
          _preferences = _preferences.copyWith(quietHoursEnd: picked.hour);
        }
      });
      _savePreferences();
    }
  }
}
