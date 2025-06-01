import 'package:dart_packstream/dart_packstream.dart';
import 'bolt_message.dart';

/// HELLO message - initializes connection and authentication.
/// Signature: 0x01
class BoltHelloMessage extends BoltMessage {
  /// Creates a HELLO message.
  ///
  /// [extra] - dictionary containing authentication and configuration data
  BoltHelloMessage(PsDictionary extra) : super(1, 0x01, [extra]);

  /// Creates a HELLO message from parsed values.
  factory BoltHelloMessage.fromValues(List<PsDataType> values) {
    if (values.length != 1) {
      throw ArgumentError(
        'HELLO message must have 1 field, got ${values.length}',
      );
    }
    return BoltHelloMessage(values[0] as PsDictionary);
  }

  /// The extra data containing authentication and configuration.
  PsDictionary get extra => values[0] as PsDictionary;

  @override
  bool get isRequest => true;

  @override
  bool get isSummary => false;

  @override
  bool get isDetail => false;
}

/// RUN message - executes a Cypher query.
/// Signature: 0x10
class BoltRunMessage extends BoltMessage {
  /// Creates a RUN message.
  ///
  /// [query] - the Cypher query to execute
  /// [parameters] - parameters for the query
  /// [extra] - additional metadata (bookmarks, transaction config, etc.)
  BoltRunMessage(PsString query, PsDictionary parameters, [PsDictionary? extra])
    : super(
        extra != null ? 3 : 2,
        0x10,
        extra != null ? [query, parameters, extra] : [query, parameters],
      );

  /// Creates a RUN message from parsed values.
  factory BoltRunMessage.fromValues(List<PsDataType> values) {
    if (values.length != 2 && values.length != 3) {
      throw ArgumentError(
        'RUN message must have 2 or 3 fields, got ${values.length}',
      );
    }

    final query = values[0] as PsString;
    final parameters = values[1] as PsDictionary;
    final extra = values.length == 3 ? values[2] as PsDictionary : null;

    return BoltRunMessage(query, parameters, extra);
  }

  /// The Cypher query to execute.
  PsString get query => values[0] as PsString;

  /// The query parameters.
  PsDictionary get parameters => values[1] as PsDictionary;

  /// Additional metadata (may be null for older protocol versions).
  PsDictionary? get extra =>
      values.length == 3 ? values[2] as PsDictionary : null;

  @override
  bool get isRequest => true;

  @override
  bool get isSummary => false;

  @override
  bool get isDetail => false;
}

/// PULL message - fetches records from a result stream.
/// Signature: 0x3F
class BoltPullMessage extends BoltMessage {
  /// Creates a PULL message.
  ///
  /// [extra] - dictionary containing 'n' (number of records) and 'qid' (query ID)
  BoltPullMessage([PsDictionary? extra])
    : super(extra != null ? 1 : 0, 0x3F, extra != null ? [extra] : []);

  /// Creates a PULL message from parsed values.
  factory BoltPullMessage.fromValues(List<PsDataType> values) {
    if (values.isNotEmpty && values.length != 1) {
      throw ArgumentError(
        'PULL message must have 0 or 1 field, got ${values.length}',
      );
    }

    final extra = values.isNotEmpty ? values[0] as PsDictionary : null;
    return BoltPullMessage(extra);
  }

  /// Additional metadata containing 'n' and 'qid' fields (Bolt 4.0+).
  PsDictionary? get extra =>
      values.isNotEmpty ? values[0] as PsDictionary : null;

  @override
  bool get isRequest => true;

  @override
  bool get isSummary => false;

  @override
  bool get isDetail => false;
}

/// DISCARD message - discards records from a result stream.
/// Signature: 0x2F
class BoltDiscardMessage extends BoltMessage {
  /// Creates a DISCARD message.
  ///
  /// [extra] - dictionary containing 'n' (number of records) and 'qid' (query ID)
  BoltDiscardMessage([PsDictionary? extra])
    : super(extra != null ? 1 : 0, 0x2F, extra != null ? [extra] : []);

  /// Creates a DISCARD message from parsed values.
  factory BoltDiscardMessage.fromValues(List<PsDataType> values) {
    if (values.isNotEmpty && values.length != 1) {
      throw ArgumentError(
        'DISCARD message must have 0 or 1 field, got ${values.length}',
      );
    }

    final extra = values.isNotEmpty ? values[0] as PsDictionary : null;
    return BoltDiscardMessage(extra);
  }

