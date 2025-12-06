import 'package:dart_neo4j/src/exceptions/neo4j_exception.dart';
import 'package:dart_neo4j/src/result/result.dart';
import 'package:dart_neo4j/src/session/transaction.dart';

/// Access mode for sessions and transactions.
enum AccessMode {
  /// Read-only access mode.
  read,

  /// Read-write access mode.
  write,
}

/// Configuration for a Neo4j session.
class SessionConfig {
  /// The default database to use for queries.
  final String? database;

  /// The access mode for this session.
  final AccessMode accessMode;

  /// Bookmarks for causal consistency.
  final List<String> bookmarks;

  /// Default query timeout.
  final Duration timeout;

  /// Creates a new session configuration.
  const SessionConfig({
    this.database,
    this.accessMode = AccessMode.write,
    this.bookmarks = const [],
    Duration? timeout,
  }) : timeout = timeout ?? const Duration(seconds: 30);

  /// Creates a read-only session configuration.
  const SessionConfig.read({
    this.database,
    this.bookmarks = const [],
    Duration? timeout,
  }) : accessMode = AccessMode.read,
       timeout = timeout ?? const Duration(seconds: 30);

  /// Creates a read-write session configuration.
  const SessionConfig.write({
    this.database,
    this.bookmarks = const [],
    Duration? timeout,
  }) : accessMode = AccessMode.write,
       timeout = timeout ?? const Duration(seconds: 30);

  @override
  String toString() {
    return 'SessionConfig{database: $database, accessMode: $accessMode, bookmarks: ${bookmarks.length}, timeout: $timeout}';
  }
}

/// A Neo4j session for executing queries and transactions.
abstract class Session {
  /// The configuration for this session.
  SessionConfig get config;

  /// Whether this session is closed.
  bool get isClosed;

  /// The last bookmarks from this session.
  List<String> get lastBookmarks;

  /// Starts executing a Cypher query in an auto-commit transaction and returns
  /// [Result] early so clients can start streaming records immediately.
  /// [Result.done] and [Result.summary()] will complete when the query has
  /// finished executing.
  ///
  /// [cypher] - the Cypher query to execute
  /// [parameters] - parameters for the query (default: empty)
  ///
  /// Throws [SessionExpiredException] if the session is closed.
  /// Throws [DatabaseException] if the query fails.
  Future<Result> startQuery(
    String cypher, [
    Map<String, dynamic> parameters = const {},
  ]);

  /// Executes a Cypher query in an auto-commit transaction and wait for the
  /// query to complete with all results.
  ///
  /// [cypher] - the Cypher query to execute
  /// [parameters] - parameters for the query (default: empty)
  ///
  /// Throws [SessionExpiredException] if the session is closed.
  /// Throws [DatabaseException] if the query fails.
  Future<Result> run(
    String cypher, [
    Map<String, dynamic> parameters = const {},
  ]);

  /// Begins an explicit transaction.
  ///
  /// [config] - optional transaction configuration
  ///
  /// Throws [SessionExpiredException] if the session is closed.
  /// Throws [DatabaseException] if the transaction cannot be started.
  Future<Transaction> beginTransaction([TransactionConfig? config]);

  /// Executes a read transaction.
  ///
  /// The provided function will be called with a read-only transaction.
  /// If the function throws a transient error, it may be retried automatically.
  ///
  /// [work] - the work to execute in the transaction
  /// [config] - optional transaction configuration
  ///
  /// Throws [SessionExpiredException] if the session is closed.
  /// Throws [DatabaseException] if the transaction fails.
  Future<T> executeRead<T>(
    ReadTransactionWork<T> work, [
    TransactionConfig? config,
  ]);

  /// Executes a write transaction.
  ///
  /// The provided function will be called with a read-write transaction.
  /// If the function throws a transient error, it may be retried automatically.
  ///
  /// [work] - the work to execute in the transaction
  /// [config] - optional transaction configuration
  ///
  /// Throws [SessionExpiredException] if the session is closed.
  /// Throws [DatabaseException] if the transaction fails.
  Future<T> executeWrite<T>(
    WriteTransactionWork<T> work, [
    TransactionConfig? config,
  ]);

  /// Closes this session and releases any associated resources.
  ///
  /// After calling this method, the session cannot be used for further operations.
  Future<void> close();
}

/// Configuration for a transaction.
class TransactionConfig {
  /// The timeout for this transaction.
  final Duration? timeout;

  /// Metadata to attach to this transaction.
  final Map<String, dynamic> metadata;

  /// Creates a new transaction configuration.
  const TransactionConfig({this.timeout, this.metadata = const {}});

  @override
  String toString() {
    return 'TransactionConfig{timeout: $timeout, metadata: ${metadata.length} entries}';
  }
}
