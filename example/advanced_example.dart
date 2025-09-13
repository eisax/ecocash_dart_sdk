/// Advanced example showcasing all Ecocash SDK features
library;

import 'package:ecocash_dart_sdk/ecocash_dart_sdk.dart';
import 'package:ecocash_dart_sdk/src/services/analytics.dart' as analytics;

/// Demonstrates advanced features of the Ecocash Dart SDK
Future<void> main() async {
  print('Ecocash Dart SDK - Advanced Features Demonstration\n');

  // === ADVANCED CONFIGURATION ===
  print(' === ADVANCED SDK CONFIGURATION ===\n');

  final EcocashApi ecocash = EcocashApi(
    apiKey: 'your_api_key_here',
    environment: EcocashEnvironment.sandbox,
    bearerToken: 'optional_bearer_token',
    enableValidation: true,
    enableRetries: true,
    enableOfflineQueue: true,
    enableLogging: true,
    enableAnalytics: true,
    retryConfig: const RetryConfig(
      maxAttempts: 3,
      initialDelay: Duration(seconds: 1),
      maxDelay: Duration(seconds: 10),
    ),
    logger: CompositeLogger(<Logger>[
      const ConsoleLogger(minLevel: LogLevel.info),
      FileLogger(
        filePath: 'logs/ecocash_sdk.log',
        minLevel: LogLevel.debug,
      ),
    ]),
    sandboxConfig: const SandboxConfig(
      enableMockResponses: false,
    ),
  );

  try {
    // === VALIDATION EXAMPLES ===
    print(' === INPUT VALIDATION DEMONSTRATION ===\n');

    final List<Map<String, dynamic>> validationTests = <Map<String, dynamic>>[
      <String, dynamic>{
        'type': 'phone',
        'value': '263XXXXXXXXX',
        'description': 'Valid Zimbabwean number (international format)'
      },
      <String, dynamic>{
        'type': 'phone',
        'value': '0774222475',
        'description': 'Valid Zimbabwean number (local format)'
      },
      <String, dynamic>{
        'type': 'phone',
        'value': '123456789',
        'description': 'Invalid phone number'
      },
      <String, dynamic>{'type': 'amount', 'value': 100.50, 'description': 'Valid amount'},
      <String, dynamic>{
        'type': 'amount',
        'value': -50.0,
        'description': 'Invalid amount (negative)'
      },
      <String, dynamic>{'type': 'currency', 'value': 'USD', 'description': 'Valid currency'},
      <String, dynamic>{
        'type': 'currency',
        'value': 'INVALID',
        'description': 'Invalid currency'
      },
    ];

    for (final Map<String, dynamic> test in validationTests) {
      print('Testing: ${test['description']}');
      bool isValid = false;
      String? normalized;

      try {
        switch (test['type']) {
          case 'phone':
            isValid =
                EcocashValidators.isValidMobileNumber(test['value'] as String);
            if (isValid) {
              normalized = EcocashValidators.normalizePhoneNumber(
                  test['value'] as String);
              final NetworkOperator? operator =
                  EcocashValidators.getNetworkOperator(test['value'] as String);
              print('   Result: Valid');
              print('   Normalized: $normalized');
              print('   Operator: ${operator?.name ?? 'Unknown'}');
            } else {
              print('   Result: Invalid');
            }
            break;
          case 'amount':
            isValid = EcocashValidators.isValidAmount(test['value'] as double);
            print('   Result: ${isValid ? 'Valid' : 'Invalid'}');
            break;
          case 'currency':
            isValid =
                EcocashValidators.isValidCurrency(test['value'] as String);
            print('   Result: ${isValid ? 'Valid' : 'Invalid'}');
            break;
        }
      } catch (e) {
        print('   Result: Invalid ($e)');
      }
      print('');
    }

    // === BATCH OPERATIONS ===
    print(' === BATCH OPERATIONS DEMONSTRATION ===\n');

    final List<PaymentRequest> batchRequests = <PaymentRequest>[
      PaymentRequest(
        customerMsisdn: '263XXXXXXXXX',
        amount: 10.0,
        reason: 'Batch payment 1',
        currency: 'USD',
        sourceReference: ecocash.generateSourceReference(),
      ),
      PaymentRequest(
        customerMsisdn: '263XXXXXXXXX',
        amount: 15.5,
        reason: 'Batch payment 2',
        currency: 'USD',
        sourceReference: ecocash.generateSourceReference(),
      ),
      PaymentRequest(
        customerMsisdn: '263774222476', // This will fail in sandbox
        amount: 20.0,
        reason: 'Batch payment 3',
        currency: 'USD',
        sourceReference: ecocash.generateSourceReference(),
      ),
      PaymentRequest(
        customerMsisdn: '263XXXXXXXXX',
        amount: 5.25,
        reason: 'Batch payment 4',
        currency: 'USD',
        sourceReference: ecocash.generateSourceReference(),
      ),
    ];

    print('Processing ${batchRequests.length} payments in batch...');
    final BatchOperationResult<PaymentResponse> batchResult =
        await ecocash.batchPayments(batchRequests, concurrency: 2);

    print('\n Batch Operation Results:');
    print('   Total Processed: ${batchResult.totalProcessed}');
    print('   Successful: ${batchResult.successful.length}');
    print('   Failed: ${batchResult.failed.length}');
    print('   Success Rate: ${batchResult.successRate.toStringAsFixed(1)}%');

    if (batchResult.successful.isNotEmpty) {
      print('\nSuccessful Payments:');
      for (final MapEntry<int, PaymentResponse> entry
          in batchResult.successful.entries) {
        final PaymentResponse response = entry.value;
        print(
            '   - ${response.ecocashTransactionReference}: ${response.amount} ${response.currency}');
      }
    }

    if (batchResult.failed.isNotEmpty) {
      print('\n Failed Payments:');
      for (final MapEntry<int, dynamic> entry in batchResult.failed.entries) {
        print('   - Request ${entry.key}: ${entry.value}');
      }
    }

    print('');

    // === ANALYTICS DEMONSTRATION ===
    print(' === ANALYTICS AND REPORTING DEMONSTRATION ===\n');

    // Get overall analytics
    final analytics.OverallAnalytics overallAnalytics = ecocash.getAnalytics();
    print(' Overall Analytics:');
    print('   Total Transactions: ${overallAnalytics.totalTransactions}');
    print('   Net Amount: ${overallAnalytics.netAmount.toStringAsFixed(2)}');

    // Get payment analytics
    final analytics.PaymentAnalytics paymentAnalytics =
        ecocash.getPaymentAnalytics();
    print('\n Payment Analytics:');
    print('   Total Payments: ${paymentAnalytics.totalPayments}');
    print('   Successful: ${paymentAnalytics.successfulPayments}');
    print('   Failed: ${paymentAnalytics.failedPayments}');
    print(
        '   Success Rate: ${paymentAnalytics.successRate.toStringAsFixed(1)}%');
    print('   Total Amount: ${paymentAnalytics.totalAmount}');
    print('   Average Amount: ${paymentAnalytics.averageAmount}');
    print('   Currency Breakdown:');
    for (final MapEntry<String, double> entry
        in paymentAnalytics.currencyBreakdown.entries) {
      print('     ${entry.key}: ${entry.value}');
    }

    print('');

    // === SANDBOX FEATURES ===
    print(' === SANDBOX AND TESTING FEATURES ===\n');

    print('Available Test Scenarios:');
    final List<Map<String, dynamic>> scenarios =
        SandboxUtils.getTestScenarios();
    for (final Map<String, dynamic> scenario in scenarios) {
      print(' ${scenario['name']}');
      print('   Phone: ${scenario['phone']}');
      print('   Expected: ${scenario['expected']}');
      print('   Description: ${scenario['description']}\n');
    }

    print('Test Phone Number Analysis:');
    final List<String> testPhones = <String>[
      '263XXXXXXXXX',
      '263774222476',
      '263774222477',
      '263774222478',
      '263774222479'
    ];

    for (final String phone in testPhones) {
      final String scenario = SandboxUtils.getExpectedBehavior(phone);
      print(' $phone: $scenario');
    }

    print('');

    // === ADVANCED FEATURES ===
    print(' === ADVANCED FEATURES DEMONSTRATION ===\n');

    // Offline queue status
    print(' Offline Queue Status:');
    print('   Enabled: ${ecocash.enableOfflineQueue}');
    // Note: Queue size and isEmpty would need to be exposed in the API

    // Data masking examples
    print('\n Data Masking Examples:');
    final Map<String, dynamic> sensitiveData = <String, dynamic>{
      'customerMsisdn': '263XXXXXXXXX',
      'apiKey': 'very_secret_api_key_12345',
      'pin': '1234',
      'amount': 100.5,
      'publicInfo': 'This is not sensitive'
    };

    final Map<String, dynamic> maskedData = <String, dynamic>{
      'customerMsisdn':
          DataMasker.maskPhoneNumber(sensitiveData['customerMsisdn'] as String),
      'apiKey': DataMasker.maskApiKey(sensitiveData['apiKey'] as String),
      'pin': DataMasker.maskPin(sensitiveData['pin'] as String),
      'amount': sensitiveData['amount'],
      'publicInfo': sensitiveData['publicInfo']
    };

    print('   Original Data: $sensitiveData');
    print('   Masked Data: $maskedData');

    // UUID generation
    print('\n UUID Generation:');
    print('   Source Reference: ${ecocash.generateSourceReference()}');
    print('   Refund Correlator: ${ecocash.generateRefundCorrelator()}');

    // Validation examples
    print('\n Validation Examples:');
    try {
      EcocashValidators.validatePaymentRequest(
        customerMsisdn: '263XXXXXXXXX',
        amount: 100.0,
        reason: 'Test payment',
        currency: 'USD',
        sourceReference: ecocash.generateSourceReference(),
      );
      print('   Payment validation: Passed');
    } catch (e) {
      print('   Payment validation: Failed ($e)');
    }

    try {
      EcocashValidators.validateRefundRequest(
        originalEcocashTransactionReference: 'ECO123456789',
        refundCorrelator: ecocash.generateRefundCorrelator(),
        sourceMobileNumber: '263XXXXXXXXX',
        amount: 50.0,
        reasonForRefund: 'Test refund',
        currency: 'USD',
        clientName: 'Test Client',
      );
      print('   Refund validation: Passed');
    } catch (e) {
      print('   Refund validation: Failed ($e)');
    }

    print('\n');
  } catch (e) {
    print('Unexpected error: $e');
  } finally {
    // Clean up resources
    ecocash.dispose();
    print('All advanced features demonstrated successfully!');
  }
}
