import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:dart_bolt/dart_bolt.dart' as bolt;
import 'package:dart_neo4j/src/auth/auth_token.dart';
import 'package:dart_neo4j/src/connection/bolt_connection.dart';
import 'package:dart_neo4j/src/driver/uri_parser.dart';
import 'package:dart_neo4j/src/exceptions/connection_exception.dart';

/// Configuration for a connection pool.
class ConnectionPoolConfig {
  /// The maximum number of connections in the pool.
  final int maxSize;

  /// The minimum number of connections to maintain in the pool.
  final int minSize;

  /// The connection timeout.
  final Duration connectionTimeout;

  /// The maximum time a connection can be idle before being closed.
  final Duration maxIdleTime;

  /// The time to wait for a connection to become available.
  final Duration acquisitionTimeout;

  /// Path to custom CA certificate file for SSL connections.
  final String? customCACertificatePath;

  /// Custom certificate validator function.
  final bool Function(X509Certificate)? certificateValidator;

  /// Creates a new connection pool configuration.
  const ConnectionPoolConfig({
    this.maxSize = 100,
    this.minSize = 1,
    this.connectionTimeout = const Duration(seconds: 30),
    this.maxIdleTime = const Duration(minutes: 30),
    this.acquisitionTimeout = const Duration(seconds: 60),
    this.customCACertificatePath,
    this.certificateValidator,
  });

  @override
  String toString() {
    return 'ConnectionPoolConfig{maxSize: $maxSize, minSize: $minSize, connectionTimeout: $connectionTimeout}';
  }
}

/// Represents a pooled connection with metadata.
class PooledConnection {
  final BoltConnection connection;
  final DateTime createdAt;
  DateTime lastUsedAt;
  bool inUse;

  /// Creates a new pooled connection.
  PooledConnection(this.connection)
      : createdAt = DateTime.now(),
        lastUsedAt = DateTime.now(),
        inUse = false;

  /// Whether this connection is idle.
  bool get isIdle => !inUse;

  /// Whether this connection has been idle for too long.
  bool isIdleFor(Duration maxIdleTime) {
    return isIdle && DateTime.now().difference(lastUsedAt) > maxIdleTime;
  }

  /// Marks this connection as being used.
  void markInUse() {
    inUse = true;
    lastUsedAt = DateTime.now();
  }

  /// Marks this connection as available.
  void markAvailable() {
    inUse = false;
    lastUsedAt = DateTime.now();
  }

  @override
  String toString() {
    return 'PooledConnection{connection: $connection, inUse: $inUse, lastUsed: $lastUsedAt}';
  }
}

/// A connection pool that manages Bolt connections to Neo4j.
class ConnectionPool {
  final ParsedUri _uri;
  final AuthToken _auth;
  final ConnectionPoolConfig _config;
  
  final Queue<PooledConnection> _availableConnections = Queue<PooledConnection>();
  final Set<PooledConnection> _allConnections = <PooledConnection>{};
  final Queue<Completer<PooledConnection>> _waitingQueue = Queue<Completer<PooledConnection>>();
  
  bool _closed = false;
  Timer? _cleanupTimer;

  /// Creates a new connection pool.
  ConnectionPool(this._uri, this._auth, [ConnectionPoolConfig? config])
      : _config = config ?? const ConnectionPoolConfig() {
    _startCleanupTimer();
  }

  /// The configuration for this pool.
  ConnectionPoolConfig get config => _config;

  /// The number of connections currently in the pool.
  int get size => _allConnections.length;

  /// The number of available connections.
  int get availableCount => _availableConnections.length;

  /// The number of connections currently in use.
  int get inUseCount => _allConnections.where((conn) => conn.inUse).length;

  /// Whether this pool is closed.
  bool get isClosed => _closed;

  /// Acquires a connection from the pool.
  ///
  /// If no connection is available and the pool is not at capacity,
  /// a new connection will be created. If the pool is at capacity,
  /// the method will wait for a connection to become available.
  ///
  /// Throws [ServiceUnavailableException] if the pool is closed.
  /// Throws [ConnectionTimeoutException] if no connection becomes available within the timeout.
  Future<PooledConnection> acquire() async {
    if (_closed) {
      throw const ServiceUnavailableException('Connection pool is closed');
    }

    // Try to get an available connection
    PooledConnection? connection = _getAvailableConnection();
    if (connection != null) {
      connection.markInUse();
      return connection;
    }

    // Try to create a new connection if under capacity
    if (_allConnections.length < _config.maxSize) {
      try {
        connection = await _createConnection();
        connection.markInUse();
        return connection;
      } catch (e) {
        // If there are no connections available and creation fails, immediately fail
        if (_allConnections.isEmpty) {
          rethrow;
        }
        // Fall through to waiting queue if creation fails but other connections exist
      }
    }

    // Wait for a connection to become available
    final completer = Completer<PooledConnection>();
    _waitingQueue.add(completer);

    try {
      return await completer.future.timeout(
        _config.acquisitionTimeout,
        onTimeout: () {
          _waitingQueue.remove(completer);
          throw ConnectionTimeoutException(
            'Timed out waiting for connection from pool',
            _config.acquisitionTimeout,
          );
        },
      );
    } catch (e) {
      _waitingQueue.remove(completer);
      rethrow;
    }
  }

