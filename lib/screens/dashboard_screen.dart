import 'package:flutter/material.dart';
import 'package:hydroponic_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../viewmodels/sensor_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/sensor_tile.dart';
import '../widgets/main_layout.dart';
import '../models/actuator_data.dart';
import '../services/tts_service.dart';
import '../services/firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = context.watch<SettingsViewModel>();
    
    return MainLayout(
      title: 'Dashboard',
      currentIndex: 0,
      actions: [
        if (settingsViewModel.ttsEnabled)
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.white),
            onPressed: () => _speakSystemStatus(),
          ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, '/alerts'),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
      ],
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              // Data refreshes automatically via Firestore stream
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: Colors.green[700],
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkPrimaryColor
                          : AppTheme.primaryColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome Back! 👋',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Monitor your hydroponic system',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // System Status Overview
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Status',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSystemStatusCard(),
                      ],
                    ),
                  ),

                  // Sensor Monitoring Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sensor Readings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/sensor'),
                          child: Text(
                            'View All',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<SensorViewModel>(
                    builder: (context, viewModel, child) {
                      if (viewModel.loading || viewModel.sensorData == null) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final sensorData = viewModel.sensorData!;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                          children: [
                            SensorCard(
                              title: 'Temperature',
                              value:
                                  '${sensorData.temperature.toStringAsFixed(1)}°C',
                              status: _getSensorStatus(
                                sensorData.temperature,
                                20,
                                40,
                              ),
                            ),
                            SensorCard(
                              title: 'pH Level',
                              value: sensorData.pH.toStringAsFixed(1),
                              status: _getSensorStatus(sensorData.pH, 5.5, 7.5),
                            ),
                            SensorCard(
                              title: 'TDS',
                              value: '${sensorData.tds.toStringAsFixed(0)} ppm',
                              status: _getSensorStatus(
                                sensorData.tds,
                                500,
                                1500,
                              ),
                            ),
                            SensorCard(
                              title: 'Water Level',
                              value:
                                  '${sensorData.waterLevel.toStringAsFixed(0)}%',
                              status: _getSensorStatus(
                                sensorData.waterLevel,
                                30,
                                100,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Critical Controls and Mode
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Controls',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCriticalControlsCard(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start),
                  ),

                  const SizedBox(height: 15),

                  // Recent Activity
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRecentActivityList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Consumer<SensorViewModel>(
      builder: (context, viewModel, child) {
        final sensorData = viewModel.sensorData;
        final actuatorData = viewModel.actuatorData;
        final loading = viewModel.loading;

        // Calculate system health based on sensor readings
        int criticalIssues = 0;
        int warnings = 0;
        int normalSensors = 0;
        const int totalSensors = 5;
        
        if (sensorData != null) {
          final tempStatus = _getSensorStatus(sensorData.temperature, 20, 30);
          final phStatus = _getSensorStatus(sensorData.pH, 5.5, 7.5);
          final tdsStatus = _getSensorStatus(sensorData.tds, 500, 1500);
          final waterStatus = _getSensorStatus(sensorData.waterLevel, 30, 100);
          final lightStatus = _getSensorStatus(sensorData.lightIntensity, 0, 1000);
          
          // Count issues
          if (tempStatus == SensorStatus.critical) criticalIssues++;
          else if (tempStatus == SensorStatus.warning) warnings++;
          else normalSensors++;
          
          if (phStatus == SensorStatus.critical) criticalIssues++;
          else if (phStatus == SensorStatus.warning) warnings++;
          else normalSensors++;
          
          if (tdsStatus == SensorStatus.critical) criticalIssues++;
          else if (tdsStatus == SensorStatus.warning) warnings++;
          else normalSensors++;
          
          if (waterStatus == SensorStatus.critical) criticalIssues++;
          else if (waterStatus == SensorStatus.warning) warnings++;
          else normalSensors++;
          
          if (lightStatus == SensorStatus.critical) criticalIssues++;
          else if (lightStatus == SensorStatus.warning) warnings++;
          else normalSensors++;
        }

        // Calculate health percentage
        int healthPercentage = sensorData != null 
            ? ((normalSensors / totalSensors) * 100).round() 
            : 0;
        
        // Sensors connected count
        int connectedSensors = sensorData != null ? totalSensors : 0;

        // Determine overall status
        Color statusColor;
        IconData statusIcon;
        String statusText;
        String statusSubtext;

        if (loading) {
          statusColor = Colors.grey;
          statusIcon = Icons.sync;
          statusText = 'Connecting...';
          statusSubtext = 'Please wait';
        } else if (criticalIssues > 0) {
          statusColor = Colors.red[700]!;
          statusIcon = Icons.error;
          statusText = 'Critical Issues';
          statusSubtext = '$criticalIssues sensor(s) need immediate attention';
        } else if (warnings > 0) {
          statusColor = Colors.orange[700]!;
          statusIcon = Icons.warning_amber_rounded;
          statusText = 'Warning';
          statusSubtext = '$warnings sensor(s) out of optimal range';
        } else {
          statusColor = Colors.green[600]!;
          statusIcon = Icons.check_circle;
          statusText = 'All Systems Operational';
          statusSubtext = 'Everything running smoothly';
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      statusIcon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusSubtext,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusMetric(
                      icon: Icons.sensors,
                      label: 'Sensors',
                      value: '$connectedSensors/$totalSensors',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusMetric(
                      icon: Icons.schedule,
                      label: 'Updated',
                      value: sensorData != null 
                          ? _formatTime(sensorData.timestamp)
                          : 'N/A',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusMetric(
                      icon: Icons.health_and_safety,
                      label: 'Health',
                      value: '$healthPercentage%',
                    ),
                  ),
                ],
              ),
              if (actuatorData != null) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white30, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActuatorIndicator(
                      icon: Icons.water_drop,
                      label: 'Water',
                      isActive: actuatorData.waterPump,
                      onTap: () => _toggleActuator(viewModel, actuatorData, 'waterPump'),
                    ),
                    _buildActuatorIndicator(
                      icon: Icons.science,
                      label: 'Nutrients',
                      isActive: actuatorData.nutrientPump,
                      onTap: () => _toggleActuator(viewModel, actuatorData, 'nutrientPump'),
                    ),
                    _buildActuatorIndicator(
                      icon: Icons.lightbulb,
                      label: 'Lights',
                      isActive: actuatorData.lights,
                      onTap: () => _toggleActuator(viewModel, actuatorData, 'lights'),
                    ),
                    _buildActuatorIndicator(
                      icon: Icons.air,
                      label: 'Fan',
                      isActive: actuatorData.fan,
                      onTap: () => _toggleActuator(viewModel, actuatorData, 'fan'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActuatorIndicator({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive 
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive 
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleActuator(SensorViewModel viewModel, dynamic actuatorData, String actuatorName) async {
    if (actuatorData == null) return;

    // Determine new state
    bool newState;
    String displayName;
    switch (actuatorName) {
      case 'waterPump':
        newState = !actuatorData.waterPump;
        displayName = 'Water Pump';
        break;
      case 'nutrientPump':
        newState = !actuatorData.nutrientPump;
        displayName = 'Nutrient Pump';
        break;
      case 'lights':
        newState = !actuatorData.lights;
        displayName = 'Grow Lights';
        break;
      case 'fan':
        newState = !actuatorData.fan;
        displayName = 'Ventilation Fan';
        break;
      default:
        return;
    }

    // Create updated actuator data with toggled value
    final updatedData = ActuatorData(
      waterPump: actuatorName == 'waterPump' ? newState : actuatorData.waterPump,
      nutrientPump: actuatorName == 'nutrientPump' ? newState : actuatorData.nutrientPump,
      lights: actuatorName == 'lights' ? newState : actuatorData.lights,
      fan: actuatorName == 'fan' ? newState : actuatorData.fan,
      timestamp: DateTime.now(),
    );

    // Send command to Firebase
    await viewModel.sendActuatorCommand(updatedData);

    // Log the activity
    final firestoreService = FirestoreService();
    await firestoreService.logActivity(
      title: '$displayName ${newState ? "activated" : "deactivated"}',
      description: 'Manual control: $displayName turned ${newState ? "ON" : "OFF"}',
      type: actuatorName == 'waterPump' ? 'water_pump' :
            actuatorName == 'nutrientPump' ? 'nutrient_pump' :
            actuatorName == 'lights' ? 'lights' : 'fan',
    );
  }

  Widget _buildStatusMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp); 

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    return Consumer<SensorViewModel>(
      builder: (context, viewModel, child) {
        final activities = viewModel.activityLogs.take(5).toList();

        if (activities.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No recent activity',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: activities.asMap().entries.map((entry) {
              final index = entry.key;
              final activity = entry.value;
              final isLast = index == activities.length - 1;

              return Column(
                children: [
                  _buildActivityItem(
                    icon: _getActivityIcon(activity.type),
                    title: activity.title,
                    time: _formatActivityTime(activity.timestamp),
                    color: _getActivityColor(activity.type),
                  ),
                  if (!isLast) Divider(height: 1, color: Theme.of(context).dividerColor),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'water_pump':
        return Icons.water_drop;
      case 'nutrient_pump':
        return Icons.science;
      case 'lights':
        return Icons.lightbulb;
      case 'fan':
        return Icons.air;
      case 'temperature':
        return Icons.thermostat;
      case 'ph':
        return Icons.water;
      case 'emergency':
        return Icons.warning;
      case 'system':
        return Icons.settings;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'water_pump':
        return Colors.blue;
      case 'nutrient_pump':
        return Colors.purple;
      case 'lights':
        return Colors.amber;
      case 'fan':
        return Colors.cyan;
      case 'temperature':
        return Colors.orange;
      case 'ph':
        return Colors.teal;
      case 'emergency':
        return Colors.red;
      case 'system':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatActivityTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String time,
    required Color color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        time,
        style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
      ),
    );
  }

  SensorStatus _getSensorStatus(double value, double min, double max) {
    if (value < min * 0.9 || value > max * 1.1) {
      return SensorStatus.critical;
    } else if (value < min || value > max) {
      return SensorStatus.warning;
    }
    return SensorStatus.normal;
  }

  Widget _buildCriticalControlsCard() {
    return Consumer<SensorViewModel>(
      builder: (context, viewModel, child) {
        final actuatorData = viewModel.actuatorData;

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Mode Selector
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        viewModel.isAutomaticMode ? Icons.auto_mode : Icons.touch_app,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Mode',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              viewModel.isAutomaticMode ? 'Automatic' : 'Manual',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: viewModel.isAutomaticMode,
                        onChanged: (value) async {
                          await viewModel.setSystemMode(value);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Switched to ${value ? 'Automatic' : 'Manual'} mode',
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.green[700],
                              ),
                            );
                          }
                        },
                        activeColor: Colors.green[600],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Emergency Stop Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showEmergencyStopDialog(viewModel, actuatorData);
                    },
                    icon: const Icon(Icons.power_settings_new, size: 24),
                    label: const Text(
                      'EMERGENCY STOP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // All On/Off Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: actuatorData != null
                            ? () => _toggleAllActuators(viewModel, actuatorData, true)
                            : null,
                        icon: const Icon(Icons.power, size: 20),
                        label: const Text('All ON'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.green[700]!, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: actuatorData != null
                            ? () => _toggleAllActuators(viewModel, actuatorData, false)
                            : null,
                        icon: const Icon(Icons.power_off, size: 20),
                        label: const Text('All OFF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[400]!, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEmergencyStopDialog(SensorViewModel viewModel, dynamic actuatorData) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700], size: 32),
            const SizedBox(width: 12),
            const Text('Emergency Stop'),
          ],
        ),
        content: const Text(
          'This will immediately turn off all actuators. Are you sure?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (actuatorData != null) {
                // Turn off all actuators
                final updatedData = ActuatorData(
                  waterPump: false,
                  nutrientPump: false,
                  lights: false,
                  fan: false,
                  timestamp: DateTime.now(),
                );

                await viewModel.sendActuatorCommand(updatedData);

                // Log the activity with emergency type (red)
                final firestoreService = FirestoreService();
                await firestoreService.logActivity(
                  title: 'EMERGENCY STOP',
                  description: 'All systems halted - Water Pump, Nutrient Pump, Lights, and Fan turned OFF',
                  type: 'emergency',
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('EMERGENCY STOP - All systems halted!'),
                      backgroundColor: Colors.red[700],
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('STOP ALL'),
          ),
        ],
      ),
    );
  }

  void _toggleAllActuators(SensorViewModel viewModel, dynamic actuatorData, bool turnOn) async {
    final updatedData = ActuatorData(
      waterPump: turnOn,
      nutrientPump: turnOn,
      lights: turnOn,
      fan: turnOn,
      timestamp: DateTime.now(),
    );

    await viewModel.sendActuatorCommand(updatedData);

    // Log the activity
    final firestoreService = FirestoreService();
    await firestoreService.logActivity(
      title: turnOn ? 'All actuators activated' : 'All actuators deactivated',
      description: 'Quick control: All systems turned ${turnOn ? "ON" : "OFF"}',
      type: 'system',
    );
  }

  Future<void> _speakSystemStatus() async {
    final tts = TtsService();
    final viewModel = context.read<SensorViewModel>();
    
    StringBuffer message = StringBuffer("System status report. ");
    
    final sensorData = viewModel.sensorData;
    if (sensorData == null) {
      message.write("No sensor data available.");
    } else {
      message.write("All systems operational. ");
      message.write("Temperature is ${sensorData.temperature.toStringAsFixed(1)} degrees celsius. ");
      message.write("pH level is ${sensorData.pH.toStringAsFixed(1)}. ");
      message.write("Water level is ${sensorData.waterLevel.toStringAsFixed(0)} percent. ");
      message.write("TDS is ${sensorData.tds.toStringAsFixed(0)} ppm. ");
      message.write("Light intensity is ${sensorData.lightIntensity.toStringAsFixed(0)} lux. ");
    }
    
    await tts.speak(message.toString());
  }
}
