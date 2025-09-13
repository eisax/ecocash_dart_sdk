/// Main Ecocash API SDK class
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/api_models.dart';
import '../services/analytics.dart' as analytics;
import '../services/logging.dart';
import '../services/retry_queue.dart';
import '../utils/sandbox_utils.dart';
import '../utils/validators.dart';
import 'environment.dart';
import 'exceptions.dart';

/// Main Ecocash API SDK with comprehensive features
class EcocashApi {

  /// Creates a new Ecocash API instance
  EcocashApi({
    required this.apiKey,
    this.bearerToken,
    this.environment = EcocashEnvironment.sandbox,
    http.Client? client,
    RetryConfig? retryConfig,
    Logger? logger,
    SandboxConfig? sandboxConfig,
    this.enableValidation = true,
    this.enableRetries = true,
    this.enableOfflineQueue = true,
    this.enableLogging = true,
    this.enableAnalytics = true,
  })  : _client = client ?? http.Client(),
        _retryMechanism = RetryMechanism(config: retryConfig),
        _offlineQueue = OfflineQueue(),
        _circuitBreaker = CircuitBreaker(),
        _logger = logger ?? const ConsoleLogger(),
        _analytics = analytics.TransactionAnalytics();
  final String apiKey;
  final String? bearerToken;
  final EcocashEnvironment environment;
  final http.Client _client;
  final Uuid _uuid = const Uuid();

  // Enhanced features
  final RetryMechanism _retryMechanism;
  final OfflineQueue _offlineQueue;
  final CircuitBreaker _circuitBreaker;
  final Logger _logger;
  final analytics.TransactionAnalytics _analytics;

  // Configuration
  final bool enableValidation;
  final bool enableRetries;
  final bool enableOfflineQueue;
  final bool enableLogging;
  final bool enableAnalytics;

  /// Makes a payment
  Future<PaymentResponse> makePayment({
    required String customerMsisdn,
    required double amount,
    required String reason,
    required String currency,
    String? sourceReference,
    bool bypassQueue = false,
  }) async {
    final String actualSourceReference =
        sourceReference ?? generateSourceReference();
    final String requestId = _uuid.v4();

    if (enableLogging) {
      _logger.info('Initiating payment request',
          operation: 'makePayment',
          requestId: requestId,
          metadata: <String, dynamic>{
            'customerMsisdn': enableLogging
                ? DataMasker.maskPhoneNumber(customerMsisdn)
                : customerMsisdn,
            'amount': amount,
            'currency': currency,
            'environment': environment.name,
          });
    }

    // Validation
    if (enableValidation) {
      try {
        EcocashValidators.validatePaymentRequest(
          customerMsisdn: customerMsisdn,
          amount: amount,
          reason: reason,
          currency: currency,
          sourceReference: actualSourceReference,
        );

        // Normalize phone number
        customerMsisdn = EcocashValidators.normalizePhoneNumber(customerMsisdn);
      } catch (e) {
        if (enableLogging) {
          _logger.error('Payment validation failed',
              operation: 'makePayment',
              requestId: requestId,
              metadata: <String, dynamic>{'error': e.toString()});
        }
        rethrow;
      }
    }

    final PaymentRequest request = PaymentRequest(
      customerMsisdn: customerMsisdn,
      amount: amount,
      reason: reason,
      currency: currency,
      sourceReference: actualSourceReference,
    );

    // Check offline queue
    if (enableOfflineQueue && !bypassQueue && !await _isNetworkAvailable()) {
      _queuePaymentForLater(request, requestId);
      throw const EcocashApiException(
          'Network unavailable. Payment queued for later processing.');
    }

    return await _executePaymentRequest(request, requestId);
  }

  /// Processes a refund
  Future<RefundResponse> processRefund({
    required String originalEcocashTransactionReference,
    required String sourceMobileNumber,
    required double amount,
    required String reasonForRefund,
    required String currency,
    String? refundCorrelator,
    String? clientName,
    bool requiresAuth = false,
  }) async {
    final String actualRefundCorrelator =
        refundCorrelator ?? generateRefundCorrelator();
    final String requestId = _uuid.v4();

    if (enableLogging) {
      _logger.info('Initiating refund request',
          operation: 'processRefund',
          requestId: requestId,
          metadata: <String, dynamic>{
            'originalTransactionRef': DataMasker.maskTransactionReference(
                originalEcocashTransactionReference),
            'amount': amount,
            'currency': currency,
            'environment': environment.name,
          });
    }

    // Validation
    if (enableValidation) {
      try {
        EcocashValidators.validateRefundRequest(
          originalEcocashTransactionReference:
              originalEcocashTransactionReference,
          refundCorrelator: actualRefundCorrelator,
          sourceMobileNumber: sourceMobileNumber,
          amount: amount,
          reasonForRefund: reasonForRefund,
          currency: currency,
        );

        // Normalize phone number
        sourceMobileNumber =
            EcocashValidators.normalizePhoneNumber(sourceMobileNumber);
      } catch (e) {
        if (enableLogging) {
          _logger.error('Refund validation failed',
              operation: 'processRefund',
              requestId: requestId,
              metadata: <String, dynamic>{'error': e.toString()});
        }
        rethrow;
      }
    }

    final RefundRequest request = RefundRequest(
      originalEcocashTransactionReference: originalEcocashTransactionReference,
      refundCorrelator: actualRefundCorrelator,
      sourceMobileNumber: sourceMobileNumber,
      amount: amount,
      reasonForRefund: reasonForRefund,
      currency: currency,
      clientName: clientName,
    );

    return await _executeRefundRequest(request, requestId, requiresAuth);
  }

  /// Looks up a transaction status
  Future<TransactionStatus> lookupTransaction({
    required String sourceMobileNumber,
    required String sourceReference,
    bool requiresAuth = false,
  }) async {
    final String requestId = _uuid.v4();

    if (enableLogging) {
      _logger.info('Initiating transaction lookup',
          operation: 'lookupTransaction',
          requestId: requestId,
          metadata: <String, dynamic>{
            'sourceMobileNumber': enableLogging
                ? DataMasker.maskPhoneNumber(sourceMobileNumber)
                : sourceMobileNumber,
            'sourceReference': sourceReference,
            'environment': environment.name,
          });
    }

    // Validation
    if (enableValidation) {
      try {
        EcocashValidators.validateTransactionLookupRequest(
          sourceMobileNumber: sourceMobileNumber,
          sourceReference: sourceReference,
        );

        // Normalize phone number
        sourceMobileNumber =
            EcocashValidators.normalizePhoneNumber(sourceMobileNumber);
      } catch (e) {
        if (enableLogging) {
          _logger.error('Transaction lookup validation failed',
              operation: 'lookupTransaction',
              requestId: requestId,
              metadata: <String, dynamic>{'error': e.toString()});
        }
        rethrow;
      }
    }

    return await _executeLookupRequest(
        sourceMobileNumber, sourceReference, requestId, requiresAuth);
  }

  /// Process multiple payments concurrently
  Future<BatchOperationResult<PaymentResponse>> batchPayments(
    List<PaymentRequest> requests, {
    int concurrency = 3,
  }) async {
    final String batchId = _uuid.v4();
    final int actualConcurrency = concurrency.clamp(1, 10);

    if (enableLogging) {
      _logger.info('Starting batch payment processing',
          operation: 'batchPayments',
          requestId: batchId,
          metadata: <String, dynamic>{
            'batchSize': requests.length,
            'concurrency': actualConcurrency
          });
    }

    final BatchOperationResult<PaymentResponse> result =
        BatchOperationResult<PaymentResponse>();

    // Process in chunks to control concurrency
    for (int i = 0; i < requests.length; i += actualConcurrency) {
      final int end = (i + actualConcurrency < requests.length)
          ? i + actualConcurrency
          : requests.length;
      final List<PaymentRequest> chunk = requests.sublist(i, end);

      final List<Future<void>> futures =
          chunk.asMap().entries.map((MapEntry<int, PaymentRequest> entry) async {
        final int index = i + entry.key;
        final PaymentRequest request = entry.value;

        try {
          final PaymentResponse response = await makePayment(
            customerMsisdn: request.customerMsisdn,
            amount: request.amount,
            reason: request.reason,
            currency: request.currency,
            sourceReference: request.sourceReference,
            bypassQueue: true,
          );
          result.addSuccess(index, response);
        } catch (e) {
          result.addFailure(index, e);
        }
      }).toList();

      await Future.wait(futures);
    }

    if (enableLogging) {
      _logger.info('Batch payment processing completed',
          operation: 'batchPayments',
          requestId: batchId,
          metadata: <String, dynamic>{
            'successful': result.successful.length,
            'failed': result.failed.length,
          });
    }

    return result;
  }

  /// Gets transaction analytics
  analytics.OverallAnalytics getAnalytics(
      {DateTime? startDate, DateTime? endDate}) {
    if (!enableAnalytics) {
      throw StateError(
          'Analytics is disabled. Enable it in constructor to use this feature.');
    }
    return _analytics.getOverallAnalytics(
        startDate: startDate, endDate: endDate);
  }

  /// Gets payment analytics
  analytics.PaymentAnalytics getPaymentAnalytics(
      {DateTime? startDate, DateTime? endDate}) {
    if (!enableAnalytics) {
      throw StateError(
          'Analytics is disabled. Enable it in constructor to use this feature.');
    }
    return _analytics.getPaymentAnalytics(
        startDate: startDate, endDate: endDate);
  }

  /// Process offline queue
  Future<void> processOfflineQueue() async {
    if (!enableOfflineQueue) return;

    if (enableLogging) {
      _logger.info('Processing offline queue',
          operation: 'processOfflineQueue');
    }

    await _offlineQueue.processQueue((QueueItem item) async {
      // Process the queued payment
      await makePayment(
        customerMsisdn: item.request!.customerMsisdn,
        amount: item.request!.amount,
        reason: item.request!.reason,
        currency: item.request!.currency,
        sourceReference: item.request!.sourceReference,
        bypassQueue: true,
      );
    });
  }