  /// Releases a connection back to the pool.
  ///
  /// If there are waiting requests, the connection will be immediately
  /// given to the next waiting request. Otherwise, it will be returned
  /// to the available pool.
  void release(PooledConnection connection) {
    if (!_allConnections.contains(connection)) {
      return; // Connection not from this pool
    }

    if (connection.connection.isClosed) {
      _removeConnection(connection);
      return;
    }

    connection.markAvailable();

    // Give to waiting request if any
    if (_waitingQueue.isNotEmpty) {
      final completer = _waitingQueue.removeFirst();
      connection.markInUse();
      completer.complete(connection);
      return;
    }

    // Return to available pool
    _availableConnections.add(connection);

    // Maintain minimum pool size
    _ensureMinimumPoolSize();
  }

  /// Closes the connection pool and all connections.
  Future<void> close() async {
    if (_closed) return;

    _closed = true;
    _cleanupTimer?.cancel();

    // Complete waiting requests with error
    while (_waitingQueue.isNotEmpty) {
      final completer = _waitingQueue.removeFirst();
      if (!completer.isCompleted) {
        completer.completeError(const ServiceUnavailableException('Connection pool closed'));
      }
    }

    // Close all connections
    final futures = <Future<void>>[];
    for (final pooledConnection in List.from(_allConnections)) {
      futures.add(pooledConnection.connection.close());
    }
    await Future.wait(futures, eagerError: false);

    _allConnections.clear();
    _availableConnections.clear();
  }

  /// Gets an available connection from the pool.
  PooledConnection? _getAvailableConnection() {
    while (_availableConnections.isNotEmpty) {
      final connection = _availableConnections.removeFirst();
      
      if (connection.connection.isClosed) {
        _removeConnection(connection);
        continue;
      }

      // Check if connection is in FAILED state and try to reset it
      if (connection.connection.serverState == bolt.BoltServerState.failed) {
        // Try to reset the connection to make it usable again
        try {
          // We can't await here, so we'll remove failed connections and let a new one be created
          _removeConnection(connection);
          continue;
        } catch (e) {
          // If reset fails, remove the connection
          _removeConnection(connection);
          continue;
        }
      }

      return connection;
    }
    return null;
  }

  /// Creates a new connection.
  Future<PooledConnection> _createConnection() async {
    final boltConnection = BoltConnection(
      _uri,
      _auth,
      connectionTimeout: _config.connectionTimeout,
      customCACertificatePath: _config.customCACertificatePath,
      certificateValidator: _config.certificateValidator,
    );

    try {
      await boltConnection.connect();
      final pooledConnection = PooledConnection(boltConnection);
      _allConnections.add(pooledConnection);
      return pooledConnection;
    } catch (e) {
      await boltConnection.close();
      rethrow;
    }
  }

  /// Removes a connection from the pool.
  void _removeConnection(PooledConnection connection) {
    _allConnections.remove(connection);
    _availableConnections.remove(connection);
    connection.connection.close();
  }

  /// Ensures the pool maintains the minimum number of connections.
  void _ensureMinimumPoolSize() {
    if (_closed) return;

    final currentSize = _allConnections.length;
    final needed = _config.minSize - currentSize;

    if (needed > 0) {
      // Create connections asynchronously to maintain minimum size
      for (int i = 0; i < needed; i++) {
        _createConnection().then((connection) {
          if (!_closed) {
            _availableConnections.add(connection);
          } else {
            connection.connection.close();
          }
        }).catchError((error) {
          // Ignore errors during background connection creation
        });
      }
    }
  }

  /// Starts the cleanup timer to remove idle connections.
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupIdleConnections();
    });
  }

  /// Removes connections that have been idle for too long.
  void _cleanupIdleConnections() {
    if (_closed) return;

    final toRemove = <PooledConnection>[];
    final currentSize = _allConnections.length;

    for (final connection in _availableConnections) {
      if (connection.isIdleFor(_config.maxIdleTime) && currentSize > _config.minSize) {
        toRemove.add(connection);
      }
    }

    for (final connection in toRemove) {
      _removeConnection(connection);
    }
  }

  @override
  String toString() {
    return 'ConnectionPool{size: $size, available: $availableCount, inUse: $inUseCount, closed: $_closed}';
  }
}