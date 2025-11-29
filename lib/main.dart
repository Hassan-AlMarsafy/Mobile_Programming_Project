import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/sensor_viewmodel.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sensors/sensors_list_screen.dart';
import 'screens/control_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/alerts_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SensorViewModel()),
      ],
      child: const SmartHydroponicApp(),
    ),
  );
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

// Theme is now centralized in lib/theme/app_theme.dart
// All screens are imported from their respective files
// This follows MVVM architecture and maintains clean separation of concerns

