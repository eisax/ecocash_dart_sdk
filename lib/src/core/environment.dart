/// Environment configuration for Ecocash API
library;

/// Environment types for Ecocash API
enum EcocashEnvironment {
  /// Sandbox environment for testing
  sandbox,

  /// Live production environment
  live,
}

/// Environment configuration
class EnvironmentConfig {
  /// Base URL for Ecocash API
  static const String baseUrl =
      'https://developers.ecocash.co.zw/api/ecocash_pay';

  /// Get the payment endpoint for the specified environment
  static String getPaymentEndpoint(EcocashEnvironment environment) {
    final String envSuffix =
        environment == EcocashEnvironment.sandbox ? 'sandbox' : 'live';
    return '$baseUrl/v2/payment/instant/c2b/$envSuffix';
  }

  /// Get the refund endpoint for the specified environment
  static String getRefundEndpoint(EcocashEnvironment environment) {
    final String envSuffix =
        environment == EcocashEnvironment.sandbox ? 'sandbox' : 'live';
    return '$baseUrl/v2/refund/instant/c2b/$envSuffix';
  }

  /// Get the transaction lookup endpoint for the specified environment
  static String getTransactionLookupEndpoint(EcocashEnvironment environment) {
    final String envSuffix =
        environment == EcocashEnvironment.sandbox ? 'sandbox' : 'live';
    return '$baseUrl/v1/transaction/c2b/status/$envSuffix';
  }
}
