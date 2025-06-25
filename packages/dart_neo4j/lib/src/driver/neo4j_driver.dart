import 'dart:io';

import 'package:dart_neo4j/src/auth/auth_token.dart';
import 'package:dart_neo4j/src/connection/connection_pool.dart';
import 'package:dart_neo4j/src/driver/uri_parser.dart';
import 'package:dart_neo4j/src/exceptions/connection_exception.dart';
import 'package:dart_neo4j/src/exceptions/neo4j_exception.dart';
import 'package:dart_neo4j/src/session/session.dart';
import 'package:dart_neo4j/src/session/session_impl.dart';

/// Configuration for the Neo4j driver.
class DriverConfig {
  /// The maximum number of connections in the connection pool.
  final int maxConnectionPoolSize;

  /// The connection timeout.
  final Duration connectionTimeout;

  /// The maximum transaction retry time.
  final Duration maxTransactionRetryTime;

  /// Whether to enable encrypted connections.
  final bool? encrypted;

  /// Whether to trust all certificates (for development only).
  final bool trustAllCertificates;

  /// Path to custom CA certificate file for SSL connections.
  /// If provided, this CA certificate will be trusted for SSL connections.
  final String? customCACertificatePath;

  /// Custom certificate validator function.
  /// If provided, this function will be called to validate certificates.
  final bool Function(X509Certificate)? certificateValidator;

  /// Creates a new driver configuration.
  const DriverConfig({
    this.maxConnectionPoolSize = 100,
    this.connectionTimeout = const Duration(seconds: 30),
    this.maxTransactionRetryTime = const Duration(seconds: 30),
    this.encrypted,
    this.trustAllCertificates = false,
    this.customCACertificatePath,
    this.certificateValidator,
  });

  @override
  String toString() {
    return 'DriverConfig{maxConnectionPoolSize: $maxConnectionPoolSize, connectionTimeout: $connectionTimeout}';
  }
}

/// The main Neo4j driver for connecting to a Neo4j database.
abstract class Neo4jDriver {
  /// Creates a new Neo4j driver.
  ///
  /// [uri] - the connection URI (e.g., 'bolt://localhost:7687')
  /// [auth] - the authentication token (default: no authentication)
  /// [config] - driver configuration (default: default configuration)
  ///
  /// Throws [InvalidUriException] if the URI is invalid.
  /// Throws [ServiceUnavailableException] if the server is not available.
  factory Neo4jDriver.create(
    String uri, {
    AuthToken? auth,
    DriverConfig? config,
  }) {
    // Parse the URI
    final parsedUri = UriParser.parse(uri);

    // Use default auth if none provided
    final authToken = auth ?? NoAuth();

    // Use default config if none provided
    final driverConfig = config ?? const DriverConfig();

    // Create the appropriate driver implementation
    return _Neo4jDriverImpl(parsedUri, authToken, driverConfig);
  }

  /// The parsed URI for this driver.
  ParsedUri get uri;

  /// The authentication token for this driver.
  AuthToken get auth;

  /// The configuration for this driver.
  DriverConfig get config;

  /// Whether this driver has been closed.
  bool get isClosed;

  /// Creates a new session with the default configuration.
  ///
  /// Throws [ServiceUnavailableException] if the driver is closed or the server is not available.
  Session session([SessionConfig? config]);

  /// Verifies connectivity to the Neo4j server.
  ///
  /// This method attempts to establish a connection to the server and perform
  /// a simple verification query.
  ///
  /// Throws [ServiceUnavailableException] if the server is not available.
  /// Throws [AuthenticationException] if authentication fails.
  Future<void> verifyConnectivity();

  /// Closes this driver and releases all associated resources.
  ///
  /// After calling this method, the driver cannot be used to create new sessions.
  Future<void> close();
}

/// Internal implementation of the Neo4j driver.
class _Neo4jDriverImpl implements Neo4jDriver {
  final ParsedUri _uri;
  final AuthToken _auth;
  final DriverConfig _config;
  final ConnectionPool _connectionPool;
  bool _isClosed = false;

  _Neo4jDriverImpl(this._uri, this._auth, this._config)
    : _connectionPool = ConnectionPool(
        _uri,
        _auth,
        ConnectionPoolConfig(
          maxSize: _config.maxConnectionPoolSize,
          connectionTimeout: _config.connectionTimeout,
          customCACertificatePath: _config.customCACertificatePath,
          certificateValidator: _config.certificateValidator,
        ),
      );

  @override
  ParsedUri get uri => _uri;

  @override
  AuthToken get auth => _auth;

  @override
  DriverConfig get config => _config;

  @override
  bool get isClosed => _isClosed;

  @override
  Session session([SessionConfig? config]) {
    if (_isClosed) {
      throw const ServiceUnavailableException('Driver has been closed');
    }

    final sessionConfig = config ?? const SessionConfig();
    return SessionImpl(_connectionPool, sessionConfig);
  }

  @override
  Future<void> verifyConnectivity() async {
    if (_isClosed) {
      throw const ServiceUnavailableException('Driver has been closed');
    }

    // Attempt to acquire and immediately release a connection
    try {
      final connection = await _connectionPool.acquire();
      _connectionPool.release(connection);
    } catch (e) {
      // Let specific exceptions pass through, wrap others in ServiceUnavailableException
      if (e is AuthenticationException) {
        rethrow;
      }
      if (e is ServiceUnavailableException) {
        rethrow;
      }
      throw ServiceUnavailableException('Failed to verify connectivity: $e', e);
    }
  }

  @override
  Future<void> close() async {
    if (_isClosed) {
      return;
    }

    _isClosed = true;

    // Close connection pool
    await _connectionPool.close();
  }

  @override
  String toString() {
    return 'Neo4jDriver{uri: ${UriParser.createDisplayString(_uri)}, closed: $_isClosed}';
  }
}
