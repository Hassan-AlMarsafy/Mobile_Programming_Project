/// Comprehensive validation utility for form inputs
/// Provides validation methods for various data types and formats
class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // RFC 5322 compliant email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation with customizable requirements
  static String? password(
    String? value, {
    int minLength = 8,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireNumber = true,
    bool requireSpecialChar = false,
  }) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (requireNumber && !value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    if (requireSpecialChar &&
        !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  // Simple password validation for basic requirements
  static String? simplePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // Confirm password validation
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Name validation
  static String? name(String? value, {int minLength = 2, int maxLength = 50}) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < minLength) {
      return 'Name must be at least $minLength characters';
    }

    if (trimmedValue.length > maxLength) {
      return 'Name must not exceed $maxLength characters';
    }

    // Check if name contains only letters, spaces, hyphens, and apostrophes
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(trimmedValue)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  // Phone number validation
  static String? phone(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'Phone number is required' : null;
    }

    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Required field validation
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Number validation
  static String? number(
    String? value, {
    bool required = true,
    double? min,
    double? max,
    String fieldName = 'Value',
  }) {
    if (value == null || value.isEmpty) {
      return required ? '$fieldName is required' : null;
    }

    final number = double.tryParse(value);

    if (number == null) {
      return 'Please enter a valid number';
    }

    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }

    if (max != null && number > max) {
      return '$fieldName must not exceed $max';
    }

    return null;
  }

  // Integer validation
  static String? integer(
    String? value, {
    bool required = true,
    int? min,
    int? max,
    String fieldName = 'Value',
  }) {
    if (value == null || value.isEmpty) {
      return required ? '$fieldName is required' : null;
    }

    final number = int.tryParse(value);

    if (number == null) {
      return 'Please enter a valid whole number';
    }

    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }

    if (max != null && number > max) {
      return '$fieldName must not exceed $max';
    }

    return null;
  }

  // Date validation
  static String? date(
    String? value, {
    bool required = true,
    DateTime? minDate,
    DateTime? maxDate,
    String format = 'yyyy-MM-dd',
  }) {
    if (value == null || value.isEmpty) {
      return required ? 'Date is required' : null;
    }

    try {
      final date = DateTime.parse(value);

      if (minDate != null && date.isBefore(minDate)) {
        return 'Date must be after ${_formatDate(minDate)}';
      }

      if (maxDate != null && date.isAfter(maxDate)) {
        return 'Date must be before ${_formatDate(maxDate)}';
      }

      return null;
    } catch (e) {
      return 'Please enter a valid date (format: $format)';
    }
  }

  // Date string formatting helper
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // URL validation
  static String? url(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'URL is required' : null;
    }

    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  // Length validation
  static String? length(
    String? value, {
    int? minLength,
    int? maxLength,
    String fieldName = 'This field',
  }) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (minLength != null && value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (maxLength != null && value.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }

    return null;
  }

  // Alphanumeric validation
  static String? alphanumeric(
    String? value, {
    bool required = true,
    String fieldName = 'This field',
  }) {
    if (value == null || value.isEmpty) {
      return required ? '$fieldName is required' : null;
    }

    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return '$fieldName can only contain letters and numbers';
    }

    return null;
  }

  // Compose multiple validators
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  // Sensor calibration validation
  static String? calibrationOffset(
    String? value, {
    required double min,
    required double max,
    required double sensorMin,
    required double sensorMax,
    required String unit,
  }) {
    if (value == null || value.isEmpty) {
      return 'Calibration offset is required';
    }

    final offset = double.tryParse(value);

    if (offset == null) {
      return 'Please enter a valid number';
    }

    // Calculate reasonable calibration range (±50% of sensor range)
    final sensorRange = sensorMax - sensorMin;
    final maxCalibration = sensorRange * 0.5;

    if (offset.abs() > maxCalibration) {
      return 'Offset too large. Max: ±${maxCalibration.toStringAsFixed(1)} $unit';
    }

    return null;
  }

  // Time validation (HH:MM format)
  static String? time(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'Time is required' : null;
    }

    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');

    if (!timeRegex.hasMatch(value)) {
      return 'Please enter a valid time (HH:MM)';
    }

    return null;
  }

  // Percentage validation
  static String? percentage(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'Percentage is required' : null;
    }

    final number = double.tryParse(value);

    if (number == null) {
      return 'Please enter a valid percentage';
    }

    if (number < 0 || number > 100) {
      return 'Percentage must be between 0 and 100';
    }

    return null;
  }

  // Minimum age validation
  static String? minimumAge(String? value, {required int minAge}) {
    if (value == null || value.isEmpty) {
      return 'Date of birth is required';
    }

    try {
      final dob = DateTime.parse(value);
      final today = DateTime.now();
      final age = today.year -
          dob.year -
          ((today.month < dob.month ||
                  (today.month == dob.month && today.day < dob.day))
              ? 1
              : 0);

      if (age < minAge) {
        return 'You must be at least $minAge years old';
      }

      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  // Credit card validation (basic Luhn algorithm)
  static String? creditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }

    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < 13 || digitsOnly.length > 19) {
      return 'Please enter a valid card number';
    }

    // Luhn algorithm
    int sum = 0;
    bool alternate = false;

    for (int i = digitsOnly.length - 1; i >= 0; i--) {
      int digit = int.parse(digitsOnly[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    if (sum % 10 != 0) {
      return 'Invalid card number';
    }

    return null;
  }

  // ZIP/Postal code validation
  static String? postalCode(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'Postal code is required' : null;
    }

    // Supports various formats (US, UK, Canada, etc.)
    if (value.length < 3 || value.length > 10) {
      return 'Please enter a valid postal code';
    }

    return null;
  }

  // Username validation
  static String? username(String? value,
      {int minLength = 3, int maxLength = 20}) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

    if (value.length < minLength) {
      return 'Username must be at least $minLength characters';
    }

    if (value.length > maxLength) {
      return 'Username must not exceed $maxLength characters';
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    if (value.startsWith('_') || value.endsWith('_')) {
      return 'Username cannot start or end with underscore';
    }

    return null;
  }
}
