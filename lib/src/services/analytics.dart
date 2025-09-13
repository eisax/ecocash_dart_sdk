/// Analytics and reporting system for Ecocash API transactions
library;

import '../models/api_models.dart';

/// Transaction analytics engine
class TransactionAnalytics {
  final List<PaymentResponse> _payments = <PaymentResponse>[];
  final List<RefundResponse> _refunds = <RefundResponse>[];
  final List<TransactionStatus> _lookups = <TransactionStatus>[];

  /// Adds a payment response to analytics
  void recordPayment(PaymentResponse payment) {
    _payments.add(payment);
  }

  /// Adds a refund response to analytics
  void recordRefund(RefundResponse refund) {
    _refunds.add(refund);
  }

  /// Adds a transaction lookup to analytics
  void recordLookup(TransactionStatus lookup) {
    _lookups.add(lookup);
  }

  /// Gets payment analytics for a date range
  PaymentAnalytics getPaymentAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final List<PaymentResponse> filteredPayments = _filterPaymentsByDate(
      _payments,
      startDate,
      endDate,
    );

    return _calculatePaymentAnalytics(filteredPayments);
  }

  /// Gets refund analytics for a date range
  RefundAnalytics getRefundAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final List<RefundResponse> filteredRefunds = _filterRefundsByDate(
      _refunds,
      startDate,
      endDate,
    );

    return _calculateRefundAnalytics(filteredRefunds);
  }

  /// Gets overall transaction analytics
  OverallAnalytics getOverallAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final PaymentAnalytics paymentAnalytics = getPaymentAnalytics(
      startDate: startDate,
      endDate: endDate,
    );
    final RefundAnalytics refundAnalytics = getRefundAnalytics(
      startDate: startDate,
      endDate: endDate,
    );

    return OverallAnalytics(
      totalTransactions:
          paymentAnalytics.totalPayments + refundAnalytics.totalRefunds,
      netAmount: paymentAnalytics.totalAmount - refundAnalytics.totalAmount,
      paymentAnalytics: paymentAnalytics,
      refundAnalytics: refundAnalytics,
    );
  }

  /// Filters payments by date range
  List<PaymentResponse> _filterPaymentsByDate(
    List<PaymentResponse> payments,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return payments.where((PaymentResponse payment) {
      if (payment.transactionDateTime == null) return false;
      final DateTime transactionDate = payment.transactionDateTime!;

      if (startDate != null && transactionDate.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && transactionDate.isAfter(endDate)) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Filters refunds by date range
  List<RefundResponse> _filterRefundsByDate(
    List<RefundResponse> refunds,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return refunds.where((RefundResponse refund) {
      if (refund.transactionDateTime == null) return false;
      final DateTime transactionDate = refund.transactionDateTime!;

      if (startDate != null && transactionDate.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && transactionDate.isAfter(endDate)) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Calculates payment analytics
  PaymentAnalytics _calculatePaymentAnalytics(List<PaymentResponse> payments) {
    if (payments.isEmpty) {
      return const PaymentAnalytics(
        totalPayments: 0,
        successfulPayments: 0,
        failedPayments: 0,
        totalAmount: 0.0,
        averageAmount: 0.0,
        currencyBreakdown: <String, double>{},
        topCustomers: <CustomerAnalytics>[],
      );
    }

    final int totalPayments = payments.length;
    final int successfulPayments = payments
        .where((PaymentResponse payment) => payment.status.toLowerCase() == 'success')
        .length;
    final int failedPayments = totalPayments - successfulPayments;

    final double totalAmount = payments
        .map((PaymentResponse payment) => payment.amount ?? 0.0)
        .fold(0.0, (double sum, double amount) => sum + amount);

    final Map<String, double> currencyBreakdown = <String, double>{};
    for (final PaymentResponse payment in payments) {
      final String currency = payment.currency ?? 'USD';
      final double amount = payment.amount ?? 0.0;
      currencyBreakdown[currency] =
          (currencyBreakdown[currency] ?? 0.0) + amount;
    }

    return PaymentAnalytics(
      totalPayments: totalPayments,
      successfulPayments: successfulPayments,
      failedPayments: failedPayments,
      totalAmount: totalAmount,
      averageAmount: totalAmount / totalPayments,
      currencyBreakdown: currencyBreakdown,
      topCustomers: const <CustomerAnalytics>[], // Simplified for now
    );
  }

  /// Calculates refund analytics
  RefundAnalytics _calculateRefundAnalytics(List<RefundResponse> refunds) {
    if (refunds.isEmpty) {
      return const RefundAnalytics(
        totalRefunds: 0,
        successfulRefunds: 0,
        failedRefunds: 0,
        totalAmount: 0.0,
        averageAmount: 0.0,
      );
    }

    final int totalRefunds = refunds.length;
    final int successfulRefunds = refunds
        .where(
            (RefundResponse refund) => refund.transactionStatus.toLowerCase() == 'completed')
        .length;
    final int failedRefunds = totalRefunds - successfulRefunds;

    final double totalAmount = refunds
        .map((RefundResponse refund) => refund.amount ?? 0.0)
        .fold(0.0, (double sum, double amount) => sum + amount);

    return RefundAnalytics(
      totalRefunds: totalRefunds,
      successfulRefunds: successfulRefunds,
      failedRefunds: failedRefunds,
      totalAmount: totalAmount,
      averageAmount: totalAmount / totalRefunds,
    );
  }

  /// Clears all analytics data
  void clearData() {
    _payments.clear();
    _refunds.clear();
    _lookups.clear();
  }
}

/// Customer analytics model
class CustomerAnalytics {

  const CustomerAnalytics({
    required this.customerId,
    required this.totalTransactions,
    required this.totalAmount,
    required this.averageAmount,
    required this.successfulTransactions,
    required this.failedTransactions,
  });
  final String customerId;
  final int totalTransactions;
  final double totalAmount;
  final double averageAmount;
  final int successfulTransactions;
  final int failedTransactions;
}

/// Payment analytics model
class PaymentAnalytics {

  const PaymentAnalytics({
    required this.totalPayments,
    required this.successfulPayments,
    required this.failedPayments,
    required this.totalAmount,
    required this.averageAmount,
    required this.currencyBreakdown,
    required this.topCustomers,
  });
  final int totalPayments;
  final int successfulPayments;
  final int failedPayments;
  final double totalAmount;
  final double averageAmount;
  final Map<String, double> currencyBreakdown;
  final List<CustomerAnalytics> topCustomers;

  double get successRate =>
      totalPayments == 0 ? 0.0 : (successfulPayments / totalPayments) * 100;
}

/// Refund analytics model
class RefundAnalytics {

  const RefundAnalytics({
    required this.totalRefunds,
    required this.successfulRefunds,
    required this.failedRefunds,
    required this.totalAmount,
    required this.averageAmount,
  });
  final int totalRefunds;
  final int successfulRefunds;
  final int failedRefunds;
  final double totalAmount;
  final double averageAmount;

  double get successRate =>
      totalRefunds == 0 ? 0.0 : (successfulRefunds / totalRefunds) * 100;
}

/// Overall analytics model
class OverallAnalytics {

  const OverallAnalytics({
    required this.totalTransactions,
    required this.netAmount,
    required this.paymentAnalytics,
    required this.refundAnalytics,
  });
  final int totalTransactions;
  final double netAmount;
  final PaymentAnalytics paymentAnalytics;
  final RefundAnalytics refundAnalytics;
}
