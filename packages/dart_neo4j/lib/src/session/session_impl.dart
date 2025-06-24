import 'dart:async';

import 'package:dart_neo4j/src/connection/connection_pool.dart';
import 'package:dart_neo4j/src/exceptions/neo4j_exception.dart';
import 'package:dart_neo4j/src/result/result.dart';
import 'package:dart_neo4j/src/session/session.dart';
import 'package:dart_neo4j/src/session/transaction.dart';
import 'package:dart_neo4j/src/session/transaction_impl.dart';

/// Concrete implementation of a Neo4j session.
class SessionImpl implements Session {
  final ConnectionPool _connectionPool;
  final SessionConfig _config;
  
  bool _closed = false;
  final List<String> _lastBookmarks = [];

  /// Creates a new session implementation.
  SessionImpl(this._connectionPool, this._config);

  @override
  SessionConfig get config => _config;

  @override
  bool get isClosed => _closed;

  @override
  List<String> get lastBookmarks => List.unmodifiable(_lastBookmarks);

  @override
  Future<Result> run(String cypher, [Map<String, dynamic> parameters = const {}]) async {
    if (_closed) {
      throw const SessionExpiredException('Session has been closed');
    }

    PooledConnection? pooledConnection;
    try {
      // Acquire connection from pool
      pooledConnection = await _connectionPool.acquire();
      
      // Execute query
      final result = await pooledConnection.connection.run(cypher, parameters);
      
      // Release connection back to pool immediately for auto-commit transactions
      _connectionPool.release(pooledConnection);
      pooledConnection = null;
      
      return result;
    } catch (e) {
      // Release connection on error
      if (pooledConnection != null) {
        _connectionPool.release(pooledConnection);
      }
      rethrow;
    }
  }

  @override
  Future<Transaction> beginTransaction([TransactionConfig? config]) async {
    if (_closed) {
      throw const SessionExpiredException('Session has been closed');
    }

    try {
      // Acquire connection from pool
      final pooledConnection = await _connectionPool.acquire();
      
      // Create transaction
      final transaction = GeneralTransactionImpl(pooledConnection, _connectionPool, config);
      
      // Begin the transaction
      await transaction.begin();
      
      return transaction;
    } catch (e) {
      throw DatabaseException('Failed to begin transaction: $e', null, e);
    }
  }

  @override
  Future<T> executeRead<T>(ReadTransactionWork<T> work, [TransactionConfig? config]) async {
    if (_closed) {
      throw const SessionExpiredException('Session has been closed');
    }

    int attempts = 0;
    const maxAttempts = 3;
    
    while (attempts < maxAttempts) {
      attempts++;
      
      ReadTransaction? transaction;
      try {
        transaction = await _beginReadTransaction(config);
        final result = await work(transaction);
        await transaction.commit();
        return result;
      } on TransientException {
        if (transaction != null && !transaction.isClosed) {
          await transaction.rollback();
        }
        if (attempts >= maxAttempts) {
          rethrow;
        }
        // Wait before retry with exponential backoff
        await Future.delayed(Duration(milliseconds: 100 * attempts));
      } catch (e) {
        if (transaction != null && !transaction.isClosed) {
          await transaction.rollback();
        }
        rethrow;
      }
    }
    
    throw const DatabaseException('Maximum retry attempts exceeded');
  }

  @override
  Future<T> executeWrite<T>(WriteTransactionWork<T> work, [TransactionConfig? config]) async {
    if (_closed) {
      throw const SessionExpiredException('Session has been closed');
    }

    int attempts = 0;
    const maxAttempts = 3;
    
    while (attempts < maxAttempts) {
      attempts++;
      
      WriteTransaction? transaction;
      try {
        transaction = await _beginWriteTransaction(config);
        final result = await work(transaction);
        await transaction.commit();
        return result;
      } on TransientException {
        if (transaction != null && !transaction.isClosed) {
          await transaction.rollback();
        }
        if (attempts >= maxAttempts) {
          rethrow;
        }
        // Wait before retry with exponential backoff
        await Future.delayed(Duration(milliseconds: 100 * attempts));
      } catch (e) {
        if (transaction != null && !transaction.isClosed) {
          await transaction.rollback();
        }
        rethrow;
      }
    }
    
    throw const DatabaseException('Maximum retry attempts exceeded');
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    
    _closed = true;
    // Note: We don't close the connection pool here since it's shared across sessions
  }

  /// Begins a read transaction.
  Future<ReadTransaction> _beginReadTransaction([TransactionConfig? config]) async {
    try {
      final pooledConnection = await _connectionPool.acquire();
      final transaction = ReadTransactionImpl(pooledConnection, _connectionPool, config);
      await transaction.begin();
      return transaction;
    } catch (e) {
      throw DatabaseException('Failed to begin read transaction: $e', null, e);
    }
  }

  /// Begins a write transaction.
  Future<WriteTransaction> _beginWriteTransaction([TransactionConfig? config]) async {
    try {
      final pooledConnection = await _connectionPool.acquire();
      final transaction = WriteTransactionImpl(pooledConnection, _connectionPool, config);
      await transaction.begin();
      return transaction;
    } catch (e) {
      throw DatabaseException('Failed to begin write transaction: $e', null, e);
    }
  }


  @override
  String toString() {
    return 'Session{config: $config, closed: $_closed, bookmarks: ${_lastBookmarks.length}}';
  }
}