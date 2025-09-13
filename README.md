# Ecocash Dart SDK

A comprehensive, production-ready Dart SDK for integrating with the Ecocash Open API. This SDK provides enterprise-grade features for processing payments, refunds, and transaction lookups in the Zimbabwe fintech ecosystem.

## Features

### Core API Features
- **Payment Processing** - C2B (Customer to Business) instant payments
- **Refund Management** - Process refunds for previous transactions  
- **Transaction Lookup** - Check transaction status and details
- **Mobile Money Integration** - Full Zimbabwe mobile money support

### Advanced SDK Features
- **Input Validation** - Comprehensive validation for all inputs
- **Retry Mechanism** - Configurable retry with exponential backoff
- **Batch Operations** - Process multiple transactions concurrently
- **Analytics & Reporting** - Built-in transaction analytics
- **Logging & Auditing** - Comprehensive logging with data masking
- **Circuit Breaker** - Prevent cascading failures
- **Offline Queue** - Queue transactions when network is unavailable
- **Sandbox Utilities** - Testing tools and mock responses
- **Data Security** - Automatic masking of sensitive information
- **Type Safety** - Full Dart null safety and strong typing

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  uuid: ^4.1.0
```

Then run:

```bash
dart pub get
```

## Quick Start

### Basic Usage
```dart
import 'package:ecocash_dart_sdk/ecocash_dart_sdk.dart';

void main() async {
  // Initialize with basic configuration
  final ecocash = EcocashApi(
    apiKey: "your_api_key_here",
    environment: EcocashEnvironment.sandbox,
  );

  try {
    // Make a payment
    final payment = await ecocash.makePayment(
      customerMsisdn: "263XXXXXXXXX",
      amount: 10.50,
      reason: "Payment for services",
      currency: "USD",
    );
    
    print('Payment successful: ${payment.ecocashTransactionReference}');
  } catch (e) {
    print('Payment failed: $e');
  } finally {
    ecocash.dispose();
  }
}
```

### Advanced Configuration
```dart
import 'package:ecocash_dart_sdk/ecocash_dart_sdk.dart';

void main() async {
  // Initialize with all features enabled
  final ecocash = EcocashApi(
    apiKey: "your_api_key_here",
    environment: EcocashEnvironment.sandbox,
    bearerToken: "your_bearer_token", // Optional
    enableValidation: true,
    enableRetries: true,
    enableOfflineQueue: true,
    enableAnalytics: true,
    enableLogging: true,
  );

  // Use the SDK...
  ecocash.dispose();
}
```

## API Reference

### Constructor

```dart
EcocashApi({
  required String apiKey,
  EcocashEnvironment environment = EcocashEnvironment.sandbox,
  String? bearerToken,
  bool enableValidation = true,
  bool enableRetries = true,
  bool enableOfflineQueue = false,
  bool enableAnalytics = true,
  bool enableLogging = true,
})
```

**Parameters:**
- `apiKey` (required) - Your Ecocash API key
- `environment` (optional) - Sandbox or live environment
- `bearerToken` (optional) - Bearer token for authenticated endpoints
- `enableValidation` (optional) - Enable input validation
- `enableRetries` (optional) - Enable retry mechanism
- `enableOfflineQueue` (optional) - Enable offline queue
- `enableAnalytics` (optional) - Enable analytics tracking
- `enableLogging` (optional) - Enable logging

### Core Methods

#### makePayment()

Initiates a C2B (Customer to Business) payment.

```dart
Future<PaymentResponse> makePayment({
  required String customerMsisdn,
  required double amount,
  required String reason,
  required String currency,
  String? sourceReference,
  String? clientName,
})
```

**Parameters:**
- `customerMsisdn` - Customer's mobile number (e.g., "263XXXXXXXXX")
- `amount` - Payment amount as double (e.g., 10.50)
- `reason` - Payment description/reason
- `currency` - Currency code (e.g., "USD", "ZWL")
- `sourceReference` - Optional unique reference (UUID generated if not provided)
- `clientName` - Optional client name for the transaction

**Example:**
```dart
final result = await ecocash.makePayment(
  customerMsisdn: "263XXXXXXXXX",
  amount: 25.00,
  reason: "Online purchase",
  currency: "USD",
);
```

#### processRefund()

Processes a refund for a previous transaction.

```dart
Future<RefundResponse> processRefund({
  required String originalEcocashTransactionReference,
  required String sourceMobileNumber,
  required double amount,
  required String reasonForRefund,
  required String currency,
  String? refundCorrelator,
  String? clientName,
})
```

**Parameters:**
- `originalEcocashTransactionReference` - Reference from the original payment
- `sourceMobileNumber` - Customer's mobile number
- `amount` - Refund amount as double
- `reasonForRefund` - Refund reason/description
- `currency` - Currency code
- `refundCorrelator` - Optional unique correlator (UUID generated if not provided)
- `clientName` - Optional client name for the refund

**Example:**
```dart
final refund = await ecocash.processRefund(
  originalEcocashTransactionReference: "ECO123456789",
  sourceMobileNumber: "263XXXXXXXXX",
  amount: 10.00,
  reasonForRefund: "Customer requested refund",
  currency: "USD",
);
```

#### lookupTransaction()

Looks up the status of a transaction.

```dart
Future<TransactionStatus> lookupTransaction({
  required String sourceMobileNumber,
  required String sourceReference,
})
```

**Parameters:**
- `sourceMobileNumber` - Customer's mobile number
- `sourceReference` - The source reference used in the original transaction

**Example:**
```dart
final status = await ecocash.lookupTransaction(
  sourceMobileNumber: "263XXXXXXXXX",
  sourceReference: "your-source-reference-uuid",
);
```

### Utility Methods

#### generateSourceReference()

Generates a new UUID for use as a source reference.

```dart
String generateSourceReference()
```

#### generateRefundCorrelator()

Generates a new UUID for use as a refund correlator.

```dart
String generateRefundCorrelator()
```

#### dispose()

Disposes of the HTTP client to free up resources.

```dart
void dispose()
```

## Advanced Features

### Batch Operations

Process multiple payments concurrently:

```dart
// Process multiple payments concurrently
final requests = [
  PaymentRequest(
    customerMsisdn: "263XXXXXXXXX",
    amount: 10.0,
    reason: "Batch payment 1",
    currency: "USD",
    sourceReference: ecocash.generateSourceReference(),
  ),
  PaymentRequest(
    customerMsisdn: "263XXXXXXXXX",
    amount: 15.50,
    reason: "Batch payment 2", 
    currency: "USD",
    sourceReference: ecocash.generateSourceReference(),
  ),
];

final result = await ecocash.batchPayments(
  requests,
  concurrency: 3, // Process 3 at a time
);

print('Successful: ${result.successful.length}');
print('Failed: ${result.failed.length}');
print('Success Rate: ${(result.successRate * 100).toStringAsFixed(1)}%');
```

### Analytics and Reporting

Get comprehensive analytics:

```dart
// Get comprehensive analytics
final analytics = ecocash.getAnalytics(
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now(),
);

print('Total Transactions: ${analytics.totalTransactions}');
print('Net Amount: ${analytics.netAmount}');
print('Payment Success Rate: ${(analytics.paymentAnalytics.successRate * 100).toStringAsFixed(1)}%');

// Get payment-specific analytics
final paymentAnalytics = ecocash.getPaymentAnalytics();
print('Total Payments: ${paymentAnalytics.totalPayments}');
print('Average Amount: ${paymentAnalytics.averageAmount}');

// Currency breakdown
for (final entry in paymentAnalytics.currencyBreakdown.entries) {
  print('${entry.key}: ${entry.value}');
}
```

### Input Validation

The SDK includes comprehensive input validation:

```dart
import 'package:ecocash_dart_sdk/ecocash_dart_sdk.dart';

// Validate phone numbers
bool isValid = EcocashValidators.isValidMobileNumber("263XXXXXXXXX");
String normalized = EcocashValidators.normalizePhoneNumber("077XXXXXXX"); // Returns "263XXXXXXXXX"
String? operator = EcocashValidators.getMobileNetworkOperator("263XXXXXXXXX"); // Returns "Econet"

