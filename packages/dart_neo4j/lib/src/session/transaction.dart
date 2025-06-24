import 'package:dart_neo4j/src/exceptions/neo4j_exception.dart';
import 'package:dart_neo4j/src/result/result.dart';

/// Represents a transaction state.
enum TransactionState {
  /// The transaction is active and can execute queries.
  active,

  /// The transaction has been committed.
  committed,

  /// The transaction has been rolled back.
  rolledBack,

  /// The transaction has been marked for rollback due to an error.
  markedForRollback,
}

/// A Neo4j transaction that can execute multiple queries atomically.
abstract class Transaction {
  /// The current state of this transaction.
  TransactionState get state;

  /// Whether this transaction is active (can execute queries).
  bool get isActive => state == TransactionState.active;

  /// Whether this transaction is closed (committed or rolled back).
  bool get isClosed =>
      state == TransactionState.committed ||
      state == TransactionState.rolledBack;

  /// Whether this transaction is marked for rollback.
  bool get isMarkedForRollback => state == TransactionState.markedForRollback;

  /// Executes a Cypher query within this transaction.
  ///
  /// [cypher] - the Cypher query to execute
  /// [parameters] - parameters for the query (default: empty)
  ///
  /// Throws [TransactionClosedException] if the transaction is closed.
  /// Throws [DatabaseException] if the query fails.
  Future<Result> run(
    String cypher, [
    Map<String, dynamic> parameters = const {},
  ]);

  /// Commits this transaction.
  ///
  /// After calling this method, the transaction cannot be used for further queries.
  ///
  /// Throws [TransactionClosedException] if the transaction is already closed.
  /// Throws [DatabaseException] if the commit fails.
  Future<void> commit();

  /// Rolls back this transaction.
  ///
  /// After calling this method, the transaction cannot be used for further queries.
  ///
  /// Throws [TransactionClosedException] if the transaction is already closed.
  Future<void> rollback();

  /// Closes this transaction.
  ///
  /// If the transaction is still active, it will be rolled back.
  Future<void> close();
}

/// A read-only transaction that can only execute read queries.
abstract class ReadTransaction extends Transaction {
  @override
  Future<Result> run(
    String cypher, [
    Map<String, dynamic> parameters = const {},
  ]) {
    if (isClosed) {
      throw const TransactionClosedException('Transaction is closed');
    }
    // Implementation will be in the concrete class
    throw UnimplementedError();
  }
}

/// A read-write transaction that can execute both read and write queries.
abstract class WriteTransaction extends Transaction {
  @override
  Future<Result> run(
    String cypher, [
    Map<String, dynamic> parameters = const {},
  ]) {
    if (isClosed) {
      throw const TransactionClosedException('Transaction is closed');
    }
    // Implementation will be in the concrete class
    throw UnimplementedError();
  }
}

/// Function type for transaction work that returns a result.
typedef TransactionWork<T> = Future<T> Function(Transaction transaction);

/// Function type for read transaction work.
typedef ReadTransactionWork<T> =
    Future<T> Function(ReadTransaction transaction);

/// Function type for write transaction work.
typedef WriteTransactionWork<T> =
    Future<T> Function(WriteTransaction transaction);