  /// Execute payment request
  Future<PaymentResponse> _executePaymentRequest(
      PaymentRequest request, String requestId) async {
    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      final Map<String, dynamic> responseData =
          await _circuitBreaker.execute(() async {
        if (enableRetries) {
          return await _retryMechanism.execute(() async {
            return await _makeHttpPaymentRequest(request);
          });
        } else {
          return await _makeHttpPaymentRequest(request);
        }
      });

      final PaymentResponse response = PaymentResponse.fromJson(responseData);

      // Record analytics
      if (enableAnalytics) {
        _analytics.recordPayment(response);
      }

      if (enableLogging) {
        _logger.info('Payment completed successfully',
            operation: 'makePayment',
            requestId: requestId,
            duration: stopwatch.elapsed,
            metadata: <String, dynamic>{
              'status': response.status,
              'ecocashRef': response.ecocashTransactionReference
            });
      }

      return response;
    } catch (e) {
      if (enableLogging) {
        _logger.error('Payment failed: ${e.toString()}',
            operation: 'makePayment',
            requestId: requestId,
            duration: stopwatch.elapsed);
      }
      rethrow;
    }
  }

  /// Execute refund request
  Future<RefundResponse> _executeRefundRequest(
      RefundRequest request, String requestId, bool requiresAuth) async {
    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      final Map<String, dynamic> responseData =
          await _circuitBreaker.execute(() async {
        if (enableRetries) {
          return await _retryMechanism.execute(() async {
            return await _makeHttpRefundRequest(request, requiresAuth);
          });
        } else {
          return await _makeHttpRefundRequest(request, requiresAuth);
        }
      });

      final RefundResponse response = RefundResponse.fromJson(responseData);

      // Record analytics
      if (enableAnalytics) {
        _analytics.recordRefund(response);
      }

      if (enableLogging) {
        _logger.info('Refund completed successfully',
            operation: 'processRefund',
            requestId: requestId,
            duration: stopwatch.elapsed,
            metadata: <String, dynamic>{
              'status': response.transactionStatus,
              'refundCorrelator': response.refundCorrelator
            });
      }

      return response;
    } catch (e) {
      if (enableLogging) {
        _logger.error('Refund failed: ${e.toString()}',
            operation: 'processRefund',
            requestId: requestId,
            duration: stopwatch.elapsed);
      }
      rethrow;
    }
  }

  /// Execute lookup request
  Future<TransactionStatus> _executeLookupRequest(String sourceMobileNumber,
      String sourceReference, String requestId, bool requiresAuth) async {
    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      final Map<String, dynamic> responseData =
          await _circuitBreaker.execute(() async {
        if (enableRetries) {
          return await _retryMechanism.execute(() async {
            return await _makeHttpLookupRequest(
                sourceMobileNumber, sourceReference, requiresAuth);
          });
        } else {
          return await _makeHttpLookupRequest(
              sourceMobileNumber, sourceReference, requiresAuth);
        }
      });

      final TransactionStatus response =
          TransactionStatus.fromJson(responseData);

      // Record analytics
      if (enableAnalytics) {
        _analytics.recordLookup(response);
      }

      if (enableLogging) {
        _logger.info('Transaction lookup completed successfully',
            operation: 'lookupTransaction',
            requestId: requestId,
            duration: stopwatch.elapsed,
            metadata: <String, dynamic>{
              'status': response.status,
              'ecocashRef': response.ecocashReference
            });
      }

      return response;
    } catch (e) {
      if (enableLogging) {
        _logger.error('Transaction lookup failed: ${e.toString()}',
            operation: 'lookupTransaction',
            requestId: requestId,
            duration: stopwatch.elapsed);
      }
      rethrow;
    }
  }

  /// Make HTTP payment request
  Future<Map<String, dynamic>> _makeHttpPaymentRequest(
      PaymentRequest request) async {
    final Uri uri =
        Uri.parse(EnvironmentConfig.getPaymentEndpoint(environment));

    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
      'X-API-KEY': apiKey,
    };

    if (bearerToken != null) {
      headers['Authorization'] = 'Bearer $bearerToken';
    }

    final Map<String, Object> body = <String, Object>{
      'customerMsisdn': request.customerMsisdn,
      'amount': request.amount,
      'reason': request.reason,
      'currency': request.currency,
      'sourceReference': request.sourceReference,
    };

    final http.Response response = await _client.post(
      uri,
      headers: headers,
      body: json.encode(body),
    );

    return _handleHttpResponse(response);
  }

  /// Make HTTP refund request
  Future<Map<String, dynamic>> _makeHttpRefundRequest(
      RefundRequest request, bool requiresAuth) async {
    final Uri uri = Uri.parse(EnvironmentConfig.getRefundEndpoint(environment));

    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
      'X-API-KEY': apiKey,
    };

    if (bearerToken != null || requiresAuth) {
      headers['Authorization'] = 'Bearer ${bearerToken ?? ''}';
    }

    final Map<String, Object> body = <String, Object>{
      'origionalEcocashTransactionReference':
          request.originalEcocashTransactionReference,
      'refundCorelator': request.refundCorrelator,
      'sourceMobileNumber': request.sourceMobileNumber,
      'amount': request.amount,
      'clientName': request.clientName ?? 'Ecocash SDK',
      'currency': request.currency,
      'reasonForRefund': request.reasonForRefund,
    };

    final http.Response response = await _client.post(
      uri,
      headers: headers,
      body: json.encode(body),
    );

    return _handleHttpResponse(response);
  }

  /// Make HTTP lookup request
  Future<Map<String, dynamic>> _makeHttpLookupRequest(String sourceMobileNumber,
      String sourceReference, bool requiresAuth) async {
    final Uri uri =
        Uri.parse(EnvironmentConfig.getTransactionLookupEndpoint(environment));

    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
      'X-API-KEY': apiKey,
    };

    if (bearerToken != null || requiresAuth) {
      headers['Authorization'] = 'Bearer ${bearerToken ?? ''}';
    }

    final Map<String, Object> body = <String, Object>{
      'sourceMobileNumber': sourceMobileNumber,
      'sourceReference': sourceReference,
    };

    final http.Response response = await _client.post(
      uri,
      headers: headers,
      body: json.encode(body),
    );

    return _handleHttpResponse(response);
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleHttpResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (response.body.isEmpty) {
          throw EcocashApiException('Empty response body',
              statusCode: response.statusCode);
        }
        return json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw EcocashApiException('Invalid JSON response: ${response.body}',
            statusCode: response.statusCode);
      }
    } else {
      String message = 'HTTP ${response.statusCode}';
      Map<String, dynamic>? responseData;

      try {
        if (response.body.isNotEmpty) {
          responseData = json.decode(response.body) as Map<String, dynamic>;
          message = responseData['message'] ?? responseData['error'] ?? message;
        }
      } catch (_) {
        // Keep default message if JSON parsing fails
      }

      throw EcocashApiException(message,
          statusCode: response.statusCode, response: responseData);
    }
  }

  /// Check network availability
  Future<bool> _isNetworkAvailable() async {
    try {
      final List<InternetAddress> result =
          await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Queue payment for later processing
  void _queuePaymentForLater(PaymentRequest request, String requestId) {
    _offlineQueue.addPayment(request);

    if (enableLogging) {
      _logger.info('Payment queued for offline processing',
          operation: 'makePayment', requestId: requestId);
    }
  }

  /// Generates a unique source reference
  String generateSourceReference() => _uuid.v4();

  /// Generates a unique refund correlator
  String generateRefundCorrelator() => _uuid.v4();

  /// Disposes resources
  void dispose() {
    _client.close();
    _offlineQueue.dispose();

    if (enableLogging) {
      _logger.info('SDK disposed', operation: 'dispose');
    }
  }
}
