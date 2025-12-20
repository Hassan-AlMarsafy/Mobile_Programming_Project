import 'package:flutter/material.dart';
import 'package:hydroponic_app/theme/app_theme.dart';
import '../../utils/validators.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/sensor_viewmodel.dart';
import '../../services/tts_service.dart';
import '../../viewmodels/settings_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/database_service.dart';
import '../../models/sensor_calibration.dart';

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

  // SQLite data
  final DatabaseService _databaseService = DatabaseService();
  Map<String, dynamic>? _thresholdProfile;
  SensorCalibration? _sensorCalibration;
  String _sensorType = '';

  // Get sensor type key from sensor name
  String _getSensorType(String sensorName) {
    switch (sensorName) {
      case 'Temperature':
        return 'temperature';
      case 'pH Level':
        return 'ph';
      case 'Water Level':
        return 'waterLevel';
      case 'TDS (Conductivity)':
        return 'tds';
      case 'Light Intensity':
        return 'light';
      default:
        return sensorName.toLowerCase().replaceAll(' ', '_');
    }
  }

  // Get threshold keys for this sensor
  Map<String, String> _getThresholdKeys() {
    switch (_sensorType) {
      case 'temperature':
        return {'min': 'temp_min', 'max': 'temp_max'};
      case 'ph':
        return {'min': 'ph_min', 'max': 'ph_max'};
      case 'waterLevel':
        return {'min': 'water_min', 'max': 'water_max'};
      case 'tds':
        return {'min': 'tds_min', 'max': 'tds_max'};
      case 'light':
        return {'min': 'light_min', 'max': 'light_max'};
      default:
        return {'min': 'temp_min', 'max': 'temp_max'};
    }
  }

  // Get min threshold from SQLite or fallback to argument
  double get _minThreshold {
    if (_thresholdProfile != null) {
      final key = _getThresholdKeys()['min']!;
      return (_thresholdProfile![key] as num?)?.toDouble() ??
          widget.sensor['min'];
    }
    return widget.sensor['min'];
  }

  // Get max threshold from SQLite or fallback to argument
  double get _maxThreshold {
    if (_thresholdProfile != null) {
      final key = _getThresholdKeys()['max']!;
      return (_thresholdProfile![key] as num?)?.toDouble() ??
          widget.sensor['max'];
    }
    return widget.sensor['max'];
  }

  // Get calibration offset from SQLite or default to 0
  double get _calibrationOffset {
    return _sensorCalibration?.offset ?? 0.0;
  }

  // Get last calibrated date from SQLite
  DateTime? get _lastCalibrated => _sensorCalibration?.lastCalibrated;

  // Get days until calibration due
  int get _calibrationDueDays {
    if (_sensorCalibration?.nextCalibrationDue == null) return 30;
    final days = _sensorCalibration!.nextCalibrationDue!
        .difference(DateTime.now())
        .inDays;
    return days < 0 ? 0 : days;
  }

  @override
  void initState() {
    super.initState();
    _sensorType = _getSensorType(widget.sensor['name'] as String);
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadAlertSettings(),
      _loadThresholds(),
      _loadCalibration(),
    ]);
  }

  Future<void> _loadThresholds() async {
    final profile = await _databaseService.getActiveProfile();
    if (mounted && profile != null) {
      setState(() {
        _thresholdProfile = profile;
      });
    }
  }

  Future<void> _loadCalibration() async {
    final calibration =
        await _databaseService.getSensorCalibration(_sensorType);
    if (mounted) {
      setState(() {
        _sensorCalibration =
            calibration ?? SensorCalibration.defaultCalibration(_sensorType);
      });
    }
  }

  Future<void> _loadAlertSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final sensorName = widget.sensor['name'] as String;

    if (mounted) {
      setState(() {
        _alertsEnabled = prefs.getBool('${sensorName}_alertsEnabled') ?? true;
        _emailNotifications =
            prefs.getBool('${sensorName}_emailNotifications') ?? false;
        _smsNotifications =
            prefs.getBool('${sensorName}_smsNotifications') ?? true;
      });
    }
  }

  Future<void> _saveAlertSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final sensorName = widget.sensor['name'] as String;
    await prefs.setBool('${sensorName}_$key', value);
  }

  Future<void> _saveCalibration(double offset) async {
    final now = DateTime.now();
    final nextDue = now.add(const Duration(days: 30));

    final calibration = SensorCalibration(
      sensorType: _sensorType,
      offset: offset,
      lastCalibrated: now,
      nextCalibrationDue: nextDue,
      calibrationIntervalDays: 30,
    );

    // Save to SQLite
    await _databaseService.saveSensorCalibration(calibration);

    // Update local state
    if (mounted) {
      setState(() {
        _sensorCalibration = calibration;
      });
    }

    // Refresh global calibration in SensorViewModel
    if (mounted) {
      final sensorViewModel =
          Provider.of<SensorViewModel>(context, listen: false);
      await sensorViewModel.refreshCalibration();
    }
  }

  double _getCalibratedValue() {
    return widget.sensor['value'] + _calibrationOffset;
  }

  String _updateSensorStatus() {
    final calibratedValue = _getCalibratedValue();
    if (calibratedValue < _minThreshold * 0.9 ||
        calibratedValue > _maxThreshold * 1.1) {
      return 'critical';
    } else if (calibratedValue < _minThreshold ||
        calibratedValue > _maxThreshold) {
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
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                color: Theme.of(context).brightness == Brightness.light
                    ? AppTheme.primaryColor
                    : AppTheme.darkPrimaryColor,
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
                      '${_minThreshold.toStringAsFixed(1)} ${widget.sensor['unit']}',
                      Icons.arrow_downward,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Max Range',
                      '${_maxThreshold.toStringAsFixed(1)} ${widget.sensor['unit']}',
                      Icons.arrow_upward,
                      Colors.purple,
                    ),
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
                            '${_calibrationOffset.toStringAsFixed(2)} ${widget.sensor['unit']}',
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
      text: _calibrationOffset.toString(),
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
                    min: _minThreshold,
                    max: _maxThreshold,
                    sensorMin: _minThreshold,
                    sensorMax: _maxThreshold,
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final inputValue = double.parse(calibrationController.text);

                // Save to SQLite
                await _saveCalibration(inputValue);

                // Update local sensor data for immediate UI feedback
                setState(() {
                  widget.sensor['status'] = _updateSensorStatus();
                });

                if (!context.mounted) return;
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
    final status = _updateSensorStatus();
    final min = _minThreshold.toStringAsFixed(1);
    final max = _maxThreshold.toStringAsFixed(1);

    await tts.speak(
      "$name is currently $value $unit. Status: $status . Acceptable range is between $min and $max $unit.",
    );
  }
}