  /// Additional metadata containing 'n' and 'qid' fields (Bolt 4.0+).
  PsDictionary? get extra =>
      values.isNotEmpty ? values[0] as PsDictionary : null;

  @override
  bool get isRequest => true;

  @override
  bool get isSummary => false;

  @override
  bool get isDetail => false;
}

/// BEGIN message - begins an explicit transaction.
/// Signature: 0x11
class BoltBeginMessage extends BoltMessage {
  /// Creates a BEGIN message.
  ///
  /// [extra] - transaction metadata (bookmarks, timeout, etc.)
  BoltBeginMessage([PsDictionary? extra])
    : super(extra != null ? 1 : 0, 0x11, extra != null ? [extra] : []);

  /// Creates a BEGIN message from parsed values.
  factory BoltBeginMessage.fromValues(List<PsDataType> values) {
    if (values.isNotEmpty && values.length != 1) {
      throw ArgumentError(
        'BEGIN message must have 0 or 1 field, got ${values.length}',
      );
    }

    final extra = values.isNotEmpty ? values[0] as PsDictionary : null;
    return BoltBeginMessage(extra);
  }

  /// Transaction metadata (may be null for default transaction).
  PsDictionary? get extra =>
      values.isNotEmpty ? values[0] as PsDictionary : null;

  @override
  bool get isRequest => true;

  @override
  bool get isSummary => false;

  @override
  bool get isDetail => false;
}

/// COMMIT message - commits an explicit transaction.
/// Signature: 0x12
class BoltCommitMessage extends BoltMessage {
  /// Creates a COMMIT message.
  BoltCommitMessage() : super(0, 0x12, []);

  /// Creates a COMMIT message from parsed values.
  factory BoltCommitMessage.fromValues(List<PsDataType> values) {
    if (values.isNotEmpty) {
      throw ArgumentError(
        'COMMIT message must have 0 fields, got ${values.length}',
      );
    }
    return BoltCommitMessage();
  }

  @override
  bool get isRequest => true;

  @override
  bool get isSummary => false;

  @override
  bool get isDetail => false;
}

/// ROLLBACK message - rolls back an explicit transaction.
/// Signature: 0x13
class BoltRollbackMessage extends BoltMessage {
  /// Creates a ROLLBACK message.
  BoltRollbackMessage() : super(0, 0x13, []);

  /// Creates a ROLLBACK message from parsed values.
  factory BoltRollbackMessage.fromValues(List<PsDataType> values) {
    if (values.isNotEmpty) {
      throw ArgumentError(
        'ROLLBACK message must have 0 fields, got ${values.length}',
      );
    }
    return BoltRollbackMessage();
  }

  @override
  bool get isRequest => true;

  @override
  bool get isSummary => false;

  @override
  bool get isDetail => false;
}

/// RESET message - resets the connection to initial state.
/// Signature: 0x0F
class BoltResetMessage extends BoltMessage {
  /// Creates a RESET message.
  BoltResetMessage() : super(0, 0x0F, []);

  /// Creates a RESET message from parsed values.
  factory BoltResetMessage.fromValues(List<PsDataType> values) {
    if (values.isNotEmpty) {
      throw ArgumentError(
        'RESET message must have 0 fields, got ${values.length}',
      );
    }
    return BoltResetMessage();
  }

  @override
  bool get isRequest => true;

  @override
  bool get isSummary => false;

  @override
  bool get isDetail => false;
}

/// GOODBYE message - closes the connection gracefully.
/// Signature: 0x02
class BoltGoodbyeMessage extends BoltMessage {
  /// Creates a GOODBYE message.
  BoltGoodbyeMessage() : super(0, 0x02, []);

  /// Creates a GOODBYE message from parsed values.
  factory BoltGoodbyeMessage.fromValues(List<PsDataType> values) {
    if (values.isNotEmpty) {
      throw ArgumentError(
        'GOODBYE message must have 0 fields, got ${values.length}',
      );
    }
    return BoltGoodbyeMessage();
  }

  @override
  bool get isRequest => true;

  @override
  bool get isSummary => false;

  @override
  bool get isDetail => false;
}
