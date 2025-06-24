/// Represents the state of a socket connection.
enum BoltSocketState {
  /// The connection is not yet established.
  disconnected,

  /// The connection is in the process of being established.
  connecting,

  /// The connection is established and ready for use.
  connected,

  /// The connection is in the process of being closed.
  disconnecting,

  /// The connection has been closed.
  closed,

  /// The connection has failed.
  failed,
}

/// Represents the server-side state according to Bolt protocol.
enum BoltServerState {
  /// Initial state before socket connection.
  disconnected,

  /// After successful handshake, awaiting HELLO message.
  negotiation,

  /// Ready to accept LOGON message.
  authentication,

  /// Can handle RUN and BEGIN requests.
  ready,

  /// Result is available for streaming.
  streaming,

  /// Ready for transaction-related messages.
  txReady,

  /// Transaction result streaming.
  txStreaming,

  /// Temporarily unusable connection state - requires RESET.
  failed,

  /// Waiting for RESET after interrupt signal.
  interrupted,

  /// Permanently closed connection.
  defunct,
}