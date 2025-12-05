import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      // Remove the 'home' property and use initialRoute instead
      initialRoute: '/splash', // Start with splash screen
      routes: AppRoutes.routes,
    );
  }
}

// ------------------ Routes ------------------
class AppRoutes {
  static const splash = '/splash';
  static const auth = '/auth'; // New route for auth wrapper
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
    auth: (_) => const AuthWrapper(), // Auth wrapper route
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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize auth state
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    await authViewModel.initialize();

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    if (!_initialized) {
      // Show a loading screen while checking auth
      return Scaffold(
        backgroundColor: const Color(0xFFF8FFFE),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.green[700]!,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Checking authentication...',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If user is logged in, go to dashboard
    if (authViewModel.isLoggedIn) {
      return const DashboardScreen();
    } else {
      // If not logged in, go to login screen
      return const LoginScreen();
    }
  }
}