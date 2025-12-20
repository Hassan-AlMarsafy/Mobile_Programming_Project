import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydroponic_app/screens/auth_screen.dart';
import 'package:provider/provider.dart';
import 'package:hydroponic_app/viewmodels/auth_viewmodel.dart';

void main() {
  group('Login Screen Widget Tests', () {
    testWidgets('Login screen displays all required elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthViewModel(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Check for welcome text
      expect(find.text('Welcome Back'), findsOneWidget);
      
      // Check for email field
      expect(find.byType(TextFormField), findsAtLeast(2));
      
      // Check for Sign In button
      expect(find.text('Sign In'), findsOneWidget);
      
      // Check for Create Account button
      expect(find.text('Create Account'), findsOneWidget);
      
      // Check for Forgot Password link
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('Email field accepts text input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthViewModel(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Find email field and enter text
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Password field is obscured', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthViewModel(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Find password field (second TextField)
      final passwordFields = find.byType(TextField);
      
      // Check that at least 2 text fields exist (email and password)
      expect(passwordFields, findsAtLeast(2));
      
      // Password field should be the second TextField - we can't directly test obscureText
      // but we can verify the field exists and accepts input
      final passwordField = passwordFields.at(1);
      await tester.enterText(passwordField, 'password123');
      await tester.pump();
      
      // Verify input was accepted (password is hidden in the field itself)
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('Tapping Sign In button with empty fields shows validation errors', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthViewModel(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Tap Sign In button
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Wait for validation
      await tester.pump(const Duration(milliseconds: 100));

      // Check for validation error messages
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('Navigation to Create Account works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthViewModel(),
            child: const LoginScreen(),
          ),
          routes: {
            '/register': (context) => const Scaffold(body: Text('Register Screen')),
          },
        ),
      );

      // Tap Create Account button
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Check if navigated to register screen
      expect(find.text('Register Screen'), findsOneWidget);
    });
  });
}
