import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'viewmodels/sensor_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sensors/sensors_list_screen.dart';
import 'screens/control_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/alerts_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SensorViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
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

// Auth Wrapper Widget
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    await authViewModel.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    if (authViewModel.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authViewModel.isLoggedIn) {
      return const DashboardScreen();
    } else {
      return const LoginScreen();
    }
  }
}

// Update your SplashScreen to use AuthWrapper
// or modify your route initialization to use AuthWrapper as the home