import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_bolt/dart_bolt.dart';
import 'package:dart_neo4j/dart_neo4j_version.dart';
import 'package:dart_neo4j/src/auth/auth_token.dart';
import 'package:dart_neo4j/src/auth/basic_auth.dart';
import 'package:dart_neo4j/src/driver/uri_parser.dart';
import 'package:dart_neo4j/src/exceptions/neo4j_exception.dart';
import 'package:dart_neo4j/src/result/record.dart';
import 'package:dart_neo4j/src/result/result.dart';
import 'package:dart_neo4j/src/result/summary.dart';

/// A Bolt protocol connection that handles Neo4j communication.
class BoltConnection {
  final ParsedUri _uri;
  final AuthToken _auth;
  late final BoltSocket _socket;
  late final BoltProtocol _protocol;

  BoltServerState _serverState = BoltServerState.disconnected;
  final List<Completer<BoltMessage>> _pendingRequests = [];

  // Streaming result tracking
  Result? _currentStreamingResult;
  List<String>? _currentStreamingKeys;

  StreamSubscription<Uint8List>? _dataSubscription;

  /// Creates a new Bolt connection.
  BoltConnection(
    this._uri,
    this._auth, {
    Duration? connectionTimeout,
    String? customCACertificatePath,
    bool Function(X509Certificate)? certificateValidator,
  }) {
    _socket = BoltSocket(
      BoltSocketConfig(
        host: _uri.host,
        port: _uri.port,
        encrypted: _uri.encrypted,
        allowSelfSignedCertificates: _uri.allowsSelfSignedCertificates,
        connectionTimeout: connectionTimeout ?? const Duration(seconds: 30),
        customCACertificatePath: customCACertificatePath,
        certificateValidator: certificateValidator,
      ),
    );
    _protocol = BoltProtocol(_socket);
  }

  /// The current server state of this connection.
  BoltServerState get serverState => _serverState;

  /// Whether this connection is ready to execute queries.
  bool get isReady => _serverState == BoltServerState.ready;

  /// Whether this connection is closed or failed.
  bool get isClosed => _serverState == BoltServerState.defunct;

  /// The agreed Bolt protocol version.
  int? get protocolVersion => _protocol.agreedVersion;

