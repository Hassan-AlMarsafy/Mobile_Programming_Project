import 'package:flutter/material.dart';
import 'package:hydroponic_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '/widgets/main_layout.dart';
import '../../viewmodels/sensor_viewmodel.dart';
import '/services/tts_service.dart';
import '/viewmodels/settings_viewmodel.dart';
import '../../services/database_service.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  DateTime _lastUpdate = DateTime.now();
  Map<String, dynamic>? _thresholdProfile;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadThresholdProfile();
  }

  Future<void> _loadThresholdProfile() async {
    final profile = await _databaseService.getActiveProfile();
    if (mounted) {
      setState(() {
        _thresholdProfile = profile;
      });
    }
  }

  Future<void> _refreshSensors() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _loadThresholdProfile(); // Reload thresholds on refresh
    if (mounted) {
      setState(() {
        _lastUpdate = DateTime.now();
      });
    }
  }

  Future<void> _speakAllSensors() async {
    final viewModel = Provider.of<SensorViewModel>(context, listen: false);
    final sensorData = viewModel.sensorData;
    if (sensorData == null) return;

    final tts = TtsService();
    StringBuffer message = StringBuffer("Sensor readings. ");

    message.write(
        "Temperature is ${sensorData.temperature.toStringAsFixed(1)} degrees Celsius. ");
    message.write("pH level is ${sensorData.pH.toStringAsFixed(1)}. ");
    message.write(
        "Water level is ${sensorData.waterLevel.toStringAsFixed(0)} percent. ");
    message.write("TDS is ${sensorData.tds.toStringAsFixed(0)} ppm. ");
    message.write(
        "Light intensity is ${sensorData.lightIntensity.toStringAsFixed(0)} lux. ");

    await tts.speak(message.toString());
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'normal':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getSensorStatus(double value, double min, double max) {
    if (value < min * 0.9 || value > max * 1.1) {
      return 'critical';
    } else if (value < min || value > max) {
      return 'warning';
    }
    return 'normal';
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Sensor Monitoring',
      currentIndex: 1,
      actions: [
        Consumer<SettingsViewModel>(
          builder: (context, settings, _) {
            if (!settings.ttsEnabled) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.volume_up, color: Colors.white),
              onPressed: _speakAllSensors,
              tooltip: 'Read all sensors',
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _refreshSensors,
          tooltip: 'Refresh sensors',
        ),
      ],
      child: Consumer<SensorViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.loading || viewModel.sensorData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final sensorData = viewModel.sensorData!;
          final actuatorData = viewModel.actuatorData;

          return RefreshIndicator(
            onRefresh: _refreshSensors,
            color: Colors.green[700],
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkPrimaryColor
                        : AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '5 Sensors Active',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last update: ${_getTimeAgo(_lastUpdate)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Temperature Sensor
                _buildSensorCard(
                  name: 'Temperature',
                  value: sensorData.temperature,
                  unit: '°C',
                  icon: Icons.thermostat,
                  min: (_thresholdProfile?['temp_min'] as num?)?.toDouble() ??
                      20.0,
                  max: (_thresholdProfile?['temp_max'] as num?)?.toDouble() ??
                      30.0,
                ),

                // pH Sensor
                _buildSensorCard(
                  name: 'pH Level',
                  value: sensorData.pH,
                  unit: 'pH',
                  icon: Icons.water_drop,
                  min:
                      (_thresholdProfile?['ph_min'] as num?)?.toDouble() ?? 5.5,
                  max:
                      (_thresholdProfile?['ph_max'] as num?)?.toDouble() ?? 7.5,
                ),

                // Water Level Sensor
                _buildSensorCard(
                  name: 'Water Level',
                  value: sensorData.waterLevel,
                  unit: '%',
                  icon: Icons.waves,
                  min: (_thresholdProfile?['water_min'] as num?)?.toDouble() ??
                      30.0,
                  max: (_thresholdProfile?['water_max'] as num?)?.toDouble() ??
                      100.0,
                ),

                // TDS Sensor
                _buildSensorCard(
                  name: 'TDS (Conductivity)',
                  value: sensorData.tds,
                  unit: 'ppm',
                  icon: Icons.electric_bolt,
                  min: (_thresholdProfile?['tds_min'] as num?)?.toDouble() ??
                      500.0,
                  max: (_thresholdProfile?['tds_max'] as num?)?.toDouble() ??
                      1500.0,
                ),

                // Light Intensity Sensor
                _buildSensorCard(
                  name: 'Light Intensity',
                  value: sensorData.lightIntensity,
                  unit: 'lux',
                  icon: Icons.wb_sunny,
                  min: (_thresholdProfile?['light_min'] as num?)?.toDouble() ??
                      0.0,
                  max: (_thresholdProfile?['light_max'] as num?)?.toDouble() ??
                      1000.0,
                ),

                // Actuators Section
                if (actuatorData != null) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Actuator Status',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _buildActuatorCard(
                    name: 'Water Pump',
                    icon: Icons.water,
                    isActive: actuatorData.waterPump,
                  ),
                  _buildActuatorCard(
                    name: 'Nutrient Pump',
                    icon: Icons.science,
                    isActive: actuatorData.nutrientPump,
                  ),
                  _buildActuatorCard(
                    name: 'Lights',
                    icon: Icons.lightbulb,
                    isActive: actuatorData.lights,
                  ),
                  _buildActuatorCard(
                    name: 'Fan',
                    icon: Icons.air,
                    isActive: actuatorData.fan,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSensorCard({
    required String name,
    required double value,
    required String unit,
    required IconData icon,
    required double min,
    required double max,
  }) {
    final status = _getSensorStatus(value, min, max);
    final statusColor = _getStatusColor(status);
    final progress = ((value - min) / (max - min)).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/sensor-detail',
            arguments: {
              'id': name,
              'name': name,
              'value': value,
              'unit': unit,
              'icon': icon,
              'status': status,
              'min': min,
              'max': max,
              'calibration': 0.0,
            },
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${value.toStringAsFixed(1)} $unit',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${min.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        color: statusColor,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Text(
                    '${max.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActuatorCard({
    required String name,
    required IconData icon,
    required bool isActive,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.green : Colors.grey,
            size: 28,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isActive ? 'ON' : 'OFF',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