// Validate amounts
bool validAmount = EcocashValidators.isValidAmount(50.25); // true
bool invalidAmount = EcocashValidators.isValidAmount(-10.0); // false

// Validate currencies
bool validCurrency = EcocashValidators.isValidCurrency("USD"); // true
bool invalidCurrency = EcocashValidators.isValidCurrency("XYZ"); // false
```

### Retry Configuration

Configure retry behavior for network resilience:

```dart
// Aggressive retry strategy
final aggressiveConfig = RetryConfig(
  maxAttempts: 5,
  initialDelay: Duration(milliseconds: 500),
  maxDelay: Duration(seconds: 30),
  backoffMultiplier: 1.5,
  exponentialBackoff: true,
  retryableStatusCodes: [408, 429, 500, 502, 503, 504],
);

// Conservative retry strategy  
final conservativeConfig = RetryConfig(
  maxAttempts: 2,
  initialDelay: Duration(seconds: 2),
  backoffMultiplier: 3.0,
);

final ecocash = EcocashApi(
  apiKey: "your_api_key",
  retryConfig: aggressiveConfig,
);
```

### Logging Configuration

Flexible logging system with data masking:

```dart
import 'package:ecocash_dart_sdk/ecocash_dart_sdk.dart';

// Console logger with colors
final consoleLogger = ConsoleLogger(
  minLevel: LogLevel.info,
  colorOutput: true,
);

// File logger with daily rotation
final fileLogger = FileLogger(
  filePath: 'logs/ecocash_sdk.log',
  minLevel: LogLevel.debug,
  rotateDaily: true,
);

// Composite logger (multiple destinations)
final logger = CompositeLogger([consoleLogger, fileLogger]);

// Data masking for sensitive information
final sensitiveData = {
  'customerMsisdn': '263XXXXXXXXX',
  'apiKey': 'secret_key_12345',
  'amount': 100.50,
};

final masked = DataMasker.maskSensitiveData(sensitiveData);
// Result: {'customerMsisdn': '263***XX', 'apiKey': 'se***45', 'amount': 100.50}
```

### Sandbox and Testing

Comprehensive testing utilities:

```dart
import 'package:ecocash_dart_sdk/ecocash_dart_sdk.dart';

// Test phone numbers for different scenarios
final testPhones = {
  SandboxUtils.testPhoneSuccess: 'Successful transaction',
  SandboxUtils.testPhoneInsufficientFunds: 'Insufficient funds error',
  SandboxUtils.testPhoneTimeout: 'Transaction timeout',
  SandboxUtils.testPhoneInvalidPin: 'Invalid PIN error',
  SandboxUtils.testPhoneNetworkError: 'Network error',
};

// Enable mock responses for testing
final ecocash = EcocashApi(
  apiKey: "test_api_key",
  environment: EcocashEnvironment.sandbox,
  enableValidation: true,
);

