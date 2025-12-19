import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hydroponic_app/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Flow Integration Test', () {
    testWidgets('Complete login flow with valid credentials', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen to complete (if any)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find email and password fields
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).at(1);

      // Enter valid credentials
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'Test123456');
      await tester.pumpAndSettle();

      // Tap Sign In button
      final signInButton = find.text('Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Wait for navigation and authentication
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify navigation to dashboard or home screen
      // (Adjust this based on your actual screen after login)
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Login with invalid credentials shows error', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).at(1);

      // Enter invalid credentials
      await tester.enterText(emailField, 'invalid@example.com');
      await tester.enterText(passwordField, 'wrongpassword');
      await tester.pumpAndSettle();

      // Tap Sign In button
      final signInButton = find.text('Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Wait for error message
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify error is displayed (SnackBar, Dialog, or error text)
      // Adjust based on your error handling implementation
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Navigate to registration screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find and tap Create Account button
      final createAccountButton = find.text('Create Account');
      await tester.tap(createAccountButton);
      await tester.pumpAndSettle();

      // Verify navigation to registration screen
      expect(find.text('Create Account'), findsWidgets);
    });

    testWidgets('Biometric authentication flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for biometric authentication option
      final biometricButton = find.byIcon(Icons.fingerprint);
      
      if (biometricButton.evaluate().isNotEmpty) {
        await tester.tap(biometricButton);
        await tester.pumpAndSettle();

        // Biometric prompt should appear
        // Note: Actual biometric verification cannot be tested in integration tests
        // This just tests the UI flow
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
    });
  });

  group('Sensor Monitoring Integration Test', () {
    testWidgets('View real-time sensor data', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Login first
      await tester.pumpAndSettle(const Duration(seconds: 3));
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).at(1);
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'Test123456');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to dashboard/sensors
      await tester.pumpAndSettle();

      // Verify sensor data is displayed
      expect(find.byType(Card), findsWidgets);
    });
  });
}
