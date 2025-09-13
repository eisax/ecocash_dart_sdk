/// Data models for Ecocash API requests and responses
library;

/// Payment request model
class PaymentRequest {

  const PaymentRequest({
    required this.customerMsisdn,
    required this.amount,
    required this.reason,
    required this.currency,
    required this.sourceReference,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) => PaymentRequest(
        customerMsisdn: json['customerMsisdn'] as String,
        amount: (json['amount'] as num).toDouble(),
        reason: json['reason'] as String,
        currency: json['currency'] as String,
        sourceReference: json['sourceReference'] as String,
      );
  final String customerMsisdn;
  final double amount;
  final String reason;
  final String currency;
  final String sourceReference;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'customerMsisdn': customerMsisdn,
        'amount': amount,
        'reason': reason,
        'currency': currency,
        'sourceReference': sourceReference,
      };
}

/// Payment response model
class PaymentResponse {

  const PaymentResponse({
    required this.status,
    required this.message,
    this.ecocashTransactionReference,
    this.amount,
    this.currency,
    this.transactionDateTime,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) =>
      PaymentResponse(
        status: json['status'] as String,
        message: json['message'] as String,
        ecocashTransactionReference:
            json['ecocashTransactionReference'] as String?,
        amount:
            json['amount'] != null ? (json['amount'] as num).toDouble() : null,
        currency: json['currency'] as String?,
        transactionDateTime: json['transactionDateTime'] != null
            ? DateTime.parse(json['transactionDateTime'] as String)
            : null,
      );
  final String status;
  final String message;
  final String? ecocashTransactionReference;
  final double? amount;
  final String? currency;
  final DateTime? transactionDateTime;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status,
        'message': message,
        'ecocashTransactionReference': ecocashTransactionReference,
        'amount': amount,
        'currency': currency,
        'transactionDateTime': transactionDateTime?.toIso8601String(),
      };
}

/// Refund request model
class RefundRequest {

  const RefundRequest({
    required this.originalEcocashTransactionReference,
    required this.refundCorrelator,
    required this.sourceMobileNumber,
    required this.amount,
    required this.reasonForRefund,
    required this.currency,
    this.clientName,
  });

  factory RefundRequest.fromJson(Map<String, dynamic> json) => RefundRequest(
        originalEcocashTransactionReference:
            json['originalEcocashTransactionReference'] as String,
        refundCorrelator: json['refundCorrelator'] as String,
        sourceMobileNumber: json['sourceMobileNumber'] as String,
        amount: (json['amount'] as num).toDouble(),
        reasonForRefund: json['reasonForRefund'] as String,
        currency: json['currency'] as String,
        clientName: json['clientName'] as String?,
      );
  final String originalEcocashTransactionReference;
  final String refundCorrelator;
  final String sourceMobileNumber;
  final double amount;
  final String reasonForRefund;
  final String currency;
  final String? clientName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'originalEcocashTransactionReference':
            originalEcocashTransactionReference,
        'refundCorrelator': refundCorrelator,
        'sourceMobileNumber': sourceMobileNumber,
        'amount': amount,
        'reasonForRefund': reasonForRefund,
        'currency': currency,
        if (clientName != null) 'clientName': clientName,
      };
}

/// Refund response model
class RefundResponse {

  const RefundResponse({
    required this.transactionStatus,
    required this.refundCorrelator,
    this.amount,
    this.currency,
    this.transactionDateTime,
  });

  factory RefundResponse.fromJson(Map<String, dynamic> json) => RefundResponse(
        transactionStatus: json['transactionStatus'] as String,
        refundCorrelator: json['refundCorrelator'] as String,
        amount:
            json['amount'] != null ? (json['amount'] as num).toDouble() : null,
        currency: json['currency'] as String?,
        transactionDateTime: json['transactionDateTime'] != null
            ? DateTime.parse(json['transactionDateTime'] as String)
            : null,
      );
  final String transactionStatus;
  final String refundCorrelator;
  final double? amount;
  final String? currency;
  final DateTime? transactionDateTime;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'transactionStatus': transactionStatus,
        'refundCorrelator': refundCorrelator,
        'amount': amount,
        'currency': currency,
        'transactionDateTime': transactionDateTime?.toIso8601String(),
      };
}

/// Transaction status model
class TransactionStatus {

  const TransactionStatus({
    required this.status,
    this.ecocashReference,
    this.amount,
    this.currency,
    this.customerMsisdn,
    this.transactionDateTime,
  });

  factory TransactionStatus.fromJson(Map<String, dynamic> json) =>
      TransactionStatus(
        status: json['status'] as String,
        ecocashReference: json['ecocashReference'] as String?,
        amount:
            json['amount'] != null ? (json['amount'] as num).toDouble() : null,
        currency: json['currency'] as String?,
        customerMsisdn: json['customerMsisdn'] as String?,
        transactionDateTime: json['transactionDateTime'] != null
            ? DateTime.parse(json['transactionDateTime'] as String)
            : null,
      );
  final String status;
  final String? ecocashReference;
  final double? amount;
  final String? currency;
  final String? customerMsisdn;
  final DateTime? transactionDateTime;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status,
        'ecocashReference': ecocashReference,
        'amount': amount,
        'currency': currency,
        'customerMsisdn': customerMsisdn,
        'transactionDateTime': transactionDateTime?.toIso8601String(),
      };
}

/// Batch operation result model
class BatchOperationResult<T> {
  final Map<int, T> successful = <int, T>{};
  final Map<int, dynamic> failed = <int, dynamic>{};

  void addSuccess(int index, T result) {
    successful[index] = result;
  }

  void addFailure(int index, error) {
    failed[index] = error;
  }

  int get totalProcessed => successful.length + failed.length;
  double get successRate =>
      totalProcessed == 0 ? 0.0 : (successful.length / totalProcessed) * 100;
}
