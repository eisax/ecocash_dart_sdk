# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-09-13

### Added
- Comprehensive input validation system with phone number normalization
- Retry mechanism with exponential backoff and configurable strategies
- Batch operations for processing multiple transactions concurrently
- Built-in analytics and reporting engine with transaction tracking
- Advanced logging system with data masking and multiple destinations
- Circuit breaker pattern for resilience and failure protection
- Offline queue management for network interruption handling
- Sandbox utilities and testing tools with mock responses
- Type-safe data models for all API requests and responses
- Environment configuration (sandbox/live) with proper endpoint handling
- Comprehensive error handling with custom exception hierarchy
- Security features including automatic PII masking
- Performance optimizations with connection pooling and concurrent processing

### Changed
- Unified API structure by merging basic and enhanced features into single EcocashApi class
- Updated all API requests to use POST with JSON payloads
- Fixed authentication to use only X-API-KEY and Content-Type headers
- Corrected API endpoint URLs and base URL configuration
- Updated field names to match exact API specification (including typos)
- Improved error messages and validation feedback
- Enhanced documentation with comprehensive examples and API reference

### Fixed
- Fixed duplicate /api segment in endpoint URLs
- Corrected refund request field names and added missing clientName field
- Fixed transaction lookup to use POST instead of GET
- Resolved all linting errors and warnings
- Fixed validation logic for phone numbers and amounts
- Corrected JSON payload formats to match API specification exactly

### Security
- Added automatic masking of sensitive data in logs
- Implemented secure credential handling
- Added input sanitization to prevent injection attacks
- Enhanced error messages to avoid exposing sensitive information

### Performance
- Implemented connection pooling for HTTP client reuse
- Added concurrent batch processing with configurable limits
- Optimized memory usage and resource cleanup
- Enhanced retry mechanism with intelligent backoff strategies

## [1.0.0] - 2024-09-13

### Added
- Initial release of Ecocash Dart SDK
- Basic payment processing (C2B instant payments)
- Refund processing for previous transactions
- Transaction lookup and status checking
- UUID generation for source references
- Basic error handling with custom exceptions
- Simple configuration with API key support
- Basic examples and documentation
- Support for sandbox and live environments
