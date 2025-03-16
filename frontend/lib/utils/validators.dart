class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Number validation
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    return null;
  }

  // Positive number validation
  static String? validatePositiveNumber(String? value, String fieldName) {
    final numberValidation = validateNumber(value, fieldName);
    if (numberValidation != null) {
      return numberValidation;
    }

    final number = double.parse(value!);
    if (number <= 0) {
      return '$fieldName must be greater than zero';
    }

    return null;
  }

  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Basic phone validation - can be customized based on country formats
    final phoneRegExp = RegExp(r'^\+?[0-9]{8,15}$');
    if (!phoneRegExp.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Date validation
  static String? validateDate(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  // Cylinder serial number validation
  static String? validateCylinderSerial(String? value) {
    if (value == null || value.isEmpty) {
      return 'Serial number is required';
    }

    if (value.length < 3) {
      return 'Serial number must be at least 3 characters';
    }

    return null;
  }

  // Credit limit validation
  static String? validateCreditLimit(String? value, bool isCreditCustomer) {
    if (!isCreditCustomer) {
      return null; // No validation needed for non-credit customers
    }

    if (value == null || value.isEmpty) {
      return 'Credit limit is required for credit customers';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }

    if (number < 0) {
      return 'Credit limit cannot be negative';
    }

    return null;
  }

  // QR code validation
  static String? validateQRCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'QR code is required';
    }

    if (value.length < 10) {
      return 'Invalid QR code format';
    }

    return null;
  }
}
