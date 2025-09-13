/// Retry mechanism and queue system for Ecocash API
library;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import '../models/api_models.dart';

/// Retry configuration
class RetryConfig {

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.exponentialBackoff = true,
    this.retryableStatusCodes = const <int>[408, 429, 500, 502, 503, 504],
  });
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool exponentialBackoff;
  final List<int> retryableStatusCodes;

  /// Default configuration for network operations
  static const RetryConfig defaultConfig = RetryConfig();

  /// Aggressive retry configuration
  static const RetryConfig aggressive = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 500),
    backoffMultiplier: 1.5,
  );

  /// Conservative retry configuration
  static const RetryConfig conservative = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(seconds: 2),
    backoffMultiplier: 3.0,
  );
}

/// Queue item for offline operations
class QueueItem {

  const QueueItem({
    required this.id,
    required this.operation,
    required this.data,
    required this.createdAt,
    this.attempts = 0,
    this.nextRetryAt,
    this.request,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? createdAt;

  factory QueueItem.fromJson(Map<String, dynamic> json) => QueueItem(
        id: json['id'] as String,
        operation: json['operation'] as String,
        data: Map<String, dynamic>.from(json['data'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        attempts: json['attempts'] as int,
        nextRetryAt: json['nextRetryAt'] != null
            ? DateTime.parse(json['nextRetryAt'] as String)
            : null,
      );
  final String id;
  final String operation;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int attempts;
  final DateTime? nextRetryAt;
  final PaymentRequest? request;
  final DateTime timestamp;

  QueueItem copyWith({
    String? id,
    String? operation,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? attempts,
    DateTime? nextRetryAt,
    PaymentRequest? request,
    DateTime? timestamp,
  }) {
    return QueueItem(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      request: request ?? this.request,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'operation': operation,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
        'nextRetryAt': nextRetryAt?.toIso8601String(),
      };

  @override
  String toString() =>
      'QueueItem(id: $id, operation: $operation, attempts: $attempts)';
}

/// Retry mechanism with exponential backoff
class RetryMechanism {

  const RetryMechanism({RetryConfig? config}) : config = config ?? const RetryConfig();
  final RetryConfig config;

  /// Executes a function with retry logic
  Future<T> execute<T>(Future<T> Function() operation) async {
    int attempts = 0;
    Duration delay = config.initialDelay;

    while (attempts < config.maxAttempts) {
      attempts++;

      try {
        return await operation();
      } catch (e) {
        final bool shouldRetry = _shouldRetry(e, attempts);

        if (!shouldRetry) {
          rethrow;
        }

        if (attempts < config.maxAttempts) {
          await Future.delayed(delay);
          delay = _calculateNextDelay(delay, attempts);
        } else {
          rethrow;
        }
      }
    }

    throw StateError('Retry mechanism failed - this should not happen');
  }

  /// Determines if an error should trigger a retry
  bool _shouldRetry(error, int attempts) {
    if (attempts >= config.maxAttempts) {
      return false;
    }

    // Check for specific error types that should be retried
    if (error.toString().contains('Network error') ||
        error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException')) {
      return true;
    }

    // Check for retryable HTTP status codes
    if (error.toString().contains('Status:')) {
      final RegExp statusPattern = RegExp(r'Status:\s*(\d+)');
      final Match? match = statusPattern.firstMatch(error.toString());
      if (match != null) {
        final int statusCode = int.parse(match.group(1)!);
        return config.retryableStatusCodes.contains(statusCode);
      }
    }

    return false;
  }

  /// Calculates the next delay using backoff strategy
  Duration _calculateNextDelay(Duration currentDelay, int attempts) {
    if (!config.exponentialBackoff) {
      return config.initialDelay;
    }

    final Duration nextDelay = Duration(
      milliseconds:
          (currentDelay.inMilliseconds * config.backoffMultiplier).round(),
    );

    return nextDelay.compareTo(config.maxDelay) > 0
        ? config.maxDelay
        : nextDelay;
  }

}

/// Offline queue manager
class OfflineQueue {
  final Queue<QueueItem> _queue = Queue<QueueItem>();
  final StreamController<QueueItem> _processedController =
      StreamController<QueueItem>.broadcast();
  final StreamController<QueueItem> _failedController =
      StreamController<QueueItem>.broadcast();

  Timer? _processingTimer;
  bool _isProcessing = false;

  /// Stream of successfully processed items
  Stream<QueueItem> get processedItems => _processedController.stream;

  /// Stream of failed items
  Stream<QueueItem> get failedItems => _failedController.stream;

  /// Current queue size
  int get queueSize => _queue.length;

  /// Whether the queue is empty
  bool get isEmpty => _queue.isEmpty;

  /// Add a payment request to the queue
  void addPayment(PaymentRequest request) {
    final QueueItem item = QueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operation: 'payment',
      data: request.toJson(),
      createdAt: DateTime.now(),
      request: request,
      attempts: 0,
    );
    _queue.add(item);
  }

  /// Process the queue with a callback function
  Future<void> processQueue(Future<void> Function(QueueItem) processor) async {
    if (_isProcessing || _queue.isEmpty) {
      return;
    }
    
    _isProcessing = true;
    
    while (_queue.isNotEmpty) {
      final QueueItem item = _queue.removeFirst();
      
      try {
        await processor(item);
        _processedController.add(item);
      } catch (e) {
        _failedController.add(item);
        // Re-queue with incremented attempts if not exceeded max
        if (item.attempts < 3) {
          final QueueItem retryItem = QueueItem(
            id: item.id,
            operation: item.operation,
            data: item.data,
            createdAt: item.createdAt,
            request: item.request,
            attempts: item.attempts + 1,
          );
          _queue.add(retryItem);
        }
      }
    }
    
    _isProcessing = false;
  }

  /// Adds an item to the queue
  void enqueue(QueueItem item) {
    _queue.add(item);
    _startProcessing();
  }

  /// Adds multiple items to the queue
  void enqueueAll(List<QueueItem> items) {
    _queue.addAll(items);
    _startProcessing();
  }

  /// Removes and returns the next item from the queue
  QueueItem? dequeue() {
    return _queue.isEmpty ? null : _queue.removeFirst();
  }

  /// Peeks at the next item without removing it
  QueueItem? peek() {
    return _queue.isEmpty ? null : _queue.first;
  }

  /// Clears all items from the queue
  void clear() {
    _queue.clear();
  }

  /// Gets all items in the queue
  List<QueueItem> getAll() {
    return List<QueueItem>.from(_queue);
  }

  /// Removes items older than the specified duration
  void removeExpiredItems(Duration maxAge) {
    final DateTime cutoff = DateTime.now().subtract(maxAge);
    _queue.removeWhere((QueueItem item) => item.createdAt.isBefore(cutoff));
  }

  /// Starts automatic processing of queue items
  void _startProcessing() {
    if (_isProcessing || _queue.isEmpty) {
      return;
    }

    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _processNextItem();
    });
  }

  /// Processes the next item in the queue
  void _processNextItem() {
    if (_isProcessing || _queue.isEmpty) {
      return;
    }

    _isProcessing = true;

    final QueueItem? item = peek();
    if (item == null) {
      _isProcessing = false;
      return;
    }

    // Check if it's time to retry this item
    if (item.nextRetryAt != null &&
        DateTime.now().isBefore(item.nextRetryAt!)) {
      _isProcessing = false;
      return;
    }

    // Remove the item from queue for processing
    dequeue();

    // This would be implemented by the SDK to actually process the item
    // For now, we'll simulate processing
    _simulateProcessing(item).then((bool success) {
      if (success) {
        _processedController.add(item);
      } else {
        _handleFailedItem(item);
      }
      _isProcessing = false;
    }).catchError((error) {
      _handleFailedItem(item);
      _isProcessing = false;
    });
  }

  /// Simulates processing an item (to be replaced with actual API calls)
  Future<bool> _simulateProcessing(QueueItem item) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Simulate 80% success rate
    return math.Random().nextDouble() > 0.2;
  }

  /// Handles a failed item
  void _handleFailedItem(QueueItem item) {
    const int maxRetries = 3;

    if (item.attempts < maxRetries) {
      // Schedule for retry with exponential backoff
      final Duration backoffDelay = Duration(
        seconds: math.pow(2, item.attempts).toInt(),
      );

      final QueueItem retryItem = item.copyWith(
        attempts: item.attempts + 1,
        nextRetryAt: DateTime.now().add(backoffDelay),
      );

      enqueue(retryItem);
    } else {
      // Max retries exceeded, mark as failed
      _failedController.add(item);
    }
  }

  /// Stops queue processing
  void stop() {
    _processingTimer?.cancel();
    _processingTimer = null;
    _isProcessing = false;
  }

  /// Disposes of the queue and closes streams
  void dispose() {
    stop();
    _processedController.close();
    _failedController.close();
    clear();
  }
}

/// Circuit breaker pattern implementation
class CircuitBreaker {

  CircuitBreaker({
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 60),
    this.retryTimeout = const Duration(seconds: 30),
  });
  final int failureThreshold;
  final Duration timeout;
  final Duration retryTimeout;

  int _failureCount = 0;
  DateTime? _lastFailureTime;
  CircuitBreakerState _state = CircuitBreakerState.closed;

  /// Current state of the circuit breaker
  CircuitBreakerState get state => _state;

  /// Executes an operation through the circuit breaker
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_state == CircuitBreakerState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitBreakerState.halfOpen;
      } else {
        throw const CircuitBreakerOpenException('Circuit breaker is open');
      }
    }

    try {
      final T result = await operation();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  /// Handles successful operation
  void _onSuccess() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
  }

  /// Handles failed operation
  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
    }
  }

  /// Determines if circuit breaker should attempt to reset
  bool _shouldAttemptReset() {
    return _lastFailureTime != null &&
        DateTime.now().difference(_lastFailureTime!) > retryTimeout;
  }

  /// Resets the circuit breaker
  void reset() {
    _failureCount = 0;
    _lastFailureTime = null;
    _state = CircuitBreakerState.closed;
  }
}

/// Circuit breaker states
enum CircuitBreakerState { closed, open, halfOpen }

/// Exception thrown when circuit breaker is open
class CircuitBreakerOpenException implements Exception {
  const CircuitBreakerOpenException(this.message);
  final String message;

  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}
