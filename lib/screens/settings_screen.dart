import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/validators.dart';
import '../services/firestore_service.dart';
import '../models/sensor_thresholds.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final FirestoreService _firestoreService = FirestoreService();
  SensorThresholds _thresholds = SensorThresholds.defaultThresholds();
  bool _isLoadingThresholds = true;

  bool _notificationsEnabled = true;
  bool _autoWatering = true;
  bool _darkMode = false;
  bool _biometricAuth = false;
  String _temperatureUnit = 'Celsius';
  String _language = 'English';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
    
    // Monitor auth state
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && mounted) {
        _loadThresholds();
      }
    });
    
    _loadThresholds();
  }

  Future<void> _loadThresholds() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      final thresholds = await _firestoreService.getSensorThresholds(user.uid);
      if (thresholds != null) {
        setState(() {
          _thresholds = thresholds;
          _isLoadingThresholds = false;
        });
      } else {
        setState(() {
          _isLoadingThresholds = false;
        });
      }
    } else {
      setState(() {
        _isLoadingThresholds = false;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showSnackBar('Please sign in to save settings');
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person,
                                size: 50, color: Colors.green[700]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'User Name',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'user.name@example.com',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _showEditProfileDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green[700],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // System Settings Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'System Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildSwitchTile(
                              icon: Icons.notifications_active,
                              title: 'Push Notifications',
                              subtitle: 'Receive alerts and updates',
                              value: _notificationsEnabled,
                              onChanged: (val) =>
                                  setState(() => _notificationsEnabled = val),
                              iconColor: Colors.orange,
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildSwitchTile(
                              icon: Icons.water_drop,
                              title: 'Auto Watering',
                              subtitle: 'Automatically water plants',
                              value: _autoWatering,
                              onChanged: (val) =>
                                  setState(() => _autoWatering = val),
                              iconColor: Colors.blue,
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildSwitchTile(
                              icon: Icons.fingerprint,
                              title: 'Biometric Authentication',
                              subtitle: 'Use fingerprint or face ID',
                              value: _biometricAuth,
                              onChanged: (val) =>
                                  setState(() => _biometricAuth = val),
                              iconColor: Colors.purple,
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildSwitchTile(
                              icon: Icons.dark_mode,
                              title: 'Dark Mode',
                              subtitle: 'Enable dark theme',
                              value: _darkMode,
                              onChanged: (val) =>
                                  setState(() => _darkMode = val),
                              iconColor: Colors.indigo,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sensor Thresholds Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sensor Thresholds',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          if (_isLoadingThresholds)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.green[700]!),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildNavigationTile(
                              icon: Icons.thermostat,
                              title: 'Temperature Range',
                              subtitle:
                                  '${_thresholds.temperatureMin}°C - ${_thresholds.temperatureMax}°C',
                              iconColor: Colors.red,
                              onTap: () => _showTemperatureThresholdDialog(),
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildNavigationTile(
                              icon: Icons.water_drop,
                              title: 'Water Level',
                              subtitle:
                                  'Min: ${_thresholds.waterLevelMin}%, Critical: ${_thresholds.waterLevelCritical}%',
                              iconColor: Colors.blue,
                              onTap: () => _showWaterLevelThresholdDialog(),
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildNavigationTile(
                              icon: Icons.science,
                              title: 'pH Level',
                              subtitle:
                                  '${_thresholds.phMin} - ${_thresholds.phMax}',
                              iconColor: Colors.purple,
                              onTap: () => _showPhThresholdDialog(),
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildNavigationTile(
                              icon: Icons.opacity,
                              title: 'TDS/EC Level',
                              subtitle:
                                  '${_thresholds.tdsMin} - ${_thresholds.tdsMax} ppm',
                              iconColor: Colors.amber,
                              onTap: () => _showTdsThresholdDialog(),
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildNavigationTile(
                              icon: Icons.wb_sunny,
                              title: 'Light Intensity',
                              subtitle:
                                  '${_thresholds.lightIntensityMin} - ${_thresholds.lightIntensityMax} lux',
                              iconColor: Colors.orange,
                              onTap: () => _showLightIntensityThresholdDialog(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Preferences Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preferences',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildNavigationTile(
                              icon: Icons.thermostat,
                              title: 'Temperature Unit',
                              subtitle: _temperatureUnit,
                              iconColor: Colors.red,
                              onTap: () => _showTemperatureUnitDialog(),
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildNavigationTile(
                              icon: Icons.language,
                              title: 'Language',
                              subtitle: _language,
                              iconColor: Colors.teal,
                              onTap: () => _showLanguageDialog(),
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildNavigationTile(
                              icon: Icons.schedule,
                              title: 'Watering Schedule',
                              subtitle: 'Configure auto-watering',
                              iconColor: Colors.cyan,
                              onTap: () =>
                                  _showSnackBar('Watering schedule settings'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // App Information Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildNavigationTile(
                              icon: Icons.help_outline,
                              title: 'Help & Support',
                              subtitle: 'Get help with the app',
                              iconColor: Colors.amber,
                              onTap: () => _showSnackBar('Opening help center'),
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildNavigationTile(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Privacy Policy',
                              subtitle: 'Read our privacy policy',
                              iconColor: Colors.blueGrey,
                              onTap: () =>
                                  _showSnackBar('Opening privacy policy'),
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildNavigationTile(
                              icon: Icons.info_outline,
                              title: 'About App',
                              subtitle: 'Version 1.0.0',
                              iconColor: Colors.green,
                              onTap: () => _showAboutDialog(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Account Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildNavigationTile(
                              icon: Icons.lock_reset,
                              title: 'Change Password',
                              subtitle: 'Update your password',
                              iconColor: Colors.deepOrange,
                              onTap: () => _showSnackBar('Change password'),
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildNavigationTile(
                              icon: Icons.logout,
                              title: 'Sign Out',
                              subtitle: 'Logout from your account',
                              iconColor: Colors.red,
                              onTap: () => _showLogoutDialog(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color iconColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green[700],
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  void _showTemperatureUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Temperature Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Celsius (°C)'),
              value: 'Celsius',
              groupValue: _temperatureUnit,
              activeColor: Colors.green[700],
              onChanged: (value) {
                setState(() => _temperatureUnit = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Fahrenheit (°F)'),
              value: 'Fahrenheit',
              groupValue: _temperatureUnit,
              activeColor: Colors.green[700],
              onChanged: (value) {
                setState(() => _temperatureUnit = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _language,
              activeColor: Colors.green[700],
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('العربية'),
              value: 'Arabic',
              groupValue: _language,
              activeColor: Colors.green[700],
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Español'),
              value: 'Spanish',
              groupValue: _language,
              activeColor: Colors.green[700],
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: 'John Doe');
    final emailController = TextEditingController(text: 'john.doe@example.com');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                validator: Validators.name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameController.dispose();
              emailController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                nameController.dispose();
                emailController.dispose();
                Navigator.pop(context);
                _showSnackBar('Profile updated successfully');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About SMART Hydroponic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version: 1.0.0',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'SMART Hydroponic is your complete solution for monitoring and controlling your hydroponic garden system.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Text(
              '© 2025 SMART Hydroponic Team',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.green[700])),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child:
                const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ============ THRESHOLD DIALOGS ============

  void _showTemperatureThresholdDialog() {
    final minController =
        TextEditingController(text: _thresholds.temperatureMin.toString());
    final maxController =
        TextEditingController(text: _thresholds.temperatureMax.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Temperature Range'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Minimum (°C)',
                  prefixIcon: const Icon(Icons.thermostat),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final num = double.tryParse(value);
                  if (num == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Maximum (°C)',
                  prefixIcon: const Icon(Icons.thermostat),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final num = double.tryParse(value);
                  if (num == null) {
                    return 'Invalid number';
                  }
                  final min = double.tryParse(minController.text);
                  if (min != null && num <= min) {
                    return 'Max must be > Min';
                  }
                  return null;
                },
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
              if (formKey.currentState!.validate()) {
                final min = double.parse(minController.text);
                final max = double.parse(maxController.text);
                await _saveThreshold(
                  _thresholds.copyWith(
                    temperatureMin: min,
                    temperatureMax: max,
                    lastUpdated: DateTime.now(),
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showWaterLevelThresholdDialog() {
    final minController =
        TextEditingController(text: _thresholds.waterLevelMin.toString());
    final criticalController =
        TextEditingController(text: _thresholds.waterLevelCritical.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Water Level Thresholds'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Minimum Level (%)',
                  prefixIcon: const Icon(Icons.water_drop),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final num = double.tryParse(value);
                  if (num == null || num < 0 || num > 100) {
                    return 'Enter 0-100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: criticalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Critical Level (%)',
                  prefixIcon: const Icon(Icons.warning_amber),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final num = double.tryParse(value);
                  if (num == null || num < 0 || num > 100) {
                    return 'Enter 0-100';
                  }
                  final min = double.tryParse(minController.text);
                  if (min != null && num >= min) {
                    return 'Critical must be < Min';
                  }
                  return null;
                },
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
              if (formKey.currentState!.validate()) {
                final min = double.parse(minController.text);
                final critical = double.parse(criticalController.text);
                await _saveThreshold(
                  _thresholds.copyWith(
                    waterLevelMin: min,
                    waterLevelCritical: critical,
                    lastUpdated: DateTime.now(),
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPhThresholdDialog() {
    final minController =
        TextEditingController(text: _thresholds.phMin.toString());
    final maxController =
        TextEditingController(text: _thresholds.phMax.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('pH Level Range'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Minimum pH',
                  prefixIcon: const Icon(Icons.science),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final num = double.tryParse(value);
                  if (num == null || num < 0 || num > 14) {
                    return 'pH must be 0-14';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Maximum pH',
                  prefixIcon: const Icon(Icons.science),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final num = double.tryParse(value);
                  if (num == null || num < 0 || num > 14) {
                    return 'pH must be 0-14';
                  }
                  final min = double.tryParse(minController.text);
                  if (min != null && num <= min) {
                    return 'Max must be > Min';
                  }
                  return null;
                },
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
              if (formKey.currentState!.validate()) {
                final min = double.parse(minController.text);
                final max = double.parse(maxController.text);
                await _saveThreshold(
                  _thresholds.copyWith(
                    phMin: min,
                    phMax: max,
                    lastUpdated: DateTime.now(),
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTdsThresholdDialog() {
    final minController =
        TextEditingController(text: _thresholds.tdsMin.toString());
    final maxController =
        TextEditingController(text: _thresholds.tdsMax.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TDS/EC Level Range'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Minimum (ppm)',
                  prefixIcon: const Icon(Icons.opacity),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final num = double.tryParse(value);
                  if (num == null || num < 0) {
                    return 'Must be positive';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Maximum (ppm)',
                  prefixIcon: const Icon(Icons.opacity),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final num = double.tryParse(value);
                  if (num == null || num < 0) {
                    return 'Must be positive';
                  }
                  final min = double.tryParse(minController.text);
                  if (min != null && num <= min) {
                    return 'Max must be > Min';
                  }
                  return null;
                },
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
              if (formKey.currentState!.validate()) {
                final min = double.parse(minController.text);
                final max = double.parse(maxController.text);
                await _saveThreshold(
                  _thresholds.copyWith(
                    tdsMin: min,
                    tdsMax: max,
                    lastUpdated: DateTime.now(),
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLightIntensityThresholdDialog() {
    final minController =
        TextEditingController(text: _thresholds.lightIntensityMin.toString());
    final maxController =
        TextEditingController(text: _thresholds.lightIntensityMax.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Light Intensity Range'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Minimum (lux)',
                  prefixIcon: const Icon(Icons.wb_sunny),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final num = double.tryParse(value);
                  if (num == null || num < 0) {
                    return 'Must be positive';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Maximum (lux)',
                  prefixIcon: const Icon(Icons.wb_sunny),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final num = double.tryParse(value);
                  if (num == null || num < 0) {
                    return 'Must be positive';
                  }
                  final min = double.tryParse(minController.text);
                  if (min != null && num <= min) {
                    return 'Max must be > Min';
                  }
                  return null;
                },
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
              if (formKey.currentState!.validate()) {
                final min = double.parse(minController.text);
                final max = double.parse(maxController.text);
                await _saveThreshold(
                  _thresholds.copyWith(
                    lightIntensityMin: min,
                    lightIntensityMax: max,
                    lastUpdated: DateTime.now(),
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveThreshold(SensorThresholds thresholds) async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      _showSnackBar('Not signed in. Please log in first.');
      return;
    }
    
    try {
      final result = await _firestoreService.saveSensorThresholds(
        user.uid,
        thresholds,
      );
      
      if (result['success'] == true) {
        setState(() {
          _thresholds = thresholds;
        });
        _showSnackBar(result['message']);
      } else {
        _showSnackBar(result['message']);
      }
    } catch (e) {
      _showSnackBar('Failed to save thresholds');
    }
  }
}