  /// Establishes and initializes the Bolt connection.
  ///
  /// This performs the full Bolt handshake and authentication.
  Future<void> connect([List<BoltVersion>? forcedVersions]) async {
    if (_serverState != BoltServerState.disconnected &&
        _serverState != BoltServerState.defunct) {
      throw ConnectionException(
        'Cannot connect from server state: $_serverState',
      );
    }

    try {
      _serverState = BoltServerState.disconnected;

      // Register Bolt structures
      registerBolt();

      // Establish socket connection
      await _socket.connect();

      // Perform Bolt handshake (before setting up message processing)
      await _protocol.performHandshake(forcedVersions);

      // Set up data processing for chunked messages
      _dataSubscription = _socket.dataStream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );

      // Authenticate
      await _authenticate();

      // Server is now ready after successful authentication
    } catch (e) {
      _serverState = BoltServerState.defunct;
      await _cleanup();
      rethrow;
    }
  }

  Future<void> _authenticate() {
    final version = BoltVersion.raw(protocolVersion!);
    return (version < BoltVersion.v5_1)
        ? _authenticateWithoutLogon()
        : _authenticateWithLogon();
  }

  /// Authenticates with the Neo4j server using HELLO flow.
  Future<void> _authenticateWithoutLogon() async {
    // Step 1: Send HELLO message (with authentication for older protocols)
    _serverState = BoltServerState.authentication;

    final helloMessage = switch (_auth) {
      BasicAuth auth => BoltMessageFactory.helloWithAuth(
        userAgent: 'dart_neo4j/$version',
        username: auth.username,
        password: auth.password,
        boltAgent: {
          'product': 'dart_neo4j/$version',
          'platform': 'Dart',
          'language': 'Dart',
        },
      ),
      NoAuth() => BoltMessageFactory.hello(
        userAgent: 'dart_neo4j/$version',
        boltAgent: {
          'product': 'dart_neo4j/$version',
          'platform': 'Dart',
          'language': 'Dart',
        },
      ),
      _ => throw ProtocolException(
        'Unsupported AuthToken ${_auth.runtimeType}',
      ),
    };

    final helloResponse = await _sendMessage(helloMessage);

    if (helloResponse is! BoltSuccessMessage) {
      if (helloResponse is BoltFailureMessage) {
        _serverState = BoltServerState.failed;
        final metadata =
            helloResponse.metadata.dartValue as Map<String, dynamic>? ??
            const {};
        final code = metadata['code'] as String? ?? 'unknown';
        final message =
            metadata['message'] as String? ?? 'Authentication failed';
        throw _isAuthError(code, message)
            ? AuthenticationException(message)
            : DatabaseException(message, code);
      } else {
        throw ProtocolException(
          'Unexpected response to HELLO: ${helloResponse.runtimeType}',
        );
      }
    }

    // Authentication successful - server is now in READY state
    _serverState = BoltServerState.ready;
    return;
  }

  /// Authenticates with the Neo4j server using HELLO/LOGON flow.
  Future<void> _authenticateWithLogon() async {
    // Step 1: Send HELLO message (without authentication for newer protocols)
    _serverState = BoltServerState.authentication;

    final helloMessage = BoltMessageFactory.hello(
      userAgent: 'dart_neo4j/$version',
      boltAgent: {
        'product': 'dart_neo4j/$version',
        'platform': 'Dart',
        'language': 'Dart',
      },
    );

    final helloResponse = await _sendMessage(helloMessage);

    if (helloResponse is! BoltSuccessMessage) {
      if (helloResponse is BoltFailureMessage) {
        _serverState = BoltServerState.failed;
        final metadata =
            helloResponse.metadata.dartValue as Map<String, dynamic>? ??
            const {};
        final code = metadata['code'] as String? ?? 'unknown';
        final message = metadata['message'] as String? ?? 'HELLO failed';
        throw DatabaseException(message, code);
      } else {
        throw ProtocolException(
          'Unexpected response to HELLO: ${helloResponse.runtimeType}',
        );
      }
    }

    // Step 2: Send LOGON message with authentication details
    final logonMessage = _createLogonMessage();
    final logonResponse = await _sendMessage(logonMessage);

    if (logonResponse is BoltSuccessMessage) {
      // Authentication successful - server is now in READY state
      _serverState = BoltServerState.ready;
      return;
    } else if (logonResponse is BoltFailureMessage) {
      _serverState = BoltServerState.failed;
      final metadata =
          logonResponse.metadata.dartValue as Map<String, dynamic>? ?? const {};
      final code = metadata['code'] as String? ?? 'unknown';
      final message = metadata['message'] as String? ?? 'Authentication failed';
      throw _isAuthError(code, message)
          ? AuthenticationException(message)
          : DatabaseException(message, code);
    } else {
      throw ProtocolException(
        'Unexpected response to LOGON: ${logonResponse.runtimeType}',
      );
    }
  }

  static bool _isAuthError(String code, String message) {
    code = code.toLowerCase();
    if (code.startsWith('neo.clienterror.security.unauthorized')) return true;
    message = message.toLowerCase();
    return message.contains('unauthorized') ||
        message.contains('authentication fail');
  }

  /// Creates a LOGON message based on the authentication token type.
  BoltLogonMessage _createLogonMessage() {
    if (_auth is BasicAuth) {
      return BoltMessageFactory.logon(
        scheme: 'basic',
        principal: _auth.username,
        credentials: _auth.password,
        realm: _auth.realm,
      );
    } else {
      // Handle other auth types using the generic AuthToken interface
      final authData = _auth.toAuthData();
      return BoltMessageFactory.logon(
        scheme: authData['scheme'] as String,
        principal: authData['principal'] as String?,
        credentials: authData['credentials'] as String?,
        realm: authData['realm'] as String?,
      );
    }
  }

  /// Begins an explicit transaction.
  Future<void> beginTransaction({
    List<String>? bookmarks,
    int? txTimeout,
    Map<String, Object?>? txMetadata,
    String? mode,
    String? db,
  }) async {
    if (!isReady) {
      throw ConnectionException(
        'Connection not ready for transactions (server state: $_serverState)',
      );
    }

    try {
      final beginMessage = BoltMessageFactory.begin(
        bookmarks: bookmarks ?? const [],
        txTimeout: txTimeout,
        txMetadata: txMetadata ?? const {},
        mode: mode,
        db: db,
      );

      final beginResponse = await _sendMessage(beginMessage);

      if (beginResponse is BoltSuccessMessage) {
        // Transaction started successfully - server transitions to TX_READY state
        _serverState = BoltServerState.txReady;
      } else if (beginResponse is BoltFailureMessage) {
        // BEGIN failed - server transitions to FAILED state
        _serverState = BoltServerState.failed;
        final metadata =
            beginResponse.metadata.dartValue as Map<String, dynamic>? ??
            const {};
        final code = metadata['code'] as String? ?? 'unknown';
        final message =
            metadata['message'] as String? ?? 'Transaction begin failed';
        throw DatabaseException(message, code);
      } else {
        throw ProtocolException(
          'Unexpected response to BEGIN: ${beginResponse.runtimeType}',
        );
      }
    } catch (e) {
      throw DatabaseException('Failed to begin transaction: $e', null, e);
    }
  }

  /// Commits an explicit transaction.
  Future<void> commitTransaction() async {
    if (_serverState != BoltServerState.txReady) {
      throw ConnectionException(
        'Cannot commit transaction (server state: $_serverState)',
      );
    }

    try {
      final commitMessage = BoltMessageFactory.commit();
      final commitResponse = await _sendMessage(commitMessage);

      if (commitResponse is BoltSuccessMessage) {
        // Transaction committed successfully - server returns to READY state
        _serverState = BoltServerState.ready;
      } else if (commitResponse is BoltFailureMessage) {
        // COMMIT failed - server transitions to FAILED state
        _serverState = BoltServerState.failed;
        final metadata =
            commitResponse.metadata.dartValue as Map<String, dynamic>? ??
            const {};
        final code = metadata['code'] as String? ?? 'unknown';
        final message =
            metadata['message'] as String? ?? 'Transaction commit failed';
        throw DatabaseException(message, code);
      } else {
        throw ProtocolException(
          'Unexpected response to COMMIT: ${commitResponse.runtimeType}',
        );
      }
    } catch (e) {
      throw DatabaseException('Failed to commit transaction: $e', null, e);
    }
  }

  /// Rolls back an explicit transaction.
  Future<void> rollbackTransaction() async {
    if (_serverState != BoltServerState.txReady) {
      throw ConnectionException(
        'Cannot rollback transaction (server state: $_serverState)',
      );
    }

    try {
      final rollbackMessage = BoltMessageFactory.rollback();
      final rollbackResponse = await _sendMessage(rollbackMessage);

      if (rollbackResponse is BoltSuccessMessage) {
        // Transaction rolled back successfully - server returns to READY state
        _serverState = BoltServerState.ready;
      } else if (rollbackResponse is BoltFailureMessage) {
        // ROLLBACK failed - server transitions to FAILED state
        _serverState = BoltServerState.failed;
        final metadata =
            rollbackResponse.metadata.dartValue as Map<String, dynamic>? ??
            const {};
        final code = metadata['code'] as String? ?? 'unknown';
        final message =
            metadata['message'] as String? ?? 'Transaction rollback failed';
        throw DatabaseException(message, code);
      } else {
        throw ProtocolException(
          'Unexpected response to ROLLBACK: ${rollbackResponse.runtimeType}',
        );
      }
    } catch (e) {
      throw DatabaseException('Failed to rollback transaction: $e', null, e);
    }
  }

  /// Runs a Cypher query and returns the result immediately.
  ///
  /// This method returns before the `PULL` operation is complete. It means
  /// [Result] can be used for streaming records immediately, but the query
  /// is still executing until [Result.done] completes. In the meantime, the
  /// connection is busy and cannot accept new requests.
  Future<Result> startQuery(
    String cypher, [
    Map<String, dynamic> parameters = const {},
    Duration? timeout,
  ]) async {
    // Check if server is in FAILED state and attempt recovery
    if (_serverState == BoltServerState.failed) {
      try {
        await _resetConnection();
      } catch (e) {
        throw ConnectionException(
          'Failed to reset connection from FAILED state: $e',
        );
      }
    }

    if (!isReady && _serverState != BoltServerState.txReady) {
      throw ConnectionException(
        'Connection not ready for queries (server state: $_serverState)',
      );
    }

    try {
      // Send RUN message (for protocol v5+, extra field is required)
      final runMessage = BoltMessageFactory.run(
        cypher,
        parameters: parameters,
        extra: {}, // Required for protocol v5+
      );
      final runResponse = await _sendMessage(runMessage);

      // Handle RUN response and update server state
      List<String> keys = [];
      if (runResponse is BoltSuccessMessage) {
        // RUN succeeded - server transitions to STREAMING or TX_STREAMING state
        if (_serverState == BoltServerState.txReady) {
          _serverState = BoltServerState.txStreaming;
        } else {
          _serverState = BoltServerState.streaming;
        }
        final metadata =
            runResponse.metadata?.dartValue as Map<String, dynamic>? ??
            const {};
        final fieldsData = metadata['fields'] as List<dynamic>? ?? const [];
        keys = fieldsData.cast<String>();
      } else if (runResponse is BoltFailureMessage) {
        // RUN failed - server transitions to FAILED state
        _serverState = BoltServerState.failed;
        final metadata =
            runResponse.metadata.dartValue as Map<String, dynamic>? ?? const {};
        final code = metadata['code'] as String? ?? 'unknown';
        final message =
            metadata['message'] as String? ?? 'Query execution failed';
        throw DatabaseException(message, code);
      } else if (runResponse is BoltIgnoredMessage) {
        // RUN was ignored, likely because server is in FAILED state
        throw DatabaseException(
          'Query was ignored by server (likely due to previous error)',
          'Neo.ClientError.Request.Invalid',
        );
      } else {
        throw ProtocolException(
          'Unexpected response to RUN: ${runResponse.runtimeType}',
        );
      }

      // Create result
      final result = Result.forQuery(cypher, parameters, keys);

      // Send PULL message but do not wait for completion - records will be collected via _handleMessage
      final pullMessage = BoltMessageFactory.pull();
      _sendMessage(pullMessage, timeout).then(
        (pullResponse) {
          if (pullResponse is BoltSuccessMessage) {
            // PULL completed successfully - server returns to READY or TX_READY state
            if (_serverState == BoltServerState.txStreaming) {
              _serverState = BoltServerState.txReady;
            } else {
              _serverState = BoltServerState.ready;
            }
            result.complete(
              _createResultSummary(pullResponse, cypher, parameters),
            );
          } else if (pullResponse is BoltFailureMessage) {
            // PULL failed - server transitions to FAILED state
            _serverState = BoltServerState.failed;
            final metadata =
                pullResponse.metadata.dartValue as Map<String, dynamic>? ??
                const {};
            final code = metadata['code'] as String? ?? 'unknown';
            final message =
                metadata['message'] as String? ?? 'Result fetch failed';
            result.completeWithError(DatabaseException(message, code));
          } else if (pullResponse is BoltIgnoredMessage) {
            // PULL was ignored - server likely already in FAILED state
            result.completeWithError(
              DatabaseException(
                'Query was ignored by server',
                'Neo.ClientError.Request.Invalid',
              ),
            );
          } else {
            result.completeWithError(
              ProtocolException(
                'Unexpected response to PULL: ${pullResponse.runtimeType}',
              ),
            );
          }
        },
        onError: (ex, st) {
          if (ex is ConnectionTimeoutException) {
            result.completeWithError(
              Exception(
                'The PULL operation has been cancelled after $timeout.',
              ),
              st,
            );
          } else {
            result.completeWithError(ex, st);
          }
        },
      );

      _currentStreamingResult = result;
      _currentStreamingKeys = keys;

      return result;
    } catch (e) {
      throw DatabaseException('Failed to execute query: $e', null, e);
    }
  }

  /// Runs a Cypher query and returns the result.
  ///
  /// This method returns after the query has finished executing.
  Future<Result> run(
    String cypher, [
    Map<String, dynamic> parameters = const {},
    Duration? timeout,
  ]) async {
    final result = await startQuery(cypher, parameters, timeout);
    await result.done;
    return result;
  }

  /// Sends a message and waits for a response.
  Future<BoltMessage> _sendMessage(
    BoltMessage message, [
    Duration? timeout,
  ]) async {
    final completer = Completer<BoltMessage>();
    _pendingRequests.add(completer);

    if (_currentStreamingResult != null) {
      throw ProtocolException(
        'A pull operation is in progress, cannot send a new message before the end of the stream.',
      );
    }

    try {
      _protocol.sendMessage(message);

      timeout ??= const Duration(seconds: 30);
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          _pendingRequests.remove(completer);
          throw ConnectionTimeoutException(
            'Message timeout: no response received',
            timeout,
          );
        },
      );
    } catch (e) {
      _pendingRequests.remove(completer);
      rethrow;
    }
  }

  /// Processes incoming data from the socket.
  void _onData(Uint8List data) {
    try {
      final messages = _protocol.parseData(data);
      for (final message in messages) {
        _handleMessage(message);
      }
    } catch (e, stackTrace) {
      _onError(e, stackTrace);
    }
  }

  /// Handles a received Bolt message.
  void _handleMessage(BoltMessage message) {
    // Handle different message types appropriately
    if (message is BoltRecordMessage) {
      // RECORD messages are streaming data - add to current result if we're streaming
      if (_currentStreamingResult != null && _currentStreamingKeys != null) {
        // Use the raw PsList values instead of dartValue to preserve Bolt structures
        final recordData = message.data.value;
        final record = Record.fromBolt(_currentStreamingKeys!, recordData);
        _currentStreamingResult!.addRecord(record);
      }

      // Don't complete requests yet - wait for summary message
    } else if (message is BoltSuccessMessage ||
        message is BoltFailureMessage ||
        message is BoltIgnoredMessage) {
      // Summary messages complete the current request
      if (_pendingRequests.isNotEmpty) {
        final completer = _pendingRequests.first;
        _pendingRequests.clear();
        completer.complete(message);
      }

      // Clear streaming state
      _currentStreamingResult = null;
      _currentStreamingKeys = null;
    } else {
      // Other messages complete requests immediately
      if (_pendingRequests.isNotEmpty) {
        final completer = _pendingRequests.first;
        _pendingRequests.clear();
        completer.complete(message);
      }
    }
  }

  /// Handles connection errors.
  void _onError(Object error, StackTrace stackTrace) {
    _serverState = BoltServerState.defunct;

    // Complete all pending requests with error
    for (final completer in _pendingRequests) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    }
    _pendingRequests.clear();
  }

  /// Handles connection close events.
  void _onDone() {
    _serverState = BoltServerState.defunct;
    _cleanup();
  }

  /// Closes the connection.
  Future<void> close() async {
    if (isClosed) return;

    try {
      if (isReady) {
        final goodbyeMessage = BoltMessageFactory.goodbye();
        await _sendMessage(goodbyeMessage);
      }
    } catch (e) {
      // Ignore errors during goodbye
    }

    _serverState = BoltServerState.defunct;
    await _cleanup();
  }

  /// Resets the connection from FAILED state to READY state.
  Future<void> _resetConnection() async {
    if (_serverState != BoltServerState.failed) {
      return; // Nothing to reset
    }

    try {
      final resetMessage = BoltMessageFactory.reset();
      final resetResponse = await _sendMessage(resetMessage);

      if (resetResponse is BoltSuccessMessage) {
        // RESET succeeded - server returns to READY state
        _serverState = BoltServerState.ready;
      } else if (resetResponse is BoltFailureMessage) {
        // RESET failed - connection is likely defunct
        _serverState = BoltServerState.defunct;
        final metadata =
            resetResponse.metadata.dartValue as Map<String, dynamic>? ??
            const {};
        final code = metadata['code'] as String? ?? 'unknown';
        final message = metadata['message'] as String? ?? 'Reset failed';
        throw ConnectionException(
          'Failed to reset connection: $message (Code: $code)',
        );
      } else {
        throw ProtocolException(
          'Unexpected response to RESET: ${resetResponse.runtimeType}',
        );
      }
    } catch (e) {
      _serverState = BoltServerState.defunct;
      rethrow;
    }
  }

  /// Creates a result summary from a success message.
  ResultSummary _createResultSummary(
    BoltSuccessMessage message,
    String query,
    Map<String, dynamic> parameters,
  ) {
    final metadata =
        message.metadata?.dartValue as Map<String, dynamic>? ?? const {};
    return ResultSummary.fromMetadata(query, parameters, metadata);
  }

  /// Cleans up resources.
  Future<void> _cleanup() async {
    await _dataSubscription?.cancel();
    _dataSubscription = null;

    await _socket.close();

    // Complete pending requests with error
    for (final completer in _pendingRequests) {
      if (!completer.isCompleted) {
        completer.completeError(const ConnectionException('Connection closed'));
      }
    }
    _pendingRequests.clear();
  }

  @override
  String toString() =>
      'BoltConnection{uri: ${_uri.host}:${_uri.port},'
      ' serverState: $_serverState,'
      ' version: ${protocolVersion?.toRadixString(16)}}';
}
