/// Input validation utilities for Ecocash API
library;

/// Network operators in Zimbabwe
enum NetworkOperator {
  econet,
  netone,
  telecel,
}

/// Exception thrown when validation fails
class ValidationException implements Exception {

  const ValidationException(this.message, this.field);
  final String message;
  final String field;

  @override
  String toString() => 'ValidationException: $message (Field: $field)';
}

/// Validation utilities for Ecocash API inputs
class EcocashValidators {
  // Supported currencies
  static const Set<String> supportedCurrencies = <String>{'USD', 'ZWL', 'EUR', 'GBP'};

  // Zimbabwe mobile number patterns
  static final RegExp _zimbabweMobilePattern = RegExp(r'^263[0-9]{9}$');
  static final RegExp _localMobilePattern = RegExp(r'^0[0-9]{9}$');

  // UUID pattern
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Validates mobile number format
  static bool isValidMobileNumber(String mobileNumber) {
    if (mobileNumber.isEmpty) {
      return false;
    }

    // Check for international format (263...)
    if (_zimbabweMobilePattern.hasMatch(mobileNumber)) {
      return true;
    }

    // Check for local format (07...)
    if (_localMobilePattern.hasMatch(mobileNumber)) {
      return true;
    }

    return false;
  }

  /// Converts local mobile number format to international format
  static String normalizePhoneNumber(String mobileNumber) {
    if (mobileNumber.startsWith('0')) {
      return '263${mobileNumber.substring(1)}';
    }
    return mobileNumber;
  }

  /// Validates amount
  static bool isValidAmount(double amount) {
    return amount > 0 &&
        amount <= 999999999.99 &&
        _hasValidDecimalPlaces(amount);
  }

  /// Validates currency code
  static bool isValidCurrency(String currency) {
    return supportedCurrencies.contains(currency.toUpperCase());
  }

  /// Validates UUID format
  static bool isValidUuid(String uuid) {
    return _uuidPattern.hasMatch(uuid);
  }

  /// Validates reason/description text
  static bool isValidReason(String reason) {
    return reason.isNotEmpty &&
        reason.length <= 255 &&
        reason.trim().isNotEmpty;
  }

  /// Validates client name
  static bool isValidClientName(String clientName) {
    return clientName.isNotEmpty &&
        clientName.length <= 100 &&
        clientName.trim().isNotEmpty &&
        RegExp(r'^[a-zA-Z0-9\s\-_.]+$').hasMatch(clientName);
  }

  /// Validates transaction reference format
  static bool isValidTransactionReference(String reference) {
    return reference.isNotEmpty &&
        reference.length <= 50 &&
        RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(reference);
  }

  /// Comprehensive payment validation
  static void validatePaymentRequest({
    required String customerMsisdn,
    required double amount,
    required String reason,
    required String currency,
    String? sourceReference,
  }) {
    if (!isValidMobileNumber(customerMsisdn)) {
      throw const ValidationException(
        'Invalid mobile number format. Expected: 263XXXXXXXXX or 0XXXXXXXXX',
        'customerMsisdn',
      );
    }

    if (!isValidAmount(amount)) {
      throw const ValidationException(
        'Invalid amount. Must be > 0, <= 999,999,999.99 and have max 2 decimal places',
        'amount',
      );
    }

    if (!isValidReason(reason)) {
      throw const ValidationException(
        'Invalid reason. Must be non-empty and <= 255 characters',
        'reason',
      );
    }

    if (!isValidCurrency(currency)) {
      throw ValidationException(
        'Invalid currency. Supported: ${supportedCurrencies.join(', ')}',
        'currency',
      );
    }

    if (sourceReference != null && !isValidUuid(sourceReference)) {
      throw const ValidationException(
        'Invalid source reference format. Must be a valid UUID',
        'sourceReference',
      );
    }
  }

  /// Comprehensive refund validation
  static void validateRefundRequest({
    required String originalEcocashTransactionReference,
    required String refundCorrelator,
    required String sourceMobileNumber,
    required double amount,
    String? clientName,
    required String currency,
    required String reasonForRefund,
  }) {
    if (!isValidTransactionReference(originalEcocashTransactionReference)) {
      throw const ValidationException(
        'Invalid original transaction reference format',
        'originalEcocashTransactionReference',
      );
    }

    if (!isValidUuid(refundCorrelator)) {
      throw const ValidationException(
        'Invalid refund correlator format. Must be a valid UUID',
        'refundCorrelator',
      );
    }

    if (!isValidMobileNumber(sourceMobileNumber)) {
      throw const ValidationException(
        'Invalid source mobile number format. Expected: 263XXXXXXXXX or 0XXXXXXXXX',
        'sourceMobileNumber',
      );
    }

    if (!isValidAmount(amount)) {
      throw const ValidationException(
        'Invalid refund amount. Must be > 0, <= 999,999,999.99 and have max 2 decimal places',
        'amount',
      );
    }

    if (clientName != null && !isValidClientName(clientName)) {
      throw const ValidationException(
        'Invalid client name. Must be non-empty, <= 100 characters, and contain only alphanumeric characters, spaces, hyphens, underscores, and dots',
        'clientName',
      );
    }

    if (!isValidCurrency(currency)) {
      throw ValidationException(
        'Invalid currency. Supported: ${supportedCurrencies.join(', ')}',
        'currency',
      );
    }

    if (!isValidReason(reasonForRefund)) {
      throw const ValidationException(
        'Invalid refund reason. Must be non-empty and <= 255 characters',
        'reasonForRefund',
      );
    }
  }

  /// Transaction lookup validation
  static void validateTransactionLookup({
    required String sourceMobileNumber,
    required String sourceReference,
  }) {
    if (!isValidMobileNumber(sourceMobileNumber)) {
      throw const ValidationException(
        'Invalid source mobile number format. Expected: 263XXXXXXXXX or 0XXXXXXXXX',
        'sourceMobileNumber',
      );
    }

    if (!isValidUuid(sourceReference)) {
      throw const ValidationException(
        'Invalid source reference format. Must be a valid UUID',
        'sourceReference',
      );
    }
  }

  /// Helper method to check decimal places
  static bool _hasValidDecimalPlaces(double amount) {
    final String amountStr = amount.toString();
    final int decimalIndex = amountStr.indexOf('.');

    if (decimalIndex == -1) {
      return true; // No decimal places
    }

    final int decimalPlaces = amountStr.length - decimalIndex - 1;
    return decimalPlaces <= 2;
  }

  /// Sanitizes input strings
  static String sanitizeString(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Validates API key format
  static bool isValidApiKey(String apiKey) {
    return apiKey.isNotEmpty && apiKey.length >= 16;
  }

  /// Validates bearer token format
  static bool isValidBearerToken(String bearerToken) {
    return bearerToken.isNotEmpty && bearerToken.length >= 16;
  }

  /// Gets supported network prefixes for Zimbabwe
  static List<String> getSupportedNetworkPrefixes() {
    return <String>['77', '78', '71', '73', '74']; // Econet, NetOne, Telecel prefixes
  }

  /// Validates network prefix
  static bool isValidNetworkPrefix(String mobileNumber) {
    final String normalizedNumber = normalizePhoneNumber(mobileNumber);
    if (normalizedNumber.length < 5) {
      return false;
    }

    final String prefix = normalizedNumber.substring(3, 5);
    return getSupportedNetworkPrefixes().contains(prefix);
  }

  /// Gets mobile network operator from number
  static String? getMobileNetworkOperator(String mobileNumber) {
    final String normalizedNumber = normalizePhoneNumber(mobileNumber);
    if (normalizedNumber.length < 5) {
      return null;
    }

    final String prefix = normalizedNumber.substring(3, 5);

    switch (prefix) {
      case '77':
      case '78':
        return 'Econet';
      case '71':
        return 'NetOne';
      case '73':
      case '74':
        return 'Telecel';
      default:
        return null;
    }
  }

  /// Validates transaction lookup request parameters
  static void validateTransactionLookupRequest({
    required String sourceMobileNumber,
    required String sourceReference,
  }) {
    if (!isValidMobileNumber(sourceMobileNumber)) {
      throw const ValidationException(
        'Invalid mobile number format',
        'sourceMobileNumber',
      );
    }

    if (!isValidTransactionReference(sourceReference)) {
      throw const ValidationException(
        'Invalid source reference format',
        'sourceReference',
      );
    }
  }

  /// Gets network operator enum for a phone number
  static NetworkOperator? getNetworkOperator(String mobileNumber) {
    final String normalizedNumber = normalizePhoneNumber(mobileNumber);
    if (normalizedNumber.length < 5) {
      return null;
    }
    
    final String prefix = normalizedNumber.substring(3, 5);
    
    switch (prefix) {
      case '77':
      case '78':
        return NetworkOperator.econet;
      case '71':
        return NetworkOperator.netone;
      case '73':
      case '74':
        return NetworkOperator.telecel;
      default:
        return null;
    }
  }
}
