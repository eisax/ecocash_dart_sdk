import 'dart:convert';

import 'package:ecocash_dart_sdk/ecocash_dart_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('EcocashApi', () {
    test('should make successful payment request', () async {
      final MockClient mockClient = MockClient((http.Request request) async {
        expect(request.method, equals('POST'));
        expect(request.url.toString(), contains('payment/instant/c2b/sandbox'));
        expect(request.headers['Content-Type'], equals('application/json'));
        expect(request.headers['X-API-KEY'], equals('test-api-key'));

        final Map<String, dynamic> body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['customerMsisdn'], equals('263774222475'));
        expect(body['amount'], equals(100.0));

        return http.Response(
            json.encode(<String, Object>{
              'status': 'success',
              'message': 'Payment successful',
              'ecocashTransactionReference': 'ECO123456789',
              'amount': 100.0,
              'currency': 'USD',
            }),
            200);
      });

      final EcocashApi api = EcocashApi(
        apiKey: 'test-api-key',
        environment: EcocashEnvironment.sandbox,
        client: mockClient,
        enableValidation: false,
        enableLogging: false,
        enableAnalytics: false,
      );

      final PaymentResponse result = await api.makePayment(
        customerMsisdn: '263774222475',
        amount: 100.0,
        reason: 'Test payment',
        currency: 'USD',
      );

      expect(result.status, equals('success'));
      expect(result.ecocashTransactionReference, equals('ECO123456789'));
      expect(result.amount, equals(100.0));
      expect(result.currency, equals('USD'));

      api.dispose();
    });

    test('should handle payment failure', () async {
      final MockClient mockClient = MockClient((http.Request request) async {
        return http.Response(
            json.encode(<String, String>{
              'status': 'failed',
              'message': 'Insufficient funds',
              'errorCode': 'INSUFFICIENT_FUNDS',
            }),
            400);
      });

      final EcocashApi api = EcocashApi(
        apiKey: 'test-api-key',
        environment: EcocashEnvironment.sandbox,
        client: mockClient,
        enableValidation: false,
        enableLogging: false,
        enableAnalytics: false,
      );

      expect(
        () => api.makePayment(
          customerMsisdn: '263774222475',
          amount: 100.0,
          reason: 'Test payment',
          currency: 'USD',
        ),
        throwsA(isA<EcocashApiException>()),
      );

      api.dispose();
    });

    test('should make successful refund request', () async {
      final MockClient mockClient = MockClient((http.Request request) async {
        expect(request.method, equals('POST'));
        expect(request.url.toString(), contains('refund/instant/c2b/sandbox'));

        return http.Response(
            json.encode(<String, Object>{
              'transactionStatus': 'completed',
              'refundCorrelator': 'REF123456789',
              'amount': 50.0,
              'currency': 'USD',
            }),
            200);
      });

      final EcocashApi api = EcocashApi(
        apiKey: 'test-api-key',
        environment: EcocashEnvironment.sandbox,
        client: mockClient,
        enableValidation: false,
        enableLogging: false,
        enableAnalytics: false,
      );

      final RefundResponse result = await api.processRefund(
        originalEcocashTransactionReference: 'ECO123456789',
        sourceMobileNumber: '263774222475',
        amount: 50.0,
        reasonForRefund: 'Customer request',
        currency: 'USD',
      );

      expect(result.transactionStatus, equals('completed'));
      expect(result.refundCorrelator, equals('REF123456789'));
      expect(result.amount, equals(50.0));
      expect(result.currency, equals('USD'));

      api.dispose();
    });

    test('should make successful transaction lookup', () async {
      final MockClient mockClient = MockClient((http.Request request) async {
        expect(request.method, equals('POST'));
        expect(
            request.url.toString(), contains('transaction/c2b/status/sandbox'));

        return http.Response(
            json.encode(<String, Object>{
              'status': 'completed',
              'ecocashReference': 'ECO123456789',
              'amount': 100.0,
              'currency': 'USD',
              'customerMsisdn': '263774222475',
            }),
            200);
      });

      final EcocashApi api = EcocashApi(
        apiKey: 'test-api-key',
        environment: EcocashEnvironment.sandbox,
        client: mockClient,
        enableValidation: false,
        enableLogging: false,
        enableAnalytics: false,
      );

      final TransactionStatus result = await api.lookupTransaction(
        sourceMobileNumber: '263774222475',
        sourceReference: 'REF123456789',
      );

      expect(result.status, equals('completed'));
      expect(result.ecocashReference, equals('ECO123456789'));
      expect(result.amount, equals(100.0));
      expect(result.currency, equals('USD'));

      api.dispose();
    });

    test('should use live environment endpoints', () async {
      final MockClient mockClient = MockClient((http.Request request) async {
        expect(request.url.toString(), contains('payment/instant/c2b/live'));
        return http.Response('{}', 200);
      });

      final EcocashApi api = EcocashApi(
        apiKey: 'test-api-key',
        environment: EcocashEnvironment.live,
        client: mockClient,
        enableValidation: false,
        enableLogging: false,
        enableAnalytics: false,
      );

      try {
        await api.makePayment(
          customerMsisdn: '263774222475',
          amount: 100.0,
          reason: 'Test payment',
          currency: 'USD',
        );
      } catch (e) {
        // Expected to fail due to empty response, but URL was correct
      }

      api.dispose();
    });

    test('should generate unique source references', () {
      final EcocashApi api = EcocashApi(
        apiKey: 'test-api-key',
        environment: EcocashEnvironment.sandbox,
        enableValidation: false,
        enableLogging: false,
        enableAnalytics: false,
      );

      final String ref1 = api.generateSourceReference();
      final String ref2 = api.generateSourceReference();

      expect(ref1, isNotEmpty);
      expect(ref2, isNotEmpty);
      expect(ref1, isNot(equals(ref2)));

      api.dispose();
    });

    test('should process batch payments', () async {
      final MockClient mockClient = MockClient((http.Request request) async {
        return http.Response(
            json.encode(<String, Object>{
              'status': 'success',
              'message': 'Payment successful',
              'ecocashTransactionReference': 'ECO123456789',
              'amount': 100.0,
              'currency': 'USD',
            }),
            200);
      });

      final EcocashApi api = EcocashApi(
        apiKey: 'test-api-key',
        environment: EcocashEnvironment.sandbox,
        client: mockClient,
        enableValidation: false,
        enableLogging: false,
        enableAnalytics: false,
      );

      final List<PaymentRequest> requests = <PaymentRequest>[
        const PaymentRequest(
          customerMsisdn: '263774222475',
          amount: 50.0,
          reason: 'Payment 1',
          currency: 'USD',
          sourceReference: 'REF1',
        ),
        const PaymentRequest(
          customerMsisdn: '263774222475',
          amount: 75.0,
          reason: 'Payment 2',
          currency: 'USD',
          sourceReference: 'REF2',
        ),
      ];

      final BatchOperationResult<PaymentResponse> result = await api.batchPayments(requests);

      expect(result.successful.length, equals(2));
      expect(result.failed.length, equals(0));
      expect(result.successRate, equals(100.0));

      api.dispose();
    });
  });

  group('Environment Configuration', () {
    test('should return correct sandbox endpoints', () {
      expect(
        EnvironmentConfig.getPaymentEndpoint(EcocashEnvironment.sandbox),
        equals(
            'https://developers.ecocash.co.zw/api/v2/payment/instant/c2b/sandbox'),
      );
      expect(
        EnvironmentConfig.getRefundEndpoint(EcocashEnvironment.sandbox),
        equals(
            'https://developers.ecocash.co.zw/api/v2/refund/instant/c2b/sandbox'),
      );
      expect(
        EnvironmentConfig.getTransactionLookupEndpoint(
            EcocashEnvironment.sandbox),
        equals(
            'https://developers.ecocash.co.zw/api/v1/transaction/c2b/status/sandbox'),
      );
    });

    test('should return correct live endpoints', () {
      expect(
        EnvironmentConfig.getPaymentEndpoint(EcocashEnvironment.live),
        equals(
            'https://developers.ecocash.co.zw/api/v2/payment/instant/c2b/live'),
      );
      expect(
        EnvironmentConfig.getRefundEndpoint(EcocashEnvironment.live),
        equals(
            'https://developers.ecocash.co.zw/api/v2/refund/instant/c2b/live'),
      );
      expect(
        EnvironmentConfig.getTransactionLookupEndpoint(EcocashEnvironment.live),
        equals(
            'https://developers.ecocash.co.zw/api/v1/transaction/c2b/status/live'),
      );
    });
  });

  group('Validators', () {
    test('should validate Zimbabwean phone numbers', () {
      expect(EcocashValidators.isValidMobileNumber('263774222475'), isTrue);
      expect(EcocashValidators.isValidMobileNumber('0774222475'), isTrue);
      expect(EcocashValidators.isValidMobileNumber('123456789'), isFalse);
      expect(EcocashValidators.isValidMobileNumber(''), isFalse);
    });

    test('should normalize phone numbers', () {
      expect(EcocashValidators.normalizePhoneNumber('0774222475'),
          equals('263774222475'));
      expect(EcocashValidators.normalizePhoneNumber('263774222475'),
          equals('263774222475'));
      expect(EcocashValidators.normalizePhoneNumber('+263774222475'),
          equals('263774222475'));
    });

    test('should validate amounts', () {
      expect(EcocashValidators.isValidAmount(100.0), isTrue);
      expect(EcocashValidators.isValidAmount(0.01), isTrue);
      expect(EcocashValidators.isValidAmount(0.0), isFalse);
      expect(EcocashValidators.isValidAmount(-50.0), isFalse);
    });

    test('should validate currencies', () {
      expect(EcocashValidators.isValidCurrency('USD'), isTrue);
      expect(EcocashValidators.isValidCurrency('ZWL'), isTrue);
      expect(EcocashValidators.isValidCurrency('INVALID'), isFalse);
    });
  });
}
