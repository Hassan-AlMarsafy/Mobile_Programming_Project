import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/main_layout.dart';
import '../viewmodels/sensor_viewmodel.dart';
import '../models/actuator_data.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Control Panel',
      currentIndex: 2,
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
              onPressed: () {
                // Placeholder for emergency stop action
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All systems halted!'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
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

  // New Widget: Scheduling Card
  Widget _buildSchedulingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(Icons.schedule, color: Colors.green[700], size: 32),
        title: const Text('Manage Schedules', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Set timers for pumps and lights'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Placeholder for navigating to a detailed scheduling screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scheduling screen coming soon!')),
          );
        },
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

    // Send command to Firebase
    await viewModel.sendActuatorCommand(updatedData);
    
    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${actuatorName == 'waterPump' ? 'Water Pump' : actuatorName == 'nutrientPump' ? 'Nutrient Pump' : actuatorName == 'lights' ? 'Lights' : 'Fan'} turned ${value ? 'ON' : 'OFF'}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green[700],
        ),
      );
    }
  }
}