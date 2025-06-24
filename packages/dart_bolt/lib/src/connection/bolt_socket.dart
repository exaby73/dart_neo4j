import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_bolt/src/connection/connection_state.dart';
import 'package:dart_bolt/src/connection/connection_exceptions.dart';

/// Configuration for a Bolt socket connection.
class BoltSocketConfig {
  /// The host to connect to.
  final String host;

  /// The port to connect to.
  final int port;

  /// Whether to use SSL/TLS encryption.
  final bool encrypted;

  /// Whether to allow self-signed certificates (only relevant if encrypted is true).
  final bool allowSelfSignedCertificates;

  /// Connection timeout duration.
  final Duration connectionTimeout;

  /// Path to custom CA certificate file for SSL connections.
  /// If provided, this CA certificate will be trusted for SSL connections.
  final String? customCACertificatePath;

  /// Custom CA certificate bytes for SSL connections.
  /// If provided, this CA certificate will be trusted for SSL connections.
  final List<int>? customCACertificateBytes;

  /// Custom certificate validator function.
  /// If provided, this function will be called to validate certificates.
  final bool Function(X509Certificate)? certificateValidator;

  /// Creates a new Bolt socket configuration.
  const BoltSocketConfig({
    required this.host,
    required this.port,
    this.encrypted = false,
    this.allowSelfSignedCertificates = false,
    this.connectionTimeout = const Duration(seconds: 30),
    this.customCACertificatePath,
    this.customCACertificateBytes,
    this.certificateValidator,
  });
}

/// A low-level socket wrapper for Bolt protocol communication.
class BoltSocket {
  final BoltSocketConfig _config;

  Socket? _socket;
  BoltSocketState _state = BoltSocketState.disconnected;
  final StreamController<Uint8List> _dataController =
      StreamController<Uint8List>.broadcast();
  StreamSubscription<Uint8List>? _socketSubscription;
  Completer<void>? _connectionCompleter;

  /// Creates a new Bolt socket.
  BoltSocket(this._config);

  /// The current state of this socket.
  BoltSocketState get state => _state;

  /// Whether this socket is connected and ready for use.
  bool get isConnected => _state == BoltSocketState.connected;

  /// Whether this socket is closed or failed.
  bool get isClosed =>
      _state == BoltSocketState.closed || _state == BoltSocketState.failed;

  /// Stream of data received from the server.
  Stream<Uint8List> get dataStream => _dataController.stream;

  /// The remote address of this connection.
  String get remoteAddress => '${_config.host}:${_config.port}';

  /// Establishes a connection to the Bolt server.
  ///
  /// Throws [ConnectionTimeoutException] if the connection times out.
  /// Throws [ServiceUnavailableException] if the server is not available.
  /// Throws [SecurityException] if SSL/TLS handshake fails.
  Future<void> connect() async {
    if (_state != BoltSocketState.disconnected &&
        _state != BoltSocketState.failed) {
      throw ConnectionException('Cannot connect from state: $_state');
    }

    _state = BoltSocketState.connecting;
    _connectionCompleter = Completer<void>();

    try {
      // Establish socket connection
      _socket = await _createSocket();

      // Set up data stream
      _socketSubscription = _socket!.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );

      _state = BoltSocketState.connected;
      _connectionCompleter!.complete();
    } catch (e) {
      _state = BoltSocketState.failed;
      await _cleanup();
      rethrow;
    }
  }

  /// Creates the appropriate socket based on the configuration.
  Future<Socket> _createSocket() async {
    try {
      Socket socket;

      if (_config.encrypted) {
        // Prepare SSL context with custom CA if provided
        SecurityContext? context;
        if (_config.customCACertificatePath != null) {
          context = SecurityContext();
          context.setTrustedCertificates(_config.customCACertificatePath!);
        } else if (_config.customCACertificateBytes != null) {
          context = SecurityContext();
          context.setTrustedCertificatesBytes(
            _config.customCACertificateBytes!,
          );
        }

        // Determine certificate validation callback
        bool Function(X509Certificate)? badCertCallback;
        if (_config.certificateValidator != null) {
          badCertCallback = _config.certificateValidator;
        } else if (_config.allowSelfSignedCertificates) {
          badCertCallback = (certificate) => true;
        }

        // Create secure socket
        socket = await SecureSocket.connect(
          _config.host,
          _config.port,
          timeout: _config.connectionTimeout,
          context: context,
          onBadCertificate: badCertCallback,
        );
      } else {
        // Create regular socket
        socket = await Socket.connect(
          _config.host,
          _config.port,
          timeout: _config.connectionTimeout,
        );
      }

      // Configure socket
      socket.setOption(SocketOption.tcpNoDelay, true);

      return socket;
    } on SocketException catch (e) {
      throw ServiceUnavailableException(
        'Failed to connect to ${_config.host}:${_config.port}: ${e.message}',
        e,
      );
    } on TimeoutException catch (e) {
      throw ConnectionTimeoutException(
        'Connection to ${_config.host}:${_config.port} timed out',
        _config.connectionTimeout,
        e,
      );
    } on HandshakeException catch (e) {
      throw SecurityException(
        'SSL/TLS handshake failed for ${_config.host}:${_config.port}: ${e.message}',
        e,
      );
    }
  }

  /// Sends data to the server.
  ///
  /// Throws [ConnectionException] if the connection is not ready.
  void send(Uint8List data) {
    if (!isConnected) {
      throw ConnectionException(
        'Cannot send data: connection not ready (state: $_state)',
      );
    }

    try {
      _socket!.add(data);
    } catch (e) {
      throw ConnectionException('Failed to send data: $e', e);
    }
  }

  /// Closes the connection gracefully.
  Future<void> close() async {
    if (_state == BoltSocketState.closed ||
        _state == BoltSocketState.disconnecting) {
      return;
    }

    _state = BoltSocketState.disconnecting;
    await _cleanup();
    _state = BoltSocketState.closed;
  }

  /// Handles incoming data from the socket.
  void _onData(Uint8List data) {
    if (!_dataController.isClosed) {
      _dataController.add(data);
    }
  }

  /// Handles socket errors.
  void _onError(Object error, StackTrace stackTrace) {
    _state = BoltSocketState.failed;

    if (!_dataController.isClosed) {
      ConnectionException exception;

      if (error is SocketException) {
        exception = ConnectionLostException(
          'Connection lost: ${error.message}',
          error,
        );
      } else {
        exception = ConnectionException('Connection error: $error', error);
      }

      _dataController.addError(exception, stackTrace);
    }

    _cleanup();
  }

  /// Handles socket close events.
  void _onDone() {
    if (_state == BoltSocketState.connected) {
      _state = BoltSocketState.closed;
    }
    _cleanup();
  }

  /// Cleans up resources.
  Future<void> _cleanup() async {
    await _socketSubscription?.cancel();
    _socketSubscription = null;

    try {
      await _socket?.close();
    } catch (e) {
      // Ignore errors during cleanup
    }
    _socket = null;

    if (!_dataController.isClosed) {
      await _dataController.close();
    }
  }

  @override
  String toString() {
    return 'BoltSocket{host: ${_config.host}:${_config.port}, state: $_state}';
  }
}
