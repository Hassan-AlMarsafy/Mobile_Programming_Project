import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hydroponic_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/validators.dart';
import '../services/firestore_service.dart';
import '../services/biometric_service.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../models/sensor_thresholds.dart';
import '../models/sensor_calibration.dart';
import '../models/user.dart';
import 'notification_settings_screen.dart';
import 'watering_schedule_screen.dart';
import '../services/tts_service.dart';
import '../viewmodels/settings_viewmodel.dart';

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
  final BiometricService _biometricService = BiometricService();
  SensorThresholds _thresholds = SensorThresholds.defaultThresholds();
  SystemCalibration _calibration = SystemCalibration.defaultCalibration();
  UserProfile? _userProfile;
  bool _isLoadingThresholds = true;
  bool _isLoadingCalibration = true;
  bool _isLoadingProfile = true;

  bool _notificationsEnabled = true;
  bool _autoWatering = true;
  bool _biometricAuth = false;
  bool _biometricAvailable = false;
  String _biometricType = 'Biometric';
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

    // Check biometric availability
    _checkBiometricAvailability();

    // Monitor auth state
    firebase_auth.FirebaseAuth.instance
        .authStateChanges()
        .listen((firebase_auth.User? user) {
      if (user != null && mounted) {
        _loadThresholds();
        _loadCalibration();
        _loadUserProfile();
      }
    });

    _loadThresholds();
    _loadCalibration();
    _loadUserProfile();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _biometricService.isBiometricAvailable();
    if (available) {
      final typeName = await _biometricService.getBiometricTypeName();
      setState(() {
        _biometricAvailable = true;
        _biometricType = typeName;
      });
    } else {
      setState(() {
        _biometricAvailable = false;
      });
    }
  }

  Future<void> _loadThresholds() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;

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

  Future<void> _loadCalibration() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;

    if (user != null) {
      final calibration =
          await _firestoreService.getSystemCalibration(user.uid);
      if (calibration != null) {
        setState(() {
          _calibration = calibration;
          _isLoadingCalibration = false;
        });
      } else {
        setState(() {
          _isLoadingCalibration = false;
        });
      }
    } else {
      setState(() {
        _isLoadingCalibration = false;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Try to load from Firestore first
      var profile = await _firestoreService.getUserProfile(user.uid);

      // If no profile exists in Firestore, create one from Firebase Auth
      if (profile == null) {
        profile = UserProfile.fromFirebaseUser(user);
        await _firestoreService.createUserProfile(profile);
      }

      setState(() {
        _userProfile = profile;
        _isLoadingProfile = false;
        // Load settings from profile
        _notificationsEnabled = profile!.notificationsEnabled;
        _autoWatering = profile.autoWatering;
        _biometricAuth = profile.biometricEnabled;
        _temperatureUnit = profile.temperatureUnit;
        _language = profile.language;
      });
    } else {
      setState(() {
        _isLoadingProfile = false;
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
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppTheme.darkPrimaryColor
                                    : AppTheme.primaryColor,
                                width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.white
                                    : AppTheme.primaryColor,
                            child: Icon(Icons.person,
                                size: 50,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppTheme.darkPrimaryColor
                                    : AppTheme.primaryColor),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _isLoadingProfile
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.onPrimary),
                                ),
                              )
                            : Text(
                                _userProfile?.displayName ?? 'User',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.white
                                      : AppTheme.primaryColor,
                                ),
                              ),
                        const SizedBox(height: 4),
                        _isLoadingProfile
                            ? const SizedBox.shrink()
                            : Text(
                                _userProfile?.email ?? 'user@example.com',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.white
                                      : AppTheme.primaryColor,
                                ),
                              ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _showEditProfileDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.white
                                    : AppTheme.primaryColor,
                            foregroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black
                                    : AppTheme.primaryColor,
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
                      Text(
                        'System Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
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
                            _buildNotificationTile(),
                            Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
                            _buildWateringTile(),
                            Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
                            _buildBiometricTile(),
                            Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
                            Consumer<ThemeViewModel>(
                              builder: (context, themeViewModel, child) {
                                return _buildSwitchTile(
                                  icon: Icons.dark_mode,
                                  title: 'Dark Mode',
                                  subtitle: 'Enable dark theme',
                                  value: themeViewModel.isDarkMode,
                                  onChanged: (val) =>
                                      themeViewModel.setThemeMode(val),
                                  iconColor: Colors.indigo,
                                );
                              },
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
                          Text(
                            'Sensor Thresholds',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          if (_isLoadingThresholds)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary),
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
                            Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
                            _buildNavigationTile(
                              icon: Icons.water_drop,
                              title: 'Water Level',
                              subtitle:
                                  'Min: ${_thresholds.waterLevelMin}%, Critical: ${_thresholds.waterLevelCritical}%',
                              iconColor: Colors.blue,
                              onTap: () => _showWaterLevelThresholdDialog(),
                            ),
                            Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
                            _buildNavigationTile(
                              icon: Icons.science,
                              title: 'pH Level',
                              subtitle:
                                  '${_thresholds.phMin} - ${_thresholds.phMax}',
                              iconColor: Colors.purple,
                              onTap: () => _showPhThresholdDialog(),
                            ),
                            Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
                            _buildNavigationTile(
                              icon: Icons.opacity,
                              title: 'TDS/EC Level',
                              subtitle:
                                  '${_thresholds.tdsMin} - ${_thresholds.tdsMax} ppm',
                              iconColor: Colors.amber,
                              onTap: () => _showTdsThresholdDialog(),
                            ),
                            Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
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

                // System Calibration Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'System Calibration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          if (_isLoadingCalibration)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (_calibration.hasCalibrationDue)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_calibration.calibrationDueCount} due',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[900],
                                ),
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
                            _buildCalibrationTile(
                              icon: Icons.thermostat,
                              title: 'Temperature Sensor',
                              sensorType: 'temperature',
                              calibration:
                                  _calibration.getSensor('temperature'),
                              iconColor: Colors.red,
                            ),
                            Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
                            _buildCalibrationTile(
                              icon: Icons.water_drop,
                              title: 'Water Level Sensor',
                              sensorType: 'waterLevel',
                              calibration: _calibration.getSensor('waterLevel'),
                              iconColor: Colors.blue,
                            ),
                            Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
                            _buildCalibrationTile(
                              icon: Icons.science,
                              title: 'pH Sensor',
                              sensorType: 'ph',
                              calibration: _calibration.getSensor('ph'),
                              iconColor: Colors.purple,
                            ),
                            Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
                            _buildCalibrationTile(
                              icon: Icons.opacity,
                              title: 'TDS/EC Sensor',
                              sensorType: 'tds',
                              calibration: _calibration.getSensor('tds'),
                              iconColor: Colors.amber,
                            ),
                            Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
                            _buildCalibrationTile(
                              icon: Icons.wb_sunny,
                              title: 'Light Sensor',
                              sensorType: 'light',
                              calibration: _calibration.getSensor('light'),
                              iconColor: Colors.orange,
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            Consumer<SettingsViewModel>(
                              builder: (context, settings, _) =>
                                  _buildSwitchTile(
                                icon: Icons.volume_up,
                                title: 'Text-to-Speech',
                                subtitle: 'Enable voice announcements',
                                value: settings.ttsEnabled,
                                onChanged: (val) => settings.setTtsEnabled(val),
                                iconColor: Colors.deepPurple,
                              ),
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            Consumer<SettingsViewModel>(
                              builder: (context, settings, _) =>
                                  _buildSwitchTile(
                                icon: Icons.mic,
                                title: 'Speech Recognition',
                                subtitle: 'Enable voice commands',
                                value: settings.srEnabled,
                                onChanged: (val) => settings.setSrEnabled(val),
                                iconColor: Colors.red,
                              ),
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
                      Text(
                        'Preferences',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
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
                            Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
                            _buildNavigationTile(
                              icon: Icons.language,
                              title: 'Language',
                              subtitle: _language,
                              iconColor: Colors.teal,
                              onTap: () => _showLanguageDialog(),
                            ),
                            Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
                            _buildNavigationTile(
                              icon: Icons.volume_up,
                              title: 'Voice Settings',
                              subtitle: 'Test text-to-speech',
                              iconColor: Colors.deepPurple,
                              onTap: () => _showTtsDialog(),
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
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildThresholdProfilesTile(),
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
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
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
                            Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
                            _buildNavigationTile(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Privacy Policy',
                              subtitle: 'Read our privacy policy',
                              iconColor: Colors.blueGrey,
                              onTap: () =>
                                  _showSnackBar('Opening privacy policy'),
                            ),
                            Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
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
                      Text(
                        'Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
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
                              onTap: _showChangePasswordDialog,
                            ),
                            Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
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

  Widget _buildNotificationTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.notifications_active,
            color: Colors.orange, size: 24),
      ),
      title: const Text(
        'Push Notifications',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Receive alerts and updates',
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.settings),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          Switch(
            value: _notificationsEnabled,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
              _saveNotificationsSetting(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdProfilesTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.tune, color: Colors.green, size: 24),
      ),
      title: const Text(
        'Threshold Profiles',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Manage sensor thresholds for different crops',
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.pushNamed(context, '/threshold-profiles'),
    );
  }

  Widget _buildWateringTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.water_drop, color: Colors.blue, size: 24),
      ),
      title: const Text(
        'Auto Watering',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Automatically water plants',
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.schedule),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WateringScheduleScreen(),
                ),
              );
            },
          ),
          Switch(
            value: _autoWatering,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) {
              setState(() => _autoWatering = val);
              _saveAutoWateringSetting(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.fingerprint, color: Colors.purple, size: 24),
      ),
      title: Text(
        _biometricType,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _biometricAvailable
            ? 'Secure app with biometric authentication'
            : 'Not available on this device',
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: Switch(
        value: _biometricAuth,
        activeColor: Theme.of(context).colorScheme.primary,
        onChanged: _biometricAvailable
            ? (val) async {
                if (val) {
                  // Authenticate before enabling
                  final result =
                      await _biometricService.authenticateWithDetails(
                          reason: 'Authenticate to enable $_biometricType');

                  if (result['success']) {
                    setState(() => _biometricAuth = true);
                    await _saveBiometricSetting(true);
                  } else {
                    final error = result['error'] as String? ?? 'Unknown error';
                    _showSnackBar(error);
                  }
                } else {
                  setState(() => _biometricAuth = false);
                  await _saveBiometricSetting(false);
                }
              }
            : null,
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
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
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
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: Icon(Icons.chevron_right,
          color: Theme.of(context).textTheme.bodySmall?.color),
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
                _saveTemperatureUnit(value!);
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
                _saveTemperatureUnit(value!);
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
                _saveLanguage(value!);
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
                _saveLanguage(value!);
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
                _saveLanguage(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    if (_userProfile == null) {
      _showSnackBar('Profile not loaded yet');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: _userProfile!.displayName,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  validator: Validators.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                            ),
                            Text(
                              _userProfile!.email,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Note: Email cannot be changed here',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Get values before closing dialog
                final newDisplayName = nameController.text.trim();

                // Close dialog first
                Navigator.pop(context);

                // Now create and save profile
                final updatedProfile = _userProfile!.copyWith(
                  displayName: newDisplayName,
                  lastUpdated: DateTime.now(),
                );

                await _saveUserProfile(updatedProfile);
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

  Future<void> _saveUserProfile(UserProfile profile) async {
    try {
      final result = await _firestoreService.saveUserProfile(profile);

      if (result['success'] == true) {
        setState(() {
          _userProfile = profile;
        });

        // Also update Firebase Auth display name
        final user = firebase_auth.FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updateDisplayName(profile.displayName);
        }

        _showSnackBar(result['message']);
      } else {
        _showSnackBar(result['message']);
      }
    } catch (e) {
      _showSnackBar('Failed to update profile');
    }
  }

  void _showChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrentPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your current password';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrentPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureCurrentPassword = !obscureCurrentPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: obscureNewPassword,
                    validator: Validators.password,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureNewPassword = !obscureNewPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirmPassword,
                    validator: (value) {
                      if (value != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureConfirmPassword = !obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Password must be at least 6 characters long',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final currentPassword = currentPasswordController.text;
                  final newPassword = newPasswordController.text;

                  Navigator.pop(context);

                  await _changePassword(currentPassword, newPassword);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
              child: const Text('Update Password',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword(
      String currentPassword, String newPassword) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;

      if (user == null || user.email == null) {
        _showSnackBar('User not authenticated');
        return;
      }

      // Re-authenticate user with current password
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update to new password
      await user.updatePassword(newPassword);

      _showSnackBar('Password updated successfully');
    } on firebase_auth.FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Current password is incorrect';
          break;
        case 'weak-password':
          errorMessage = 'New password is too weak';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please sign out and sign in again to change password';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Check your internet connection';
          break;
        default:
          errorMessage = 'Failed to update password: ${e.message}';
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar('Failed to update password');
    }
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
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 12),
            Text(
              '© 2025 SMART Hydroponic Team',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
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
            onPressed: () async {
              Navigator.pop(context);
              try {
                await firebase_auth.FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sign out failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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

  // ============ SETTINGS PERSISTENCE ============

  Future<void> _saveNotificationsSetting(bool value) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null || _userProfile == null) return;

    try {
      final updatedProfile = _userProfile!.copyWith(
        notificationsEnabled: value,
        lastUpdated: DateTime.now(),
      );

      await _firestoreService.saveUserProfile(updatedProfile);

      setState(() {
        _userProfile = updatedProfile;
      });
    } catch (e) {
      _showSnackBar('Failed to save notification setting');
    }
  }

  Future<void> _saveAutoWateringSetting(bool value) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null || _userProfile == null) return;

    try {
      final updatedProfile = _userProfile!.copyWith(
        autoWatering: value,
        lastUpdated: DateTime.now(),
      );

      await _firestoreService.saveUserProfile(updatedProfile);

      setState(() {
        _userProfile = updatedProfile;
      });
    } catch (e) {
      _showSnackBar('Failed to save auto watering setting');
    }
  }

  Future<void> _saveBiometricSetting(bool value) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null || _userProfile == null) return;

    try {
      if (value) {
        // When enabling, prompt for password to save securely
        final password = await _showPasswordDialog();
        if (password == null || password.isEmpty) {
          _showSnackBar('Password required to enable biometric login');
          return;
        }

        // Verify the password by attempting to re-authenticate
        try {
          final credential = firebase_auth.EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );
          await user.reauthenticateWithCredential(credential);

          // Password is correct, save it securely
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('biometric_email', user.email!);
          await prefs.setString('biometric_password', password);
        } catch (e) {
          _showSnackBar('Incorrect password');
          return;
        }
      } else {
        // When disabling, remove saved credentials
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('biometric_email');
        await prefs.remove('biometric_password');
      }

      // Save to SharedPreferences (local)
      await _biometricService.setBiometricEnabled(value);

      // Save to Firebase (cloud)
      final updatedProfile = _userProfile!.copyWith(
        biometricEnabled: value,
        lastUpdated: DateTime.now(),
      );

      await _firestoreService.saveUserProfile(updatedProfile);

      setState(() {
        _userProfile = updatedProfile;
      });

      _showSnackBar(value
          ? '$_biometricType enabled - You can now login with fingerprint'
          : '$_biometricType disabled');
    } catch (e) {
      _showSnackBar('Failed to save biometric setting');
    }
  }

  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your password to enable biometric login'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTemperatureUnit(String value) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null || _userProfile == null) return;

    try {
      final updatedProfile = _userProfile!.copyWith(
        temperatureUnit: value,
        lastUpdated: DateTime.now(),
      );

      await _firestoreService.saveUserProfile(updatedProfile);

      setState(() {
        _userProfile = updatedProfile;
      });
    } catch (e) {
      _showSnackBar('Failed to save temperature unit');
    }
  }

  Future<void> _saveLanguage(String value) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null || _userProfile == null) return;

    try {
      final updatedProfile = _userProfile!.copyWith(
        language: value,
        lastUpdated: DateTime.now(),
      );

      await _firestoreService.saveUserProfile(updatedProfile);

      setState(() {
        _userProfile = updatedProfile;
      });
    } catch (e) {
      _showSnackBar('Failed to save language setting');
    }
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
    final user = firebase_auth.FirebaseAuth.instance.currentUser;

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

  // ============ CALIBRATION METHODS ============

  Widget _buildCalibrationTile({
    required IconData icon,
    required String title,
    required String sensorType,
    required SensorCalibration? calibration,
    required Color iconColor,
  }) {
    if (calibration == null) return const SizedBox.shrink();

    final lastCalibrated = calibration.lastCalibrated;
    final String subtitle = lastCalibrated != null
        ? 'Last: ${DateFormat('MMM d, yyyy').format(lastCalibrated)}'
        : 'Never calibrated';

    final Color statusColor = calibration.isCalibrationDue
        ? Colors.red
        : calibration.isCalibrationApproaching
            ? Colors.orange
            : Colors.green;

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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                calibration.calibrationStatus,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
        onPressed: () => _showSensorCalibrationDialog(sensorType, calibration),
      ),
    );
  }

  void _showSensorCalibrationDialog(
    String sensorType,
    SensorCalibration calibration,
  ) {
    final offsetController =
        TextEditingController(text: calibration.offset.toString());
    final intervalController = TextEditingController(
      text: calibration.calibrationIntervalDays.toString(),
    );
    final formKey = GlobalKey<FormState>();

    // Sensor display names and units
    final sensorNames = {
      'temperature': {'name': 'Temperature', 'unit': '°C'},
      'waterLevel': {'name': 'Water Level', 'unit': '%'},
      'ph': {'name': 'pH', 'unit': ''},
      'tds': {'name': 'TDS/EC', 'unit': 'ppm'},
      'light': {'name': 'Light', 'unit': 'lux'},
    };

    final sensorInfo = sensorNames[sensorType]!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Calibrate ${sensorInfo['name']} Sensor'),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: offsetController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Calibration Offset',
                    hintText: 'Enter offset value',
                    suffixText: sensorInfo['unit'],
                    prefixIcon: const Icon(Icons.tune),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    helperText: 'Positive or negative adjustment value',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: intervalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Calibration Interval',
                    hintText: 'Days between calibrations',
                    suffixText: 'days',
                    prefixIcon: const Icon(Icons.event),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    helperText: 'How often to calibrate this sensor',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    final num = int.tryParse(value);
                    if (num == null || num < 1) {
                      return 'Must be at least 1 day';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                          'Changes will be saved to your profile',
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final offset = double.parse(offsetController.text);
                final interval = int.parse(intervalController.text);
                final now = DateTime.now();

                final updatedCalibration = calibration.copyWith(
                  offset: offset,
                  calibrationIntervalDays: interval,
                  lastCalibrated: now,
                  nextCalibrationDue: now.add(Duration(days: interval)),
                );

                await _saveCalibration(sensorType, updatedCalibration);
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

  Future<void> _saveCalibration(
    String sensorType,
    SensorCalibration calibration,
  ) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnackBar('Not signed in. Please log in first.');
      return;
    }

    try {
      final updatedSystem = _calibration.updateSensor(sensorType, calibration);
      final result = await _firestoreService.saveSystemCalibration(
          user.uid, updatedSystem);

      if (result['success'] == true) {
        setState(() {
          _calibration = updatedSystem;
        });
        _showSnackBar(result['message']);
      } else {
        _showSnackBar(result['message']);
      }
    } catch (e) {
      _showSnackBar('Failed to save calibration');
    }
  }

  void _showTtsDialog() {
    final tts = TtsService();
    double speechRate = 0.5;
    double volume = 1.0;
    double pitch = 1.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.volume_up, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text('Voice Settings'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Speech Rate',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: speechRate,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: speechRate.toStringAsFixed(1),
                activeColor: Colors.green[700],
                onChanged: (value) {
                  setDialogState(() => speechRate = value);
                  tts.setSpeechRate(value);
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Volume',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: volume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: volume.toStringAsFixed(1),
                activeColor: Colors.green[700],
                onChanged: (value) {
                  setDialogState(() => volume = value);
                  tts.setVolume(value);
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Pitch',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: pitch,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                label: pitch.toStringAsFixed(1),
                activeColor: Colors.green[700],
                onChanged: (value) {
                  setDialogState(() => pitch = value);
                  tts.setPitch(value);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await tts.speak(
                        "Hello, this is your Smart Hydroponic system speaking. All sensors are functioning normally.");
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Test Voice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                tts.stop();
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
