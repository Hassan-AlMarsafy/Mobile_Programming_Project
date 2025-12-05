import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'viewmodels/simulator_viewmodel.dart';
import 'screens/simulator_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SimulatorViewModel(),
      child: MaterialApp(
        title: 'Sensor Dashboard Simulator',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.purple, useMaterial3: true),
        home: const SimulatorScreen(),
      ),
    );
  }
}
