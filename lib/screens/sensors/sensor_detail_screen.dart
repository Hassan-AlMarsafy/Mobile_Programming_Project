import 'package:flutter/material.dart';
import 'package:hydroponic_app/theme/app_theme.dart';
import '../../utils/validators.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/sensor_viewmodel.dart';
import '../../services/tts_service.dart';
import '../../viewmodels/settings_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SensorDetailScreen extends StatefulWidget {
  final Map<String, dynamic> sensor;

  const SensorDetailScreen({super.key, required this.sensor});

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  // Alert settings state
  bool _alertsEnabled = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;

  // Calibration tracking
  DateTime? _lastCalibrated;
  int _calibrationDueDays = 15;

  @override
  void initState() {
    super.initState();
    _loadAlertSettings();
  }

  Future<void> _loadAlertSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final sensorName = widget.sensor['name'] as String;

    setState(() {
      _alertsEnabled = prefs.getBool('${sensorName}_alertsEnabled') ?? true;
      _emailNotifications =
          prefs.getBool('${sensorName}_emailNotifications') ?? false;
      _smsNotifications =
          prefs.getBool('${sensorName}_smsNotifications') ?? true;

      final lastCalibratedMs = prefs.getInt('${sensorName}_lastCalibrated');
      if (lastCalibratedMs != null) {
        _lastCalibrated = DateTime.fromMillisecondsSinceEpoch(lastCalibratedMs);
        // Calculate days until next calibration (every 30 days)
        final daysSinceCalibration =
            DateTime.now().difference(_lastCalibrated!).inDays;
        _calibrationDueDays = 30 - daysSinceCalibration;
        if (_calibrationDueDays < 0) _calibrationDueDays = 0;
      }
    });
  }

  Future<void> _saveAlertSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final sensorName = widget.sensor['name'] as String;
    await prefs.setBool('${sensorName}_$key', value);
  }

  Future<void> _saveCalibrationDate() async {
    final prefs = await SharedPreferences.getInstance();
    final sensorName = widget.sensor['name'] as String;
    final now = DateTime.now();
    await prefs.setInt(
        '${sensorName}_lastCalibrated', now.millisecondsSinceEpoch);
    setState(() {
      _lastCalibrated = now;
      _calibrationDueDays = 30;
    });
  }

  double _getCalibratedValue() {
    return widget.sensor['value'] + widget.sensor['calibration'];
  }

  String _updateSensorStatus() {
    final calibratedValue = _getCalibratedValue();
    if (calibratedValue < widget.sensor['min'] * 0.9 ||
        calibratedValue > widget.sensor['max'] * 1.1) {
      return 'critical';
    } else if (calibratedValue < widget.sensor['min'] ||
        calibratedValue > widget.sensor['max']) {
      return 'warning';
    } else {
      return 'normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.sensor['name'],
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          if (settingsViewModel.ttsEnabled)
            IconButton(
              icon: const Icon(Icons.volume_up, color: Colors.white),
              onPressed: () => _speakSensorReading(),
            ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export functionality - Coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Value Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.green[700]!, Colors.green[600]!],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.sensor['icon'],
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_getCalibratedValue().toStringAsFixed(1)} ${widget.sensor['unit']}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.sensor['status'] == 'normal'
                                ? Icons.check_circle
                                : Icons.warning,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.sensor['status'].toString().toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Statistics Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Min Range',
                      '${widget.sensor['min']} ${widget.sensor['unit']}',
                      Icons.arrow_downward,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Max Range',
                      '${widget.sensor['max']} ${widget.sensor['unit']}',
                      Icons.arrow_upward,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Real-time Firebase Data
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Firebase Data',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer<SensorViewModel>(
                    builder: (context, viewModel, child) {
                      if (viewModel.loading) {
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      final sensorData = viewModel.sensorData;
                      if (sensorData == null) {
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.cloud_off,
                                    size: 48,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No Firebase data available',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      // Display all sensor readings from Firebase
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildFirebaseDataRow(
                                'Temperature',
                                '${sensorData.temperature.toStringAsFixed(1)}°C',
                                Icons.thermostat,
                                Colors.orange,
                              ),
                              const Divider(height: 20),
                              _buildFirebaseDataRow(
                                'pH Level',
                                sensorData.pH.toStringAsFixed(2),
                                Icons.water_drop,
                                Colors.blue,
                              ),
                              const Divider(height: 20),
                              _buildFirebaseDataRow(
                                'Water Level',
                                '${sensorData.waterLevel.toStringAsFixed(0)}%',
                                Icons.opacity,
                                Colors.cyan,
                              ),
                              const Divider(height: 20),
                              _buildFirebaseDataRow(
                                'TDS',
                                '${sensorData.tds.toStringAsFixed(0)} ppm',
                                Icons.science,
                                Colors.purple,
                              ),
                              const Divider(height: 20),
                              _buildFirebaseDataRow(
                                'Light Intensity',
                                '${sensorData.lightIntensity.toStringAsFixed(0)} lux',
                                Icons.light_mode,
                                Colors.amber,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Last updated: ${sensorData.timestamp.toString().substring(11, 19)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Calibration Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calibration Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildCalibrationRow(
                            'Current Offset',
                            '${widget.sensor['calibration']} ${widget.sensor['unit']}',
                            Icons.tune,
                          ),
                          const Divider(height: 24),
                          _buildCalibrationRow(
                            'Last Calibrated',
                            _lastCalibrated != null
                                ? '${_lastCalibrated!.day}/${_lastCalibrated!.month}/${_lastCalibrated!.year}'
                                : 'Never',
                            Icons.history,
                          ),
                          const Divider(height: 24),
                          _buildCalibrationRow(
                            'Calibration Due',
                            _calibrationDueDays > 0
                                ? 'In $_calibrationDueDays days'
                                : 'Overdue!',
                            Icons.event,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _showCalibrationDialog();
                                _saveCalibrationDate();
                              },
                              icon: const Icon(Icons.tune),
                              label: const Text('Recalibrate Sensor'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Alert Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alert Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Enable Alerts'),
                          subtitle: const Text(
                            'Get notified of critical readings',
                          ),
                          value: _alertsEnabled,
                          onChanged: (value) {
                            setState(() => _alertsEnabled = value);
                            _saveAlertSetting('alertsEnabled', value);
                          },
                          activeColor: Colors.green[700],
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Email Notifications'),
                          subtitle: const Text('Send alerts via email'),
                          value: _emailNotifications,
                          onChanged: _alertsEnabled
                              ? (value) {
                                  setState(() => _emailNotifications = value);
                                  _saveAlertSetting(
                                      'emailNotifications', value);
                                }
                              : null,
                          activeColor: Colors.green[700],
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('SMS Notifications'),
                          subtitle: const Text('Send alerts via SMS'),
                          value: _smsNotifications,
                          onChanged: _alertsEnabled
                              ? (value) {
                                  setState(() => _smsNotifications = value);
                                  _saveAlertSetting('smsNotifications', value);
                                }
                              : null,
                          activeColor: Colors.green[700],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green[700], size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFirebaseDataRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
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
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.check_circle, color: color, size: 16),
        ),
      ],
    );
  }

  void _showCalibrationDialog() {
    final formKey = GlobalKey<FormState>();
    final TextEditingController calibrationController = TextEditingController(
      text: widget.sensor['calibration'].toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.tune, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text('Calibrate Sensor'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkPrimaryColor
                        : AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Raw Reading:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            '${widget.sensor['value'].toStringAsFixed(2)} ${widget.sensor['unit']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Calibrated:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            '${_getCalibratedValue().toStringAsFixed(2)} ${widget.sensor['unit']}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: calibrationController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (value) => Validators.calibrationOffset(
                    value,
                    min: widget.sensor['min'],
                    max: widget.sensor['max'],
                    sensorMin: widget.sensor['min'],
                    sensorMax: widget.sensor['max'],
                    unit: widget.sensor['unit'],
                  ),
                  decoration: InputDecoration(
                    labelText: 'Calibration Offset',
                    hintText: 'Enter offset value',
                    suffixText: widget.sensor['unit'],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    helperText: 'Positive or negative value to adjust reading',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Calibration will take effect immediately',
                          style:
                              TextStyle(fontSize: 11, color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Calibration will take effect immediately',
                          style:
                              TextStyle(fontSize: 11, color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final inputValue = double.parse(calibrationController.text);

                setState(() {
                  widget.sensor['calibration'] = inputValue;
                  widget.sensor['status'] = _updateSensorStatus();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Sensor calibrated successfully'),
                    backgroundColor: Colors.green[700],
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _speakSensorReading() async {
    final tts = TtsService();
    final value = _getCalibratedValue().toStringAsFixed(1);
    final name = widget.sensor['name'];
    final unit = widget.sensor['unit'];
    final status = widget.sensor['status'];
    final min = widget.sensor['min'];
    final max = widget.sensor['max'];

    await tts.speak(
      "$name is currently $value $unit. Status: $status . Acceptable range is between $min and $max $unit.",
    );
  }
}
