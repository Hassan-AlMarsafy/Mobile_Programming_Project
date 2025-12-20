import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/main_layout.dart';
import '../viewmodels/sensor_viewmodel.dart';
import '../models/actuator_data.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/firestore_service.dart';
import '../services/schedule_service.dart';
import '../viewmodels/settings_viewmodel.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _uiUpdateTimer;


  // Speech recognition
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;
  String _lastCommand = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
    // Don't initialize speech service here - only when SR is enabled and user taps mic

    // Update UI every 10 seconds to refresh schedule status
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _speechService.dispose();
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speechService.startListening(
        onResult: (text) {
          setState(() => _isListening = false);
          _processVoiceCommand(text);
        },
      );
    }
  }

  void _processVoiceCommand(String command) async {
    setState(() => _lastCommand = command);
    final tts = TtsService();
    final viewModel = context.read<SensorViewModel>();
    final actuatorData = viewModel.actuatorData;

    if (actuatorData == null) {
      tts.speak('System not ready. Please try again.');
      return;
    }

    // Emergency stop
    if (command.contains('emergency') && command.contains('stop')) {
      _executeEmergencyStop();
      tts.speak('Emergency stop activated');
      return;
    }

    // Water pump control
    if (command.contains('water') && command.contains('pump')) {
      if (command.contains('turn on') || command.contains('start') || command.contains('on')) {
        _toggleActuator(viewModel, actuatorData, 'waterPump', true);
        tts.speak('Water pump turned on');
      } else if (command.contains('turn off') || command.contains('stop') || command.contains('off')) {
        _toggleActuator(viewModel, actuatorData, 'waterPump', false);
        tts.speak('Water pump turned off');
      }
      return;
    }

    // Nutrient pump / Feeding cycle control
    if ((command.contains('nutrient') || command.contains('feeding')) && 
        (command.contains('pump') || command.contains('cycle'))) {
      if (command.contains('start') || command.contains('turn on') || command.contains('on')) {
        _toggleActuator(viewModel, actuatorData, 'nutrientPump', true);
        tts.speak('Feeding cycle started');
      } else if (command.contains('end') || command.contains('stop') || command.contains('turn off') || command.contains('off')) {
        _toggleActuator(viewModel, actuatorData, 'nutrientPump', false);
        tts.speak('Feeding cycle ended');
      }
      return;
    }

    // Light control
    if (command.contains('light')) {
      if (command.contains('increase') || command.contains('turn on') || command.contains('on')) {
        _toggleActuator(viewModel, actuatorData, 'lights', true);
        tts.speak('Grow lights turned on');
      } else if (command.contains('decrease') || command.contains('turn off') || command.contains('off')) {
        _toggleActuator(viewModel, actuatorData, 'lights', false);
        tts.speak('Grow lights turned off');
      }
      return;
    }

    // Fan control
    if (command.contains('fan')) {
      if (command.contains('turn on') || command.contains('start') || command.contains('on')) {
        _toggleActuator(viewModel, actuatorData, 'fan', true);
        tts.speak('Fan turned on');
      } else if (command.contains('turn off') || command.contains('stop') || command.contains('off')) {
        _toggleActuator(viewModel, actuatorData, 'fan', false);
        tts.speak('Fan turned off');
      }
      return;
    }

    // Unknown command
    tts.speak('Command not recognized');
  }

  void _executeEmergencyStop() async {
    final viewModel = context.read<SensorViewModel>();
    
    // Turn off all actuators
    final updatedData = ActuatorData(
      waterPump: false,
      nutrientPump: false,
      lights: false,
      fan: false,
      timestamp: DateTime.now(),
    );

    // Send command to Firebase
    await viewModel.sendActuatorCommand(updatedData);

    // Log the activity
    final firestoreService = FirestoreService();
    await firestoreService.logActivity(
      title: 'EMERGENCY STOP',
      description: 'All systems halted - Water Pump, Nutrient Pump, Lights, and Fan turned OFF',
      type: 'emergency',
    );


    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('EMERGENCY STOP - All systems halted!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Control Panel',
      currentIndex: 2,
      actions: [
        Consumer<SettingsViewModel>(
          builder: (context, settings, _) {
            if (!settings.srEnabled) return const SizedBox.shrink();
            return IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : Colors.white,
              ),
              onPressed: _toggleListening,
              tooltip: _isListening ? 'Stop listening' : 'Voice command',
            );
          },
        ),
      ],
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEmergencyStopCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Manual Actuator Control'),
                const SizedBox(height: 16),
                _buildManualControlCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Automation & Scheduling'),
                const SizedBox(height: 16),
                _buildSchedulingCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Control History'),
                const SizedBox(height: 16),
                _buildControlHistoryCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  // New Widget: Emergency Stop Card
  Widget _buildEmergencyStopCard() {
    return Card(
      elevation: 4,
      color: Colors.red[700],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const Icon(Icons.power_settings_new, color: Colors.white, size: 40),
            const SizedBox(width: 20),
            const Expanded(
              child: Text(
                'Emergency Stop',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _executeEmergencyStop,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red[700],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('HALT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // New Widget: Manual Control Card
  Widget _buildManualControlCard() {
    return Consumer<SensorViewModel>(
      builder: (context, viewModel, child) {
        final actuatorData = viewModel.actuatorData;

        if (actuatorData == null) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildControlSwitch(
                  'Water Pump',
                  actuatorData.waterPump,
                  (value) => _toggleActuator(viewModel, actuatorData, 'waterPump', value),
                  Icons.water_damage_outlined,
                  Colors.blue,
                ),
                const Divider(height: 24),
                _buildControlSwitch(
                  'Nutrient Pump',
                  actuatorData.nutrientPump,
                  (value) => _toggleActuator(viewModel, actuatorData, 'nutrientPump', value),
                  Icons.opacity,
                  Colors.purple,
                ),
                const Divider(height: 24),
                _buildControlSwitch(
                  'Grow Lights',
                  actuatorData.lights,
                  (value) => _toggleActuator(viewModel, actuatorData, 'lights', value),
                  Icons.lightbulb_outline,
                  Colors.amber,
                ),
                const Divider(height: 24),
                _buildControlSwitch(
                  'Fan',
                  actuatorData.fan,
                  (value) => _toggleActuator(viewModel, actuatorData, 'fan', value),
                  Icons.air,
                  Colors.teal,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlSwitch(
      String title,
      bool value,
      ValueChanged<bool> onChanged,
      IconData icon,
      Color color,
      ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.green[600],
        ),
      ],
    );
  }
  
  Widget _buildSchedulingCard() {
    final scheduleService = ScheduleService();
    final isWatering = scheduleService.isCurrentlyWatering;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Icon(Icons.schedule, color: Colors.green[700], size: 32),
            title: const Text('Manage Schedules', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Set timers for pumps and lights'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/watering-schedule');
            },
          ),
          if (isWatering)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.blue[900]!.withOpacity(0.3) : Colors.blue[50],
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.water_drop, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scheduled watering in progress...',
                      style: TextStyle(
                        color: isDark ? Colors.blue[300] : Colors.blue[900],
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await scheduleService.stopCurrentWatering();
                      setState(() {});
                    },
                    child: const Text('STOP'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Control History Button - Opens Modal with Full History
  Widget _buildControlHistoryCard() {
    return Consumer<SensorViewModel>(
      builder: (context, viewModel, child) {
        final logs = viewModel.activityLogs;
        final displayCount = logs.length > 5 ? 5 : logs.length;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => _showFullControlHistory(),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, color: Colors.green[700], size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Control History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${logs.length} events',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[800],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                    ],
                  ),
                  if (logs.isEmpty) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'No control history yet',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    // Show only first 5 events
                    ...List.generate(displayCount, (index) {
                      final log = logs[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: index < displayCount - 1 ? 12 : 0),
                        child: _buildHistoryItem(log),
                      );
                    }),
                    if (logs.length > 5) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Tap to view all ${logs.length} events',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryItem(dynamic log) {
    final title = log.title ?? 'System Activity';
    final description = log.description ?? '';
    final timestamp = log.timestamp;
    final type = log.type ?? 'system';

    // Get icon and color based on type
    IconData icon;
    Color color;

    switch (type) {
      case 'water_pump':
        icon = Icons.water_damage_outlined;
        color = Colors.blue;
        break;
      case 'nutrient_pump':
        icon = Icons.opacity;
        color = Colors.purple;
        break;
      case 'lights':
        icon = Icons.lightbulb_outline;
        color = Colors.amber;
        break;
      case 'fan':
        icon = Icons.air;
        color = Colors.teal;
        break;
      case 'emergency':
        icon = Icons.emergency;
        color = Colors.red;
        break;
      case 'schedule':
        icon = Icons.schedule;
        color = Colors.green;
        break;
      default:
        icon = Icons.settings;
        color = Colors.grey;
    }

    // Format time
    String timeStr;
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      timeStr = 'Just now';
    } else if (diff.inHours < 1) {
      timeStr = '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      timeStr = '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      timeStr = 'Yesterday';
    } else {
      timeStr = '${diff.inDays}d ago';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          timeStr,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _showFullControlHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Colors.green[700], size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Full Control History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // List
                Expanded(
                  child: Consumer<SensorViewModel>(
                    builder: (context, viewModel, child) {
                      final logs = viewModel.activityLogs;

                      if (logs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No Control History',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Activity will appear here as you control the system',
                                style: TextStyle(color: Colors.grey[500]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: logs.length,
                        separatorBuilder: (context, index) => const Divider(height: 24),
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return _buildFullHistoryItem(log);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullHistoryItem(dynamic log) {
    final title = log.title ?? 'System Activity';
    final description = log.description ?? '';
    final timestamp = log.timestamp;
    final type = log.type ?? 'system';

    // Get icon and color based on type
    IconData icon;
    Color color;

    switch (type) {
      case 'water_pump':
        icon = Icons.water_damage_outlined;
        color = Colors.blue;
        break;
      case 'nutrient_pump':
        icon = Icons.opacity;
        color = Colors.purple;
        break;
      case 'lights':
        icon = Icons.lightbulb_outline;
        color = Colors.amber;
        break;
      case 'fan':
        icon = Icons.air;
        color = Colors.teal;
        break;
      case 'emergency':
        icon = Icons.emergency;
        color = Colors.red;
        break;
      case 'schedule':
        icon = Icons.schedule;
        color = Colors.green;
        break;
      default:
        icon = Icons.settings;
        color = Colors.grey;
    }

    // Format date and time
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    final dateStr = _formatFullDate(timestamp);
    final timeStr = _formatTime(timestamp);

    String relativeTime;
    if (diff.inMinutes < 1) {
      relativeTime = 'Just now';
    } else if (diff.inHours < 1) {
      relativeTime = '${diff.inMinutes} minutes ago';
    } else if (diff.inDays < 1) {
      relativeTime = '${diff.inHours} hours ago';
    } else if (diff.inDays == 1) {
      relativeTime = 'Yesterday';
    } else {
      relativeTime = '$dateStr';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '$relativeTime • $timeStr',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  void _toggleActuator(SensorViewModel viewModel, ActuatorData actuatorData, String actuatorName, bool value) async {
    // Create updated actuator data with new value
    final updatedData = ActuatorData(
      waterPump: actuatorName == 'waterPump' ? value : actuatorData.waterPump,
      nutrientPump: actuatorName == 'nutrientPump' ? value : actuatorData.nutrientPump,
      lights: actuatorName == 'lights' ? value : actuatorData.lights,
      fan: actuatorName == 'fan' ? value : actuatorData.fan,
      timestamp: DateTime.now(),
    );

    // Get display name
    String displayName;
    String type;
    switch (actuatorName) {
      case 'waterPump':
        displayName = 'Water Pump';
        type = 'water_pump';
        break;
      case 'nutrientPump':
        displayName = 'Nutrient Pump';
        type = 'nutrient_pump';
        break;
      case 'lights':
        displayName = 'Grow Lights';
        type = 'lights';
        break;
      case 'fan':
        displayName = 'Ventilation Fan';
        type = 'fan';
        break;
      default:
        displayName = actuatorName;
        type = 'system';
    }

    // Send command to Firebase
    await viewModel.sendActuatorCommand(updatedData);

    // Log the activity
    final firestoreService = FirestoreService();
    await firestoreService.logActivity(
      title: '$displayName ${value ? "activated" : "deactivated"}',
      description: 'Control panel: $displayName turned ${value ? "ON" : "OFF"}',
      type: type,
    );
    
    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$displayName turned ${value ? 'ON' : 'OFF'}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green[700],
        ),
      );
    }
  }
}