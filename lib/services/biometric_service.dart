import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Check if biometric authentication is available on device
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Authenticate with biometrics
  Future<Map<String, dynamic>> authenticateWithDetails({String reason = 'Please authenticate to access the app'}) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        print('BiometricService: Biometric not available');
        return {'success': false, 'error': 'Biometric authentication is not available on this device'};
      }

      // Check if device has enrolled biometrics
      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        print('BiometricService: No biometrics enrolled on device');
        return {'success': false, 'error': 'No biometrics enrolled. Please add a fingerprint in Settings.'};
      }

      print('BiometricService: Attempting authentication...');
      print('BiometricService: Available biometrics: $availableBiometrics');
      
      final result = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: false,
        ),
      );
      
      print('BiometricService: Authentication result: $result');
      
      if (result) {
        return {'success': true, 'error': null};
      } else {
        return {'success': false, 'error': 'Authentication was cancelled or failed'};
      }
    } catch (e) {
      print('BiometricService: Authentication error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Backward compatibility - simple boolean return
  Future<bool> authenticate({String reason = 'Please authenticate to access the app'}) async {
    final result = await authenticateWithDetails(reason: reason);
    return result['success'] as bool;
  }

  // Check if biometric is enabled in settings
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('biometric_enabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  // Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', enabled);
    } catch (e) {
      // Handle error
    }
  }

  // Check if app should require biometric on launch
  Future<bool> shouldRequireBiometric() async {
    final isEnabled = await isBiometricEnabled();
    final isAvailable = await isBiometricAvailable();
    return isEnabled && isAvailable;
  }

  // Get biometric type name for display
  Future<String> getBiometricTypeName() async {
    final types = await getAvailableBiometrics();
    
    if (types.isEmpty) {
      return 'Biometric';
    }
    
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    }
    
    if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    }
    
    if (types.contains(BiometricType.iris)) {
      return 'Iris';
    }
    
    return 'Biometric';
  }
}
