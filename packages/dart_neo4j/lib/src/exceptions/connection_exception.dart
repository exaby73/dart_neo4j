import 'package:dart_bolt/dart_bolt.dart' as bolt;
import 'package:dart_neo4j/src/exceptions/neo4j_exception.dart';

/// Exception thrown when connection-related errors occur in the Neo4j driver.
///
/// This wraps the low-level Bolt connection exceptions to provide a higher-level
/// driver-specific interface while preserving the underlying cause.
class ConnectionException extends Neo4jException {
  /// Creates a new connection exception.
  const ConnectionException(super.message, [super.cause]);

  /// Creates a connection exception from a Bolt connection exception.
  factory ConnectionException.fromBolt(
    bolt.BoltConnectionException boltException,
  ) {
    return ConnectionException(boltException.message, boltException);
  }

  @override
  String toString() {
    if (cause != null) {
      return 'ConnectionException: $message\nCaused by: $cause';
    }
    return 'ConnectionException: $message';
  }
}

/// Exception thrown when unable to connect to the database server.
class ServiceUnavailableException extends ConnectionException {
  /// Creates a new service unavailable exception.
  const ServiceUnavailableException(super.message, [super.cause]);

  /// Creates a service unavailable exception from a Bolt exception.
  factory ServiceUnavailableException.fromBolt(
    bolt.ServiceUnavailableException boltException,
  ) {
    return ServiceUnavailableException(boltException.message, boltException);
  }

  @override
  String toString() {
    if (cause != null) {
      return 'ServiceUnavailableException: $message\nCaused by: $cause';
    }
    return 'ServiceUnavailableException: $message';
  }
}

/// Exception thrown when the connection times out.
class ConnectionTimeoutException extends ConnectionException {
  /// The timeout duration that was exceeded.
  final Duration? timeout;

  /// Creates a new connection timeout exception.
  const ConnectionTimeoutException(super.message, [this.timeout, super.cause]);

  /// Creates a timeout exception from a Bolt exception.
  factory ConnectionTimeoutException.fromBolt(
    bolt.ConnectionTimeoutException boltException,
  ) {
    return ConnectionTimeoutException(
      boltException.message,
      boltException.timeout,
      boltException,
    );
  }

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

  /// Creates a connection lost exception from a Bolt exception.
  factory ConnectionLostException.fromBolt(
    bolt.ConnectionLostException boltException,
  ) {
    return ConnectionLostException(boltException.message, boltException);
  }

  @override
  String toString() {
    if (cause != null) {
      return 'ConnectionLostException: $message\nCaused by: $cause';
    }
    return 'ConnectionLostException: $message';
  }
}

/// Exception thrown when SSL/TLS handshake fails.
class SecurityException extends ConnectionException {
  /// Creates a new security exception.
  const SecurityException(super.message, [super.cause]);

  /// Creates a security exception from a Bolt exception.
  factory SecurityException.fromBolt(bolt.SecurityException boltException) {
    return SecurityException(boltException.message, boltException);
  }

  @override
  String toString() {
    if (cause != null) {
      return 'SecurityException: $message\nCaused by: $cause';
    }
    return 'SecurityException: $message';
  }
}

/// Exception thrown when the Bolt protocol version is not supported.
class ProtocolException extends ConnectionException {
  /// The protocol version that was requested or received.
  final int? version;

  /// Creates a new protocol exception.
  const ProtocolException(super.message, [this.version, super.cause]);

  /// Creates a protocol exception from a Bolt exception.
  factory ProtocolException.fromBolt(bolt.ProtocolException boltException) {
    return ProtocolException(
      boltException.message,
      boltException.version,
      boltException,
    );
  }

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

/// Exception thrown when an invalid URI is provided.
class InvalidUriException extends ConnectionException {
  /// The invalid URI that caused the exception.
  final String uri;

  /// Creates a new invalid URI exception.
  const InvalidUriException(super.message, this.uri, [super.cause]);

  @override
  String toString() {
    final buffer = StringBuffer('InvalidUriException: $message');
    buffer.write(' (URI: $uri)');
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}
