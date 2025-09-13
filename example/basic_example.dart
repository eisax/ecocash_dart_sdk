/// Basic example demonstrating core Ecocash SDK functionality
library;

import 'package:ecocash_dart_sdk/ecocash_dart_sdk.dart';

/// Demonstrates basic usage of the Ecocash Dart SDK
Future<void> main() async {
  print('Ecocash Dart SDK - Basic Example\n');

  // Initialize the SDK for sandbox environment
  final EcocashApi ecocash = EcocashApi(
    apiKey: 'your_api_key_here',
    environment: EcocashEnvironment.sandbox,
  );

  try {
    // === MAKING A PAYMENT ===
    print('Making a payment...');
    final String sourceReference = ecocash.generateSourceReference();
    print('Generated source reference: $sourceReference');

    final Map<String, dynamic> paymentRequest = <String, dynamic>{
      'customerMsisdn': '263XXXXXXXXX',
      'amount': 25.50,
      'reason': 'Test payment',
      'currency': 'USD',
      'sourceReference': sourceReference,
    };

    try {
      final PaymentResponse paymentResult = await ecocash.makePayment(
        customerMsisdn: paymentRequest['customerMsisdn'] as String,
        amount: paymentRequest['amount'] as double,
        reason: paymentRequest['reason'] as String,
        currency: paymentRequest['currency'] as String,
        sourceReference: paymentRequest['sourceReference'] as String,
      );

      print('Payment successful!');
      print('   Status: ${paymentResult.status}');
      print(
          '   Ecocash Reference: ${paymentResult.ecocashTransactionReference}');
      print('   Amount: ${paymentResult.amount} ${paymentResult.currency}');
    } catch (e) {
      print('Payment failed: $e');
    }

    print('');

    // === PROCESSING A REFUND ===
    print('Processing a refund...');
    final Map<String, dynamic> refundRequest = <String, dynamic>{
      'originalEcocashTransactionReference': 'ECO123456789',
      'sourceMobileNumber': '263XXXXXXXXX',
      'amount': 10.25,
      'reasonForRefund': 'Customer requested refund',
      'currency': 'USD',
    };

    try {
      final RefundResponse refundResult = await ecocash.processRefund(
        originalEcocashTransactionReference:
            refundRequest['originalEcocashTransactionReference'] as String,
        sourceMobileNumber: refundRequest['sourceMobileNumber'] as String,
        amount: refundRequest['amount'] as double,
        reasonForRefund: refundRequest['reasonForRefund'] as String,
        currency: refundRequest['currency'] as String,
      );

      print(' Refund successful!');
      print('   Status: ${refundResult.transactionStatus}');
      print('   Refund Correlator: ${refundResult.refundCorrelator}');
      print('   Amount: ${refundResult.amount} ${refundResult.currency}');
    } catch (e) {
      print(' Refund failed: $e');
    }

    print('');

    // === LOOKING UP A TRANSACTION ===
    print(' Looking up transaction...');
    final String lookupReference = ecocash.generateSourceReference();

    try {
      final TransactionStatus lookupResult = await ecocash.lookupTransaction(
        sourceMobileNumber: '263XXXXXXXXX',
        sourceReference: lookupReference,
      );

      print(' Lookup successful!');
      print('   Status: ${lookupResult.status}');
      print('   Ecocash Reference: ${lookupResult.ecocashReference}');
      print('   Amount: ${lookupResult.amount} ${lookupResult.currency}');
    } catch (e) {
      print(' Lookup failed: $e');
    }

    print('');

    // === ENVIRONMENT DEMONSTRATION ===
    print(' Environment Configuration:');
    print('   Current Environment: ${ecocash.environment.name}');
    print(
        '   Payment Endpoint: ${EnvironmentConfig.getPaymentEndpoint(ecocash.environment)}');
    print(
        '   Refund Endpoint: ${EnvironmentConfig.getRefundEndpoint(ecocash.environment)}');
    print(
        '   Lookup Endpoint: ${EnvironmentConfig.getTransactionLookupEndpoint(ecocash.environment)}');
  } catch (e) {
    print(' Unexpected error: $e');
  } finally {
    // Clean up resources
    ecocash.dispose();
    print('\n SDK disposed successfully');
  }
}
