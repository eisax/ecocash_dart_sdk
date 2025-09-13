/// Logging and auditing system for Ecocash API
library;

import 'dart:convert';
import 'dart:io';

/// Log levels
enum LogLevel { debug, info, warning, error, critical }

/// Log entry model
class LogEntry {

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.operation,
    this.metadata,
    this.requestId,
    this.duration,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        timestamp: DateTime.parse(json['timestamp'] as String),
        level: LogLevel.values.byName(json['level'] as String),
        message: json['message'] as String,
        operation: json['operation'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
        requestId: json['requestId'] as String?,
        duration: json['duration'] != null
            ? Duration(milliseconds: json['duration'] as int)
            : null,
      );
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? operation;
  final Map<String, dynamic>? metadata;
  final String? requestId;
  final Duration? duration;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'message': message,
        if (operation != null) 'operation': operation,
        if (metadata != null) 'metadata': metadata,
        if (requestId != null) 'requestId': requestId,
        if (duration != null) 'duration': duration!.inMilliseconds,
      };

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('[${level.name.toUpperCase()}] ');
    if (requestId != null) buffer.write('[$requestId] ');
    if (operation != null) buffer.write('[$operation] ');
    buffer.write(message);
    if (duration != null) buffer.write(' (${duration!.inMilliseconds}ms)');
    return buffer.toString();
  }
}

/// Logger interface
abstract class Logger {
  void log(
    LogLevel level,
    String message, {
    String? operation,
    Map<String, dynamic>? metadata,
    String? requestId,
    Duration? duration,
  });

  void debug(String message,
      {String? operation,
      Map<String, dynamic>? metadata,
      String? requestId,
      Duration? duration});
  void info(String message,
      {String? operation,
      Map<String, dynamic>? metadata,
      String? requestId,
      Duration? duration});
  void warning(String message,
      {String? operation,
      Map<String, dynamic>? metadata,
      String? requestId,
      Duration? duration});
  void error(String message,
      {String? operation,
      Map<String, dynamic>? metadata,
      String? requestId,
      Duration? duration});
  void critical(String message,
      {String? operation,
      Map<String, dynamic>? metadata,
      String? requestId,
      Duration? duration});
}

/// Console logger implementation
class ConsoleLogger implements Logger {

  const ConsoleLogger({
    this.minLevel = LogLevel.info,
    this.colorOutput = true,
  });
  final LogLevel minLevel;
  final bool colorOutput;

  @override
  void log(
    LogLevel level,
    String message, {
    String? operation,
    Map<String, dynamic>? metadata,
    String? requestId,
    Duration? duration,
  }) {
    if (level.index < minLevel.index) return;

    final LogEntry entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      operation: operation,
      metadata: metadata,
      requestId: requestId,
      duration: duration,
    );

    final String output = colorOutput ? _colorize(entry) : entry.toString();
    print(output);
  }

  String _colorize(LogEntry entry) {
    const String reset = '\x1B[0m';
    String color;

    switch (entry.level) {
      case LogLevel.debug:
        color = '\x1B[37m'; // White
        break;
      case LogLevel.info:
        color = '\x1B[36m'; // Cyan
        break;
      case LogLevel.warning:
        color = '\x1B[33m'; // Yellow
        break;
      case LogLevel.error:
        color = '\x1B[31m'; // Red
        break;
      case LogLevel.critical:
        color = '\x1B[35m'; // Magenta
        break;
    }

    return '$color${entry.toString()}$reset';
  }

  @override
  void debug(String message,
          {String? operation,
          Map<String, dynamic>? metadata,
          String? requestId,
          Duration? duration}) =>
      log(LogLevel.debug, message,
          operation: operation,
          metadata: metadata,
          requestId: requestId,
          duration: duration);

  @override
  void info(String message,
          {String? operation,
          Map<String, dynamic>? metadata,
          String? requestId,
          Duration? duration}) =>
      log(LogLevel.info, message,
          operation: operation,
          metadata: metadata,
          requestId: requestId,
          duration: duration);

  @override
  void warning(String message,
          {String? operation,
          Map<String, dynamic>? metadata,
          String? requestId,
          Duration? duration}) =>
      log(LogLevel.warning, message,
          operation: operation,
          metadata: metadata,
          requestId: requestId,
          duration: duration);

  @override
  void error(String message,
          {String? operation,
          Map<String, dynamic>? metadata,
          String? requestId,
          Duration? duration}) =>
      log(LogLevel.error, message,
          operation: operation,
          metadata: metadata,
          requestId: requestId,
          duration: duration);

  @override
  void critical(String message,
          {String? operation,
          Map<String, dynamic>? metadata,
          String? requestId,
          Duration? duration}) =>
      log(LogLevel.critical, message,
          operation: operation,
          metadata: metadata,
          requestId: requestId,
          duration: duration);
}

/// File logger implementation
class FileLogger implements Logger {

  FileLogger({
    required this.filePath,
    this.minLevel = LogLevel.info,
    this.rotateDaily = true,
  });
  final String filePath;
  final LogLevel minLevel;
  final bool rotateDaily;

  IOSink? _sink;
  DateTime? _lastRotation;

  @override
  void log(
    LogLevel level,
    String message, {
    String? operation,
    Map<String, dynamic>? metadata,
    String? requestId,
    Duration? duration,
  }) {
    if (level.index < minLevel.index) return;

    _ensureSinkOpen();

    final LogEntry entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      operation: operation,
      metadata: metadata,
      requestId: requestId,
      duration: duration,
    );

    _sink?.writeln(jsonEncode(entry.toJson()));
  }

  void _ensureSinkOpen() {
    final DateTime now = DateTime.now();

    if (rotateDaily && _shouldRotate(now)) {
      _sink?.close();
      _sink = null;
    }

    if (_sink == null) {
      final String actualPath = rotateDaily ? _getDailyFilePath(now) : filePath;
      _sink = File(actualPath).openWrite(mode: FileMode.append);
      _lastRotation = now;
    }
  }

  bool _shouldRotate(DateTime now) {
    if (_lastRotation == null) return false;
    return now.day != _lastRotation!.day ||
        now.month != _lastRotation!.month ||
        now.year != _lastRotation!.year;
  }

  String _getDailyFilePath(DateTime date) {
    final String dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final String directory = filePath.substring(0, filePath.lastIndexOf('/'));
    final String filename = filePath.substring(filePath.lastIndexOf('/') + 1);
    final String nameWithoutExt = filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    final String ext = filename.contains('.')
        ? filename.substring(filename.lastIndexOf('.'))
        : '.log';

    return '$directory/${nameWithoutExt}_$dateStr$ext';
  }

  void close() {
    _sink?.close();
    _sink = null;
  }

  @override
  void debug(String message,
          {String? operation,
          Map<String, dynamic>? metadata,
          String? requestId,
          Duration? duration}) =>
      log(LogLevel.debug, message,
          operation: operation,
          metadata: metadata,
          requestId: requestId,
          duration: duration);

  @override
  void info(String message,
          {String? operation,
          Map<String, dynamic>? metadata,
          String? requestId,
          Duration? duration}) =>
      log(LogLevel.info, message,
          operation: operation,
          metadata: metadata,
          requestId: requestId,
          duration: duration);

  @override
  void warning(String message,
          {String? operation,
          Map<String, dynamic>? metadata,
          String? requestId,
          Duration? duration}) =>
      log(LogLevel.warning, message,
          operation: operation,
          metadata: metadata,
          requestId: requestId,
          duration: duration);

  @override
  void error(String message,
          {String? operation,
          Map<String, dynamic>? metadata,
          String? requestId,
          Duration? duration}) =>
      log(LogLevel.error, message,
          operation: operation,
          metadata: metadata,
          requestId: requestId,
          duration: duration);

  @override
  void critical(String message,
          {String? operation,
          Map<String, dynamic>? metadata,
          String? requestId,
          Duration? duration}) =>
      log(LogLevel.critical, message,
          operation: operation,
          metadata: metadata,
          requestId: requestId,
          duration: duration);
}

/// Composite logger that logs to multiple destinations
class CompositeLogger implements Logger {

  const CompositeLogger(this.loggers);
  final List<Logger> loggers;

  @override
  void log(
    LogLevel level,
    String message, {
    String? operation,
    Map<String, dynamic>? metadata,
    String? requestId,
    Duration? duration,
  }) {
    for (final Logger logger in loggers) {
      logger.log(level, message,
          operation: operation,
          metadata: metadata,
          requestId: requestId,
          duration: duration);
    }
  }

  @override
  void debug(String message,
          {String? operation,
          Map<String, dynamic>? metadata,
          String? requestId,
          Duration? duration}) =>
      log(LogLevel.debug, message,
          operation: operation,
          metadata: metadata,
          requestId: requestId,
          duration: duration);

  @override
  void info(String message,
          {String? operation,
          Map<String, dynamic>? metadata,
          String? requestId,
          Duration? duration}) =>
      log(LogLevel.info, message,
          operation: operation,
          metadata: metadata,
          requestId: requestId,
          duration: duration);

  @override
  void warning(String message,
          {String? operation,
          Map<String, dynamic>? metadata,
          String? requestId,
          Duration? duration}) =>
      log(LogLevel.warning, message,
          operation: operation,
          metadata: metadata,
          requestId: requestId,
          duration: duration);

  @override
  void error(String message,
          {String? operation,
          Map<String, dynamic>? metadata,
          String? requestId,
          Duration? duration}) =>
      log(LogLevel.error, message,
          operation: operation,
          metadata: metadata,
          requestId: requestId,
          duration: duration);

  @override
  void critical(String message,
          {String? operation,
          Map<String, dynamic>? metadata,
          String? requestId,
          Duration? duration}) =>
      log(LogLevel.critical, message,
          operation: operation,
          metadata: metadata,
          requestId: requestId,
          duration: duration);
}

/// Data masking utilities for sensitive information
class DataMasker {
  static const List<String> sensitiveFields = <String>[
    'pin',
    'password',
    'token',
    'apiKey',
    'authorization',
    'secret'
  ];

  /// Masks sensitive data in a map
  static Map<String, dynamic> maskSensitiveData(Map<String, dynamic> data) {
    final Map<String, dynamic> masked = <String, dynamic>{};

    for (final MapEntry<String, dynamic> entry in data.entries) {
      if (_isSensitiveField(entry.key)) {
        masked[entry.key] = _maskValue(entry.value);
      } else if (entry.value is Map<String, dynamic>) {
        masked[entry.key] = maskSensitiveData(entry.value);
      } else if (entry.value is List) {
        masked[entry.key] = _maskList(entry.value);
      } else {
        masked[entry.key] = entry.value;
      }
    }

    return masked;
  }

  static bool _isSensitiveField(String fieldName) {
    final String lowerField = fieldName.toLowerCase();
    return sensitiveFields.any(lowerField.contains);
  }

  static dynamic _maskValue(value) {
    if (value == null) return null;
    if (value is String) {
      return value.length <= 4
          ? '***'
          : '${value.substring(0, 2)}***${value.substring(value.length - 2)}';
    }
    return '***';
  }

  static List<dynamic> _maskList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return maskSensitiveData(item);
      }
      return item;
    }).toList();
  }

  /// Masks phone numbers (shows only first 3 and last 2 digits)
  static String maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length <= 5) return '***';
    return '${phoneNumber.substring(0, 3)}***${phoneNumber.substring(phoneNumber.length - 2)}';
  }

  /// Masks transaction references (shows only first and last 4 characters)
  static String maskTransactionReference(String reference) {
    if (reference.length <= 8) return '***';
    return '${reference.substring(0, 4)}***${reference.substring(reference.length - 4)}';
  }

  /// Masks API key
  static String maskApiKey(String apiKey) {
    if (apiKey.length <= 8) return '***';
    return '${apiKey.substring(0, 4)}${'*' * (apiKey.length - 8)}${apiKey.substring(apiKey.length - 4)}';
  }

  /// Masks PIN
  static String maskPin(String pin) {
    return '***';
  }
}
