import 'package:dart_neo4j/src/connection/connection_pool.dart';
import 'package:dart_neo4j/src/exceptions/neo4j_exception.dart';
import 'package:dart_neo4j/src/result/result.dart';
import 'package:dart_neo4j/src/session/session.dart';
import 'package:dart_neo4j/src/session/transaction.dart';

/// Base implementation for transactions.
abstract class TransactionImpl implements Transaction {
  final PooledConnection _pooledConnection;
  final ConnectionPool _connectionPool;
  final TransactionConfig? config;
  
  TransactionState _state = TransactionState.active;

  /// Creates a new transaction implementation.
  TransactionImpl(this._pooledConnection, this._connectionPool, this.config);

  @override
  TransactionState get state => _state;

  @override
  bool get isActive => _state == TransactionState.active;

  @override
  bool get isClosed => _state == TransactionState.committed || _state == TransactionState.rolledBack;

  @override
  bool get isMarkedForRollback => _state == TransactionState.markedForRollback;

  @override
  Future<Result> run(String cypher, [Map<String, dynamic> parameters = const {}]) async {
    if (isClosed) {
      throw const TransactionClosedException('Transaction is closed');
    }
    if (isMarkedForRollback) {
      throw const TransactionClosedException('Transaction is marked for rollback');
    }

    try {
      return await _pooledConnection.connection.run(cypher, parameters);
    } catch (e) {
      _state = TransactionState.markedForRollback;
      rethrow;
    }
  }

  @override
  Future<void> commit() async {
    if (isClosed) {
      throw const TransactionClosedException('Transaction is already closed');
    }
    if (isMarkedForRollback) {
      throw const TransactionClosedException('Cannot commit transaction marked for rollback');
    }

    try {
      // Send actual COMMIT message to the database
      await _pooledConnection.connection.commitTransaction();
      _state = TransactionState.committed;
    } catch (e) {
      _state = TransactionState.markedForRollback;
      throw DatabaseException('Failed to commit transaction: $e', null, e);
    } finally {
      await _cleanup();
    }
  }

  @override
  Future<void> rollback() async {
    if (_state == TransactionState.committed) {
      throw const TransactionClosedException('Cannot rollback committed transaction');
    }
    if (_state == TransactionState.rolledBack) {
      return; // Already rolled back
    }

    try {
      // Send actual ROLLBACK message to the database
      await _pooledConnection.connection.rollbackTransaction();
      _state = TransactionState.rolledBack;
    } catch (e) {
      _state = TransactionState.rolledBack; // Still mark as rolled back even if message fails
      throw DatabaseException('Failed to rollback transaction: $e', null, e);
    } finally {
      await _cleanup();
    }
  }

  @override
  Future<void> close() async {
    if (isClosed) return;

    if (isActive) {
      await rollback();
    } else {
      await _cleanup();
    }
  }

  /// Begins the transaction (internal method).
  Future<void> begin() async {
    try {
      // Send actual BEGIN message to the database
      await _pooledConnection.connection.beginTransaction(
        txTimeout: config?.timeout?.inMilliseconds,
        txMetadata: config?.metadata,
      );
      _state = TransactionState.active;
    } catch (e) {
      _state = TransactionState.markedForRollback;
      await _cleanup();
      throw DatabaseException('Failed to begin transaction: $e', null, e);
    }
  }

  /// Cleans up transaction resources.
  Future<void> _cleanup() async {
    // Return connection to pool
    _connectionPool.release(_pooledConnection);
  }

  @override
  String toString() {
    return '$runtimeType{state: $_state}';
  }
}

/// Concrete implementation of a general transaction.
class GeneralTransactionImpl extends TransactionImpl {
  /// Creates a new general transaction.
  GeneralTransactionImpl(super.pooledConnection, super.connectionPool, super.config);
}

/// Concrete implementation of a read-only transaction.
class ReadTransactionImpl extends TransactionImpl implements ReadTransaction {
  /// Creates a new read transaction.
  ReadTransactionImpl(super.pooledConnection, super.connectionPool, super.config);

  @override
  Future<Result> run(String cypher, [Map<String, dynamic> parameters = const {}]) async {
    // Could add read-only query validation here
    return super.run(cypher, parameters);
  }
}

/// Concrete implementation of a read-write transaction.
class WriteTransactionImpl extends TransactionImpl implements WriteTransaction {
  /// Creates a new write transaction.
  WriteTransactionImpl(super.pooledConnection, super.connectionPool, super.config);

  @override
  Future<Result> run(String cypher, [Map<String, dynamic> parameters = const {}]) async {
    // Could add write permission validation here
    return super.run(cypher, parameters);
  }
}