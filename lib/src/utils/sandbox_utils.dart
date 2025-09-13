/// Sandbox utilities and mock responses for Ecocash API testing
library;

import 'dart:math' as math;

/// Sandbox configuration and utilities
class SandboxUtils {
  // Test phone numbers for different scenarios
  static const String testPhoneSuccess = '263774222475';
  static const String testPhoneInsufficientFunds = '263774222476';
  static const String testPhoneTimeout = '263774222477';
  static const String testPhoneInvalidPin = '263774222478';
  static const String testPhoneNetworkError = '263774222479';

  // Test PINs
  static const List<String> validTestPins = <String>['0000', '1234', '9999'];
  static const String defaultTestPin = '0000';

  // Test amounts for different scenarios
  static const double testAmountSuccess = 10.50;
  static const double testAmountInsufficientFunds = 999999.99;
  static const double testAmountTimeout = 50.00;

  /// Gets appropriate test PIN for sandbox testing
  static String getTestPin() => defaultTestPin;

  /// Generates a mock successful payment response
  static Map<String, dynamic> mockSuccessfulPaymentResponse({
    required String sourceReference,
    required double amount,
    required String currency,
  }) {
    return <String, dynamic>{
      'status': 'success',
      'message': 'Payment completed successfully',
      'ecocashTransactionReference': 'ECO${_generateRandomId(10)}',
      'sourceReference': sourceReference,
      'amount': amount,
      'currency': currency,
      'transactionDateTime': DateTime.now().toIso8601String(),
      'customerMsisdn': testPhoneSuccess,
    };
  }

  /// Generates a mock failed payment response
  static Map<String, dynamic> mockFailedPaymentResponse({
    required String sourceReference,
    String reason = 'Insufficient funds',
  }) {
    return <String, dynamic>{
      'status': 'failed',
      'message': reason,
      'sourceReference': sourceReference,
      'errorCode': 'INSUFFICIENT_FUNDS',
      'transactionDateTime': DateTime.now().toIso8601String(),
    };
  }

  /// Generates a mock successful refund response
  static Map<String, dynamic> mockSuccessfulRefundResponse({
    required String refundCorrelator,
    required double amount,
    required String currency,
  }) {
    return <String, dynamic>{
      'transactionStatus': 'completed',
      'destinationReferenceCode': 'REF${_generateRandomId(8)}',
      'refundCorrelator': refundCorrelator,
      'amount': amount,
      'currency': currency,
      'transactionDateTime': DateTime.now().toIso8601String(),
      'message': 'Refund processed successfully',
    };
  }

  /// Generates a mock transaction lookup response
  static Map<String, dynamic> mockTransactionLookupResponse({
    required String sourceReference,
    required String sourceMobileNumber,
    String status = 'completed',
  }) {
    return <String, dynamic>{
      'sourceMobileNumber': sourceMobileNumber,
      'sourceReference': sourceReference,
      'amount': testAmountSuccess,
      'status': status,
      'ecocashReference': 'ECO${_generateRandomId(10)}',
      'transactionDateTime':
          DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      'currency': 'USD',
      'customerMsisdn': testPhoneSuccess,
    };
  }

  /// Determines expected response based on test phone number
  static MockResponseType getExpectedResponseType(String phoneNumber) {
    switch (phoneNumber) {
      case testPhoneSuccess:
        return MockResponseType.success;
      case testPhoneInsufficientFunds:
        return MockResponseType.insufficientFunds;
      case testPhoneTimeout:
        return MockResponseType.timeout;
      case testPhoneInvalidPin:
        return MockResponseType.invalidPin;
      case testPhoneNetworkError:
        return MockResponseType.networkError;
      default:
        return MockResponseType.success;
    }
  }

  /// Generates appropriate mock response for payment
  static Map<String, dynamic> generatePaymentMockResponse({
    required String customerMsisdn,
    required String sourceReference,
    required double amount,
    required String currency,
  }) {
    final MockResponseType responseType =
        getExpectedResponseType(customerMsisdn);

    switch (responseType) {
      case MockResponseType.success:
        return mockSuccessfulPaymentResponse(
          sourceReference: sourceReference,
          amount: amount,
          currency: currency,
        );
      case MockResponseType.insufficientFunds:
        return mockFailedPaymentResponse(
          sourceReference: sourceReference,
          reason: 'Insufficient funds in customer wallet',
        );
      case MockResponseType.timeout:
        return mockFailedPaymentResponse(
          sourceReference: sourceReference,
          reason: 'Transaction timeout',
        );
      case MockResponseType.invalidPin:
        return mockFailedPaymentResponse(
          sourceReference: sourceReference,
          reason: 'Invalid PIN entered',
        );
      case MockResponseType.networkError:
        return mockFailedPaymentResponse(
          sourceReference: sourceReference,
          reason: 'Network error occurred',
        );
    }
  }

  /// Gets all test scenarios
  static List<Map<String, dynamic>> getTestScenarios() {
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'name': 'Successful Payment',
        'phone': testPhoneSuccess,
        'expected': 'success',
        'description': 'Should complete successfully with valid response',
      },
      <String, dynamic>{
        'name': 'Insufficient Funds',
        'phone': testPhoneInsufficientFunds,
        'expected': 'failed',
        'description': 'Should fail due to insufficient funds',
      },
      <String, dynamic>{
        'name': 'Transaction Timeout',
        'phone': testPhoneTimeout,
        'expected': 'failed',
        'description': 'Should timeout and fail',
      },
      <String, dynamic>{
        'name': 'Invalid PIN',
        'phone': testPhoneInvalidPin,
        'expected': 'failed',
        'description': 'Should fail due to invalid PIN',
      },
      <String, dynamic>{
        'name': 'Network Error',
        'phone': testPhoneNetworkError,
        'expected': 'failed',
        'description': 'Should fail due to network error',
      },
    ];
  }

  /// Gets expected behavior for a phone number
  static String getExpectedBehavior(String phoneNumber) {
    switch (phoneNumber) {
      case testPhoneSuccess:
        return 'Successful transaction';
      case testPhoneInsufficientFunds:
        return 'Insufficient funds error';
      case testPhoneTimeout:
        return 'Transaction timeout';
      case testPhoneInvalidPin:
        return 'Invalid PIN error';
      case testPhoneNetworkError:
        return 'Network error';
      default:
        return 'Unknown behavior';
    }
  }

  /// Validates if a phone number is a test number
  static bool isTestPhoneNumber(String phoneNumber) {
    return <String>[
      testPhoneSuccess,
      testPhoneInsufficientFunds,
      testPhoneTimeout,
      testPhoneInvalidPin,
      testPhoneNetworkError,
    ].contains(phoneNumber);
  }

  /// Gets test scenario description for a phone number
  static String getTestScenarioDescription(String phoneNumber) {
    switch (phoneNumber) {
      case testPhoneSuccess:
        return 'Successful transaction';
      case testPhoneInsufficientFunds:
        return 'Insufficient funds error';
      case testPhoneTimeout:
        return 'Transaction timeout';
      case testPhoneInvalidPin:
        return 'Invalid PIN error';
      case testPhoneNetworkError:
        return 'Network error';
      default:
        return 'Unknown test scenario';
    }
  }

  /// Generates random ID for mock responses
  static String _generateRandomId(int length) {
    const String chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final math.Random random = math.Random();
    return List.generate(length, (int index) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Creates a complete test suite data set
  static List<Map<String, dynamic>> createTestSuite() {
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'name': 'Successful Payment',
        'phoneNumber': testPhoneSuccess,
        'amount': testAmountSuccess,
        'currency': 'USD',
        'expectedStatus': 'success',
        'description': 'Should complete successfully with valid response',
      },
      <String, dynamic>{
        'name': 'Insufficient Funds',
        'phoneNumber': testPhoneInsufficientFunds,
        'amount': testAmountInsufficientFunds,
        'currency': 'USD',
        'expectedStatus': 'failed',
        'description': 'Should fail due to insufficient funds',
      },
      <String, dynamic>{
        'name': 'Transaction Timeout',
        'phoneNumber': testPhoneTimeout,
        'amount': testAmountTimeout,
        'currency': 'USD',
        'expectedStatus': 'failed',
        'description': 'Should timeout and fail',
      },
      <String, dynamic>{
        'name': 'Invalid PIN',
        'phoneNumber': testPhoneInvalidPin,
        'amount': testAmountSuccess,
        'currency': 'USD',
        'expectedStatus': 'failed',
        'description': 'Should fail due to invalid PIN',
      },
      <String, dynamic>{
        'name': 'Network Error',
        'phoneNumber': testPhoneNetworkError,
        'amount': testAmountSuccess,
        'currency': 'USD',
        'expectedStatus': 'failed',
        'description': 'Should fail due to network error',
      },
    ];
  }

  /// Simulates network delay for more realistic testing
  static Future<void> simulateNetworkDelay([Duration? delay]) async {
    final Duration actualDelay =
        delay ?? Duration(milliseconds: math.Random().nextInt(1000) + 500);
    await Future.delayed(actualDelay);
  }

  /// Creates mock HTTP responses for testing
  static Map<String, dynamic> createMockHttpResponse({
    required int statusCode,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) {
    return <String, dynamic>{
      'statusCode': statusCode,
      'body': body,
      'headers': headers ?? <String, String>{'content-type': 'application/json'},
    };
  }
}

/// Mock response types for testing
enum MockResponseType {
  success,
  insufficientFunds,
  timeout,
  invalidPin,
  networkError,
}

/// Sandbox environment configuration
class SandboxConfig {

  const SandboxConfig({
    this.enableMockResponses = false,
    this.mockResponseDelay = const Duration(milliseconds: 500),
    this.mockSuccessRate = 0.8,
    this.logAllRequests = true,
    this.environment = 'sandbox',
  });
  final bool enableMockResponses;
  final Duration mockResponseDelay;
  final double mockSuccessRate;
  final bool logAllRequests;
  final String environment;

  /// Development configuration with high success rate
  static const SandboxConfig development = SandboxConfig(
    enableMockResponses: true,
    mockResponseDelay: Duration(milliseconds: 200),
    mockSuccessRate: 0.95,
    logAllRequests: true,
    environment: 'development',
  );

  /// Testing configuration with mixed success rates
  static const SandboxConfig testing = SandboxConfig(
    enableMockResponses: true,
    mockResponseDelay: Duration(milliseconds: 100),
    mockSuccessRate: 0.7,
    logAllRequests: true,
    environment: 'testing',
  );

  /// Production-like sandbox configuration
  static const SandboxConfig production = SandboxConfig(
    enableMockResponses: false,
    mockResponseDelay: Duration(milliseconds: 1000),
    mockSuccessRate: 0.99,
    logAllRequests: false,
    environment: 'sandbox',
  );
}

/// Mock API client for testing without hitting real endpoints
class MockEcocashApiClient {

  MockEcocashApiClient({this.config = SandboxConfig.development});
  final SandboxConfig config;
  final math.Random _random = math.Random();

  /// Simulates a payment request
  Future<Map<String, dynamic>> makePayment({
    required String customerMsisdn,
    required double amount,
    required String reason,
    required String currency,
    required String sourceReference,
  }) async {
    await SandboxUtils.simulateNetworkDelay(config.mockResponseDelay);

    if (config.enableMockResponses) {
      return SandboxUtils.generatePaymentMockResponse(
        customerMsisdn: customerMsisdn,
        sourceReference: sourceReference,
        amount: amount,
        currency: currency,
      );
    }

    // Simulate random success/failure based on success rate
    final bool isSuccess = _random.nextDouble() < config.mockSuccessRate;

    if (isSuccess) {
      return SandboxUtils.mockSuccessfulPaymentResponse(
        sourceReference: sourceReference,
        amount: amount,
        currency: currency,
      );
    } else {
      return SandboxUtils.mockFailedPaymentResponse(
        sourceReference: sourceReference,
        reason: 'Simulated failure for testing',
      );
    }
  }

  /// Simulates a refund request
  Future<Map<String, dynamic>> processRefund({
    required String originalEcocashTransactionReference,
    required String refundCorrelator,
    required double amount,
    required String currency,
  }) async {
    await SandboxUtils.simulateNetworkDelay(config.mockResponseDelay);

    final bool isSuccess = _random.nextDouble() < config.mockSuccessRate;

    if (isSuccess) {
      return SandboxUtils.mockSuccessfulRefundResponse(
        refundCorrelator: refundCorrelator,
        amount: amount,
        currency: currency,
      );
    } else {
      return <String, dynamic>{
        'transactionStatus': 'failed',
        'refundCorrelator': refundCorrelator,
        'message': 'Refund failed - original transaction not found',
        'errorCode': 'ORIGINAL_TRANSACTION_NOT_FOUND',
      };
    }
  }

  /// Simulates a transaction lookup
  Future<Map<String, dynamic>> lookupTransaction({
    required String sourceMobileNumber,
    required String sourceReference,
  }) async {
    await SandboxUtils.simulateNetworkDelay(config.mockResponseDelay);

    return SandboxUtils.mockTransactionLookupResponse(
      sourceReference: sourceReference,
      sourceMobileNumber: sourceMobileNumber,
      status: _random.nextDouble() < config.mockSuccessRate
          ? 'completed'
          : 'failed',
    );
  }
}
