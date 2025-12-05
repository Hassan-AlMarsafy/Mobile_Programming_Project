import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tts_service.dart';
import '../viewmodels/settings_viewmodel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
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
                            child: Icon(Icons.person, size: 50, color: Colors.green[700]),
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
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
                              onChanged: (val) => setState(() => _notificationsEnabled = val),
                              iconColor: Colors.orange,
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildSwitchTile(
                              icon: Icons.water_drop,
                              title: 'Auto Watering',
                              subtitle: 'Automatically water plants',
                              value: _autoWatering,
                              onChanged: (val) => setState(() => _autoWatering = val),
                              iconColor: Colors.blue,
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildSwitchTile(
                              icon: Icons.fingerprint,
                              title: 'Biometric Authentication',
                              subtitle: 'Use fingerprint or face ID',
                              value: _biometricAuth,
                              onChanged: (val) => setState(() => _biometricAuth = val),
                              iconColor: Colors.purple,
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildSwitchTile(
                              icon: Icons.dark_mode,
                              title: 'Dark Mode',
                              subtitle: 'Enable dark theme',
                              value: _darkMode,
                              onChanged: (val) => setState(() => _darkMode = val),
                              iconColor: Colors.indigo,
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            Consumer<SettingsViewModel>(
                              builder: (context, settings, _) => _buildSwitchTile(
                                icon: Icons.volume_up,
                                title: 'Text-to-Speech',
                                subtitle: 'Enable voice announcements',
                                value: settings.ttsEnabled,
                                onChanged: (val) => settings.setTtsEnabled(val),
                                iconColor: Colors.deepPurple,
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
                              onTap: () => _showSnackBar('Watering schedule settings'),
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
                              onTap: () => _showSnackBar('Opening privacy policy'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: 'John Doe',
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: 'john.doe@example.com',
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Profile updated successfully');
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
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
                      "Hello, this is your Smart Hydroponic system speaking. All sensors are functioning normally."
                    );
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
