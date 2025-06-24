/// Base exception class for all Bolt connection exceptions.
abstract class BoltConnectionException implements Exception {
  /// The error message.
  final String message;

  /// The underlying cause of this exception, if any.
  final Object? cause;

  /// Creates a new Bolt connection exception.
  const BoltConnectionException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return '$runtimeType: $message\nCaused by: $cause';
    }
    return '$runtimeType: $message';
  }
}

/// Exception thrown when connection-related errors occur.
class ConnectionException extends BoltConnectionException {
  /// Creates a new connection exception.
  const ConnectionException(super.message, [super.cause]);
}

/// Exception thrown when unable to connect to the server.
class ServiceUnavailableException extends ConnectionException {
  /// Creates a new service unavailable exception.
  const ServiceUnavailableException(super.message, [super.cause]);
}

/// Exception thrown when the connection times out.
class ConnectionTimeoutException extends ConnectionException {
  /// The timeout duration that was exceeded.
  final Duration? timeout;

  /// Creates a new connection timeout exception.
  const ConnectionTimeoutException(super.message, [this.timeout, super.cause]);

  @override
  String toString() {
    final buffer = StringBuffer('ConnectionTimeoutException: $message');
    if (timeout != null) {
      buffer.write(' (Timeout: ${timeout!.inMilliseconds}ms)');
    }
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}

/// Exception thrown when the connection is lost unexpectedly.
class ConnectionLostException extends ConnectionException {
  /// Creates a new connection lost exception.
  const ConnectionLostException(super.message, [super.cause]);
}

/// Exception thrown when SSL/TLS handshake fails.
class SecurityException extends ConnectionException {
  /// Creates a new security exception.
  const SecurityException(super.message, [super.cause]);
}

/// Exception thrown when the Bolt protocol version is not supported.
class ProtocolException extends ConnectionException {
  /// The protocol version that was requested or received.
  final int? version;

  /// Creates a new protocol exception.
  const ProtocolException(super.message, [this.version, super.cause]);

  @override
  String toString() {
    final buffer = StringBuffer('ProtocolException: $message');
    if (version != null) {
      buffer.write(' (Version: $version)');
    }
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}