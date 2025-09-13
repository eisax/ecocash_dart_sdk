/// Exception classes for Ecocash API
library;

/// Exception thrown by Ecocash API operations
class EcocashApiException implements Exception {

  /// Creates a new Ecocash API exception
  const EcocashApiException(
    this.message, {
    this.statusCode,
    this.response,
  });
  /// The error message
  final String message;

  /// HTTP status code if available
  final int? statusCode;

  /// Full response data if available
  final Map<String, dynamic>? response;

  @override
  String toString() {
    return 'EcocashApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }
}
