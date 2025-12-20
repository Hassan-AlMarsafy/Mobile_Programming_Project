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

  // State for switches
  bool _waterPumpState = true;
  bool _nutrientPumpState = false;
  bool _lightsState = true;

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

  void _processVoiceCommand(String command) {
    setState(() => _lastCommand = command);
    final tts = TtsService();

    // Emergency stop
    if (command.contains('emergency') && command.contains('stop')) {
      _executeEmergencyStop();
      tts.speak('Emergency stop activated');
      return;
    }

    // Water pump control
    if (command.contains('water') && command.contains('pump')) {
      if (command.contains('turn on') || command.contains('start') || command.contains('on')) {
        setState(() => _waterPumpState = true);
        tts.speak('Water pump turned on');
      } else if (command.contains('turn off') || command.contains('stop') || command.contains('off')) {
        setState(() => _waterPumpState = false);
        tts.speak('Water pump turned off');
      }
      return;
    }

    // Nutrient pump / Feeding cycle control
    if ((command.contains('nutrient') || command.contains('feeding')) && 
        (command.contains('pump') || command.contains('cycle'))) {
      if (command.contains('start') || command.contains('turn on') || command.contains('on')) {
        setState(() => _nutrientPumpState = true);
        tts.speak('Feeding cycle started');
      } else if (command.contains('end') || command.contains('stop') || command.contains('turn off') || command.contains('off')) {
        setState(() => _nutrientPumpState = false);
        tts.speak('Feeding cycle ended');
      }
      return;
    }

    // Light control
    if (command.contains('light')) {
      if (command.contains('increase') || command.contains('turn on') || command.contains('on')) {
        setState(() => _lightsState = true);
        tts.speak('Grow lights turned on');
      } else if (command.contains('decrease') || command.contains('turn off') || command.contains('off')) {
        setState(() => _lightsState = false);
        tts.speak('Grow lights turned off');
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

    // Update local state
    setState(() {
      _waterPumpState = false;
      _nutrientPumpState = false;
      _lightsState = false;
    });

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

  // New Widget: Control History
  Widget _buildControlHistoryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHistoryItem(
              'Water Pump',
              'Turned ON manually',
              '10:15 AM',
              Icons.water_damage_outlined,
              Colors.blue,
            ),
            const Divider(height: 24),
            _buildHistoryItem(
              'Grow Lights',
              'Turned ON by schedule',
              '08:00 AM',
              Icons.lightbulb_outline,
              Colors.amber,
            ),
            const Divider(height: 24),
            _buildHistoryItem(
              'Nutrient Pump',
              'Turned OFF manually',
              'Yesterday',
              Icons.opacity,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
            ],
          ),
        ),
        Text(time, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
      ],
    );
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