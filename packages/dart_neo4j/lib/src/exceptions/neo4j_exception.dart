/// Base exception class for all Neo4j driver exceptions.
abstract class Neo4jException implements Exception {
  /// The error message.
  final String message;

  /// The underlying cause of this exception, if any.
  final Object? cause;

  /// Creates a new Neo4j exception.
  const Neo4jException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'Neo4jException: $message\nCaused by: $cause';
    }
    return 'Neo4jException: $message';
  }
}

/// Exception thrown when a database operation fails.
class DatabaseException extends Neo4jException {
  /// The Neo4j error code, if available.
  final String? code;

  /// Creates a new database exception.
  const DatabaseException(super.message, [this.code, super.cause]);

  @override
  String toString() {
    final buffer = StringBuffer('DatabaseException: $message');
    if (code != null) {
      buffer.write(' (Code: $code)');
    }
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a client-side error occurs.
class ClientException extends Neo4jException {
  /// Creates a new client exception.
  const ClientException(super.message, [super.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'ClientException: $message\nCaused by: $cause';
    }
    return 'ClientException: $message';
  }
}

/// Exception thrown when a transient error occurs that may be retried.
class TransientException extends Neo4jException {
  /// The Neo4j error code, if available.
  final String? code;

  /// Creates a new transient exception.
  const TransientException(super.message, [this.code, super.cause]);

  @override
  String toString() {
    final buffer = StringBuffer('TransientException: $message');
    if (code != null) {
      buffer.write(' (Code: $code)');
    }
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}

/// Exception thrown when authentication fails.
class AuthenticationException extends Neo4jException {
  /// Creates a new authentication exception.
  const AuthenticationException(super.message, [super.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'AuthenticationException: $message\nCaused by: $cause';
    }
    return 'AuthenticationException: $message';
  }
}

/// Exception thrown when authorization fails.
class AuthorizationException extends Neo4jException {
  /// Creates a new authorization exception.
  const AuthorizationException(super.message, [super.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'AuthorizationException: $message\nCaused by: $cause';
    }
    return 'AuthorizationException: $message';
  }
}

/// Exception thrown when a session is used after being closed.
class SessionExpiredException extends Neo4jException {
  /// Creates a new session expired exception.
  const SessionExpiredException(super.message, [super.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'SessionExpiredException: $message\nCaused by: $cause';
    }
    return 'SessionExpiredException: $message';
  }
}

/// Exception thrown when a transaction is used after being closed.
class TransactionClosedException extends Neo4jException {
  /// Creates a new transaction closed exception.
  const TransactionClosedException(super.message, [super.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'TransactionClosedException: $message\nCaused by: $cause';
    }
    return 'TransactionClosedException: $message';
  }
}