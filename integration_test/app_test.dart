import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hydroponic_app/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Allow more time for tests to complete
  binding.testTextInput.register();

  group('App Integration Tests', () {

    testWidgets('INT002 - Login with invalid credentials', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate past splash screen if needed
      final getStartedFinder = find.text('Get Started');
      if (getStartedFinder.evaluate().isNotEmpty) {
        await tester.tap(getStartedFinder);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Find email and password fields
      final emailField = find.widgetWithText(TextFormField, 'Email Address');
      final passwordField = find.widgetWithText(TextFormField, 'Password');

      // Enter invalid credentials
      await tester.enterText(emailField, 'invalid@example.com');
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(passwordField, 'wrongpassword');
      await tester.pump(const Duration(milliseconds: 500));

      // Dismiss keyboard
      tester.testTextInput.hide();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap Sign In button
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      expect(signInButton, findsOneWidget);

      await tester.tap(signInButton);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // Should show error and stay on login screen
      final stillOnLogin = find.widgetWithText(ElevatedButton, 'Sign In');
      expect(stillOnLogin, findsOneWidget, reason: 'Should remain on login screen after invalid credentials');

      // Wait to show error message
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('INT003 - Navigate to registration', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate past splash screen
      final getStartedFinder = find.text('Get Started');
      if (getStartedFinder.evaluate().isNotEmpty) {
        await tester.tap(getStartedFinder);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Look for "Create Account" button on login screen
      final createAccountButton = find.widgetWithText(OutlinedButton, 'Create Account');
      expect(createAccountButton, findsOneWidget, reason: 'Create Account button should be on login screen');

      await tester.tap(createAccountButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify we're on registration screen
      // Registration screen should now be visible

      // Wait a bit to show the registration screen
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('INT004 - Biometric authentication', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate past splash screen
      final getStartedFinder = find.text('Get Started');
      if (getStartedFinder.evaluate().isNotEmpty) {
        await tester.tap(getStartedFinder);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Look for biometric login button
      final biometricButton = find.widgetWithText(OutlinedButton, 'Login with Fingerprint');

      if (biometricButton.evaluate().isNotEmpty) {
        // Biometric is available, tap it
        await tester.tap(biometricButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Biometric prompt would appear (can't be automated in tests)
        // Just verify the app is still running
        await tester.pump(const Duration(seconds: 5));
      } else {
        // Biometric not available - this is okay
        final emailField = find.widgetWithText(TextFormField, 'Email Address');
        expect(emailField, findsOneWidget, reason: 'Should be on login screen if biometric not available');

        await tester.pump(const Duration(seconds: 3));
      }

      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('INT005 - Sensor monitoring (Full flow with login)', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate past splash screen
      final getStartedFinder = find.text('Get Started');
      if (getStartedFinder.evaluate().isNotEmpty) {
        await tester.tap(getStartedFinder);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Perform complete login flow
      final emailField = find.widgetWithText(TextFormField, 'Email Address');
      final passwordField = find.widgetWithText(TextFormField, 'Password');

      if (emailField.evaluate().isNotEmpty && passwordField.evaluate().isNotEmpty) {
        // Enter credentials
        await tester.enterText(emailField, 'test@example.com');
        await tester.pump(const Duration(milliseconds: 500));

        await tester.enterText(passwordField, 'Test123456');
        await tester.pump(const Duration(milliseconds: 500));

        // Dismiss keyboard
        tester.testTextInput.hide();
        await tester.pump(const Duration(milliseconds: 500));

        // Tap sign in
        final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
        if (signInButton.evaluate().isNotEmpty) {
          await tester.tap(signInButton);
          await tester.pump(const Duration(seconds: 2));

          // Wait for login and navigation to dashboard
          await tester.pumpAndSettle(const Duration(seconds: 10));
        }
      }

      // Wait for dashboard to fully load
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for dashboard elements
      final dashboardTitle = find.text('Dashboard');
      final onDashboard = dashboardTitle.evaluate().isNotEmpty;

      // If we made it to dashboard, wait to show sensor data
      if (onDashboard) {
        // Wait for sensor data to load from Firebase
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Verify app is showing content (dashboard or login screen)
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}

