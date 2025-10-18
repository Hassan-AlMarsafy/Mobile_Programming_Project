import 'package:flutter/material.dart';

void main() {
  runApp(const SmartHydroponicApp());
}

class SmartHydroponicApp extends StatelessWidget {
  const SmartHydroponicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMART Hydroponic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}

// ------------------ Routes ------------------
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgot = '/forgot';
  static const dashboard = '/dashboard';
  static const sensor = '/sensor';
  static const control = '/control';
  static const analytics = '/analytics';
  static const settings = '/settings';
  static const alerts = '/alerts';

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    forgot: (_) => const ForgotPasswordScreen(),
    dashboard: (_) => const DashboardScreen(),
    sensor: (_) => const SensorScreen(),
    control: (_) => const ControlScreen(),
    analytics: (_) => const AnalyticsScreen(),
    settings: (_) => const SettingsScreen(),
    alerts: (_) => const AlertsScreen(),
  };
}

// ------------------ Theme ------------------
class AppTheme {
  static final lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
    scaffoldBackgroundColor: Colors.grey[50],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    cardTheme: const CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      elevation: 2,
    ),
  );
}

// ------------------ Screens ------------------

// Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate a loading delay then navigate
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Placeholder for app logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('SH',
                    style: TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('SMART Hydroponic',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // Placeholder: navigate to dashboard
                Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.forgot),
              child: const Text('Forgot Password?'),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?"),
                TextButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.register), child: const Text('Register'))
              ],
            )
          ],
        ),
      ),
    );
  }
}

// Register Screen
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 12),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Create Account')),
          ],
        ),
      ),
    );
  }
}

// Forgot Password Screen
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _emailCtrl = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Enter your email to receive password reset instructions.'),
            const SizedBox(height: 12),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Send Reset Email'))
          ],
        ),
      ),
    );
  }
}

// Dashboard Screen
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.alerts), icon: const Icon(Icons.notifications)),
          IconButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.settings), icon: const Icon(Icons.settings)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.control),
        child: const Icon(Icons.power_settings_new),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: StatusCard(title: 'Mode', value: 'Automatic', icon: Icons.auto_awesome)),
                const SizedBox(width: 8),
                Expanded(child: StatusCard(title: 'Uptime', value: '2h 14m', icon: Icons.timer)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Live Sensors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: const [
                  SensorCard(title: 'Temperature', value: '25°C', status: SensorStatus.normal),
                  SensorCard(title: 'pH', value: '6.2', status: SensorStatus.warning),
                  SensorCard(title: 'Water Level', value: 'Critical', status: SensorStatus.critical),
                  SensorCard(title: 'Light', value: '800 lx', status: SensorStatus.normal),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.analytics),
                    icon: const Icon(Icons.show_chart),
                    label: const Text('View Analytics'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.sensor),
                    icon: const Icon(Icons.sensors),
                    label: const Text('Sensors'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// Sensor Screen
class SensorScreen extends StatelessWidget {
  const SensorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Monitoring')),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          const Text('Sensors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const SensorDetailTile(title: 'Temperature', value: '25°C', lastUpdated: '10:15 AM', status: SensorStatus.normal),
          const SensorDetailTile(title: 'pH', value: '6.2', lastUpdated: '10:14 AM', status: SensorStatus.warning),
          const SensorDetailTile(title: 'Water Level', value: 'Normal', lastUpdated: '10:10 AM', status: SensorStatus.normal),
          const SensorDetailTile(title: 'TDS', value: '450 ppm', lastUpdated: '10:12 AM', status: SensorStatus.normal),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () {}, child: const Text('Calibrate Sensors')),
        ],
      ),
    );
  }
}

// Control Screen
class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control Panel')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Manual Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ControlButton(label: 'Water Pump', icon: Icons.water, onTap: () {}),
            const SizedBox(height: 8),
            ControlButton(label: 'Grow Lights', icon: Icons.lightbulb, onTap: () {}),
            const SizedBox(height: 8),
            ControlButton(label: 'Cooling Fan', icon: Icons.ac_unit, onTap: () {}),
            const SizedBox(height: 16),
            const Text('Schedules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: const Text('Daily Lighting Schedule'),
                subtitle: const Text('06:00 - 18:00'),
                trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () {}, child: const Text('Emergency Stop')),
          ],
        ),
      ),
    );
  }
}

// Analytics Screen
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics & History')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Last 7 days Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const ChartPlaceholder(height: 180),
            const SizedBox(height: 12),
            const Text('Export', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.file_download), label: const Text('Export CSV')),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(title: Text('2025-10-10 09:12'), subtitle: Text('Temperature spike: 30°C')),
                  ListTile(title: Text('2025-10-09 14:01'), subtitle: Text('Low water level detected')),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Settings Screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          const ListTile(title: Text('Sensor Thresholds'), subtitle: Text('Configure critical thresholds')),
          const ListTile(title: Text('Notifications'), subtitle: Text('Manage push and SMS alerts')),
          const ListTile(title: Text('Speech'), subtitle: Text('Text-to-speech & voice control settings')),
          const ListTile(title: Text('User Profile'), subtitle: Text('Account details')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () {}, child: const Text('Save Settings')),
        ],
      ),
    );
  }
}

// Alerts Screen
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts & Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          const Text('Active Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: const Text('pH out of range'),
              subtitle: const Text('pH 6.2 - check nutrient solution'),
              trailing: ElevatedButton(onPressed: () {}, child: const Text('Acknowledge')),
            ),
          ),
          const SizedBox(height: 8),
          const Text('History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const ListTile(title: Text('2025-10-09 14:01'), subtitle: Text('Low water level - acknowledged')),
          const ListTile(title: Text('2025-10-08 12:20'), subtitle: Text('Temperature high - acknowledged')),
        ],
      ),
    );
  }
}

// ------------------ Reusable Widgets ------------------

class StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const StatusCard({super.key, required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.green[100], child: Icon(icon, color: Colors.green[800])),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

enum SensorStatus { normal, warning, critical }

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final SensorStatus status;
  const SensorCard({super.key, required this.title, required this.value, required this.status});

  Color _statusColor() {
    switch (status) {
      case SensorStatus.normal:
        return Colors.green;
      case SensorStatus.warning:
        return Colors.orange;
      case SensorStatus.critical:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Icon(Icons.circle, color: _statusColor(), size: 14),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Last: 10:15', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class SensorDetailTile extends StatelessWidget {
  final String title;
  final String value;
  final String lastUpdated;
  final SensorStatus status;
  const SensorDetailTile({super.key, required this.title, required this.value, required this.lastUpdated, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case SensorStatus.normal:
        color = Colors.green;
        break;
      case SensorStatus.warning:
        color = Colors.orange;
        break;
      case SensorStatus.critical:
        color = Colors.red;
        break;
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(Icons.sensors, color: color)),
        title: Text(title),
        subtitle: Text('Value: $value • Updated: $lastUpdated'),
        trailing: IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
      ),
    );
  }
}

class ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const ControlButton({super.key, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.green[50], child: Icon(icon, color: Colors.green[700])),
        title: Text(label),
        trailing: ElevatedButton(onPressed: onTap, child: const Text('Toggle')),
      ),
    );
  }
}

class ChartPlaceholder extends StatelessWidget {
  final double height;
  const ChartPlaceholder({super.key, this.height = 150});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: height,
        child: const Center(child: Text('Chart placeholder')),
      ),
    );
  }
}

