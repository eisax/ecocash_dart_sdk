import 'package:ecocash_dart_sdk/ecocash_dart_sdk.dart';

/// Example demonstrating how to use the Ecocash Dart SDK
Future<void> main() async {
  // Initialize the SDK with your API key
  final EcocashApi ecocash = EcocashApi(
    apiKey: 'your_api_key_here',
    environment: EcocashEnvironment.sandbox,
  );

  try {
    print(' Ecocash Dart SDK Example\n');

    // Example 1: Make a payment
    print(' Making a payment...');
    final String sourceRef = ecocash.generateSourceReference();
    print('Generated source reference: $sourceRef');

    final PaymentResponse paymentResult = await ecocash.makePayment(
      customerMsisdn: '263XXXXXXXXX',
      amount: 10.50,
      reason: 'Test payment from Dart SDK',
      currency: 'USD',
      sourceReference: sourceRef,
    );

    print(' Payment initiated successfully:');
    print('Response: $paymentResult\n');

    // Extract transaction reference for refund example
    final String ecocashTransactionRef = paymentResult.ecocashTransactionReference ??
        'DUMMY_TRANSACTION_REF_123';

    // Example 2: Process a refund
    print(' Processing a refund...');
    final RefundResponse refundResult = await ecocash.processRefund(
      originalEcocashTransactionReference: ecocashTransactionRef,
      sourceMobileNumber: '263XXXXXXXXX',
      amount: 5.25,
      reasonForRefund: 'Partial refund - Test from Dart SDK',
      currency: 'USD',
    );

    print(' Refund processed successfully:');
    print('Response: $refundResult\n');

    // Example 3: Lookup transaction status
    print(' Looking up transaction status...');
    final TransactionStatus lookupResult = await ecocash.lookupTransaction(
      sourceMobileNumber: '263XXXXXXXXX',
      sourceReference: sourceRef,
    );

    print(' Transaction lookup completed:');
    print('Response: $lookupResult\n');

    print('All operations completed successfully!');
  } on EcocashApiException catch (e) {
    print(' Ecocash API Error: $e');
    if (e.response != null) {
      print('Full error response: ${e.response}');
    }
  } catch (e) {
    print(' Unexpected error: $e');
  } finally {
    // Clean up resources
    ecocash.dispose();
  }
}

/// Example showing different configuration options
void configurationExample() {
  print('\n🔧 Configuration Examples:\n');

  // Basic configuration
  final EcocashApi basicEcocash = EcocashApi(
    apiKey: 'your_api_key_here',
  );

  // Custom base URL (for different environments)
  final EcocashApi customUrlEcocash = EcocashApi(
    apiKey: 'your_api_key_here',
    environment: EcocashEnvironment.sandbox,
  );

  // With bearer token for authenticated endpoints
  final EcocashApi authenticatedEcocash = EcocashApi(
    apiKey: 'your_api_key_here',
    bearerToken: 'your_bearer_token_here',
  );

  print(' Basic configuration: API Key only');
  print(' Custom URL configuration: Different base URL');
  print(' Authenticated configuration: With bearer token');

  // Remember to dispose when done
  basicEcocash.dispose();
  customUrlEcocash.dispose();
  authenticatedEcocash.dispose();
}

/// Example showing error handling
void errorHandlingExample() async {
  final EcocashApi ecocash = EcocashApi(apiKey: 'invalid_key');

  try {
    await ecocash.makePayment(
      customerMsisdn: '263XXXXXXXXX',
      amount: 10.50,
      reason: 'Test payment',
      currency: 'USD',
    );
  } on EcocashApiException catch (e) {
    print('\n Error Handling Example:');
    print('Error message: ${e.message}');
    print('Status code: ${e.statusCode}');
    print('Full response: ${e.response}');
  } finally {
    ecocash.dispose();
  }
}

/// Example showing advanced usage patterns
void advancedUsageExample() async {
  final EcocashApi ecocash = EcocashApi(
    apiKey: '1wddI46HBW3pK7pH32wgr3st9wIM7E4w',
    bearerToken: 'optional_bearer_token',
  );

  try {
    print('\n Advanced Usage Examples:\n');

    // Generate multiple source references
    final List<String> refs = List.generate(3, (_) => ecocash.generateSourceReference());
    print('Generated references: $refs');

    // Batch operations (in real scenarios, you might want to handle these concurrently)
    for (int i = 0; i < 3; i++) {
      print('Processing payment ${i + 1}/3...');

      try {
        await ecocash.makePayment(
          customerMsisdn: '263XXXXXXXXX',
          amount: (i + 1) * 5.0, // 5.0, 10.0, 15.0
          reason: 'Batch payment #${i + 1}',
          currency: 'USD',
          sourceReference: refs[i],
        );
        print(' Payment ${i + 1} completed');
      } catch (e) {
        print(' Payment ${i + 1} failed: $e');
      }
    }

    // Lookup all transactions
    for (int i = 0; i < refs.length; i++) {
      try {
        final TransactionStatus result = await ecocash.lookupTransaction(
          sourceMobileNumber: '263XXXXXXXXX',
          sourceReference: refs[i],
        );
        print('Transaction ${i + 1} status: ${result.status}');
      } catch (e) {
        print(' Lookup ${i + 1} failed: $e');
      }
    }
  } finally {
    ecocash.dispose();
  }
}