// Generate mock responses
final mockPayment = SandboxUtils.mockSuccessfulPaymentResponse(
  sourceReference: "test-ref-123",
  amount: 50.0,
  currency: "USD",
);
```

## Error Handling

The SDK includes comprehensive error handling:

```dart
try {
  final payment = await ecocash.makePayment(/* params */);
} on ValidationException catch (e) {
  print('Validation Error: ${e.message} (Field: ${e.field})');
} on EcocashApiException catch (e) {
  print('API Error: ${e.message}');
  print('Status Code: ${e.statusCode}');
  print('Response: ${e.response}');
} on CircuitBreakerOpenException catch (e) {
  print('Circuit Breaker Open: ${e.message}');
} catch (e) {
  print('Unexpected Error: $e');
}
```

## Configuration Examples

### Development Environment
```dart
final devSdk = EcocashApi(
  apiKey: "dev_api_key",
  environment: EcocashEnvironment.sandbox,
  enableValidation: true,
  enableRetries: true,
  enableOfflineQueue: true,
  enableAnalytics: true,
  enableLogging: true,
);
```

### Production Environment
```dart
final prodSdk = EcocashApi(
  apiKey: "prod_api_key",
  environment: EcocashEnvironment.live,
  bearerToken: "prod_bearer_token",
  enableValidation: true,
  enableRetries: true,
  enableOfflineQueue: false,
  enableAnalytics: true,
  enableLogging: true,
);
```

### Testing Environment
```dart
final testSdk = EcocashApi(
  apiKey: "test_api_key",
  environment: EcocashEnvironment.sandbox,
  enableValidation: false,
  enableRetries: false,
  enableOfflineQueue: false,
  enableAnalytics: false,
  enableLogging: false,
);
```

## API Endpoints

The SDK supports the following Ecocash API endpoints:

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/v2/payment/instant/c2b/sandbox` | Initiate C2B payments (sandbox) |
| POST | `/v2/payment/instant/c2b/live` | Initiate C2B payments (live) |
| POST | `/v2/refund/instant/c2b/sandbox` | Process refunds (sandbox) |
| POST | `/v2/refund/instant/c2b/live` | Process refunds (live) |
| POST | `/v1/transaction/c2b/status/sandbox` | Transaction lookup (sandbox) |
| POST | `/v1/transaction/c2b/status/live` | Transaction lookup (live) |

## Testing

Run the examples:

```bash
# Basic example
dart run example/basic_example.dart

# Advanced example
dart run example/advanced_example.dart

# Main example
dart run example/main.dart
```

## Best Practices

1. **Always dispose** of the EcocashApi instance when done:
   ```dart
   final ecocash = EcocashApi(apiKey: "key");
   try {
     // Use the API
   } finally {
     ecocash.dispose();
   }
   ```

2. **Handle errors gracefully**:
   ```dart
   try {
     final result = await ecocash.makePayment(/* params */);
   } on EcocashApiException catch (e) {
     // Handle API-specific errors
   } catch (e) {
     // Handle other errors
   }
   ```

3. **Use meaningful source references**:
   ```dart
   final ref = ecocash.generateSourceReference();
   // Store this reference for future lookups
   ```

4. **Validate input parameters** before making API calls:
   ```dart
   if (amount <= 0) {
     throw ArgumentError('Amount must be positive');
   }
   ```

## Security Features

- **Data Masking**: Automatic masking of sensitive data in logs
- **Input Validation**: Comprehensive validation prevents injection attacks
- **Secure Headers**: Proper API key and authorization handling
- **Network Security**: Circuit breaker prevents DoS scenarios

## Performance Features

- **Batch Processing**: Concurrent processing with configurable limits
- **Connection Pooling**: Efficient HTTP client reuse
- **Retry Optimization**: Exponential backoff with jitter
- **Circuit Breaker**: Fail-fast for improved resilience
- **Offline Queue**: Handle network interruptions gracefully

## Environment Variables

For production use, consider storing sensitive information in environment variables:

```dart
final ecocash = EcocashApi(
  apiKey: Platform.environment['ECOCASH_API_KEY'] ?? '',
  bearerToken: Platform.environment['ECOCASH_BEARER_TOKEN'],
);
```

## Support

- **API Documentation**: [Ecocash Developer Portal](https://developers.ecocash.co.zw)
- **Test Credentials**: Use placeholder phone numbers for sandbox testing

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

**Author:** Kudah Ndlovu  
**GitHub:** eisax

This SDK is provided for integration with the Ecocash Open API. Please refer to Ecocash's terms of service for API usage guidelines.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Changelog

### v2.0.0 - Enhanced Release
- Added comprehensive input validation
- Implemented retry mechanism with exponential backoff  
- Added batch operations support
- Built-in analytics and reporting
- Advanced logging with data masking
- Circuit breaker pattern implementation
- Offline queue management
- Comprehensive sandbox utilities
- Enhanced security features
- Performance optimizations
- Full type safety with data models
- Flexible configuration system

### v1.0.0 - Initial Release
- Basic payment, refund, and lookup operations
- Simple error handling
- UUID generation
- Basic examples and documentation

---

**Built for the Zimbabwe fintech ecosystem**