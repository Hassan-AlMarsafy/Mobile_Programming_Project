import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/widgets/main_layout.dart';
import '../../viewmodels/sensor_viewmodel.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  DateTime _lastUpdate = DateTime.now();

  Future<void> _refreshSensors() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _lastUpdate = DateTime.now();
      });
    }
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
                    gradient: LinearGradient(
                      colors: [Colors.green[700]!, Colors.green[600]!],
                    ),
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
                  min: 20.0,
                  max: 30.0,
                ),

                // pH Sensor
                _buildSensorCard(
                  name: 'pH Level',
                  value: sensorData.pH,
                  unit: 'pH',
                  icon: Icons.water_drop,
                  min: 5.5,
                  max: 7.5,
                ),

                // Water Level Sensor
                _buildSensorCard(
                  name: 'Water Level',
                  value: sensorData.waterLevel,
                  unit: '%',
                  icon: Icons.waves,
                  min: 30.0,
                  max: 100.0,
                ),

                // TDS Sensor
                _buildSensorCard(
                  name: 'TDS (Conductivity)',
                  value: sensorData.tds,
                  unit: 'ppm',
                  icon: Icons.electric_bolt,
                  min: 500.0,
                  max: 1500.0,
                ),

                // Light Intensity Sensor
                _buildSensorCard(
                  name: 'Light Intensity',
                  value: sensorData.lightIntensity,
                  unit: 'lux',
                  icon: Icons.wb_sunny,
                  min: 0.0,
                  max: 1000.0,
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
