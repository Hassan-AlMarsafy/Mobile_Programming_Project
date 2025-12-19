import 'package:flutter_test/flutter_test.dart';

// Helper function for tests
void setupTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();
}

Future<T> neverEndingFuture<T>() async {
  // ignore: literal_only_boolean_expressions
  while (true) {
    await Future.delayed(const Duration(minutes: 5));
  }
}
