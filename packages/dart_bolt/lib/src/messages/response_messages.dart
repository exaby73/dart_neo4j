import 'package:dart_packstream/dart_packstream.dart';
import 'bolt_message.dart';

/// SUCCESS message - indicates successful completion of a request.
/// Signature: 0x70
class BoltSuccessMessage extends BoltMessage {
  /// Creates a SUCCESS message.
  ///
  /// [metadata] - metadata about the successful operation
  BoltSuccessMessage([PsDictionary? metadata])
    : super(metadata != null ? 1 : 0, 0x70, metadata != null ? [metadata] : []);

  /// Creates a SUCCESS message from parsed values.
  factory BoltSuccessMessage.fromValues(List<PsDataType> values) {
    if (values.isNotEmpty && values.length != 1) {
      throw ArgumentError(
        'SUCCESS message must have 0 or 1 field, got ${values.length}',
      );
    }

    final metadata = values.isNotEmpty ? values[0] as PsDictionary : null;
    return BoltSuccessMessage(metadata);
  }

  /// Metadata about the successful operation (may be null).
  PsDictionary? get metadata =>
      values.isNotEmpty ? values[0] as PsDictionary : null;

  @override
  bool get isRequest => false;

  @override
  bool get isSummary => true;

  @override
  bool get isDetail => false;
}

/// FAILURE message - indicates that a request failed.
/// Signature: 0x7F
class BoltFailureMessage extends BoltMessage {
  /// Creates a FAILURE message.
  ///
  /// [metadata] - metadata describing the failure (code, message, etc.)
  BoltFailureMessage(PsDictionary metadata) : super(1, 0x7F, [metadata]);

  /// Creates a FAILURE message from parsed values.
  factory BoltFailureMessage.fromValues(List<PsDataType> values) {
    if (values.length != 1) {
      throw ArgumentError(
        'FAILURE message must have 1 field, got ${values.length}',
      );
    }
    return BoltFailureMessage(values[0] as PsDictionary);
  }

  /// Metadata describing the failure.
  PsDictionary get metadata => values[0] as PsDictionary;

  @override
  bool get isRequest => false;

  @override
  bool get isSummary => true;

  @override
  bool get isDetail => false;
}

/// IGNORED message - indicates that a request was ignored.
/// Signature: 0x7E
class BoltIgnoredMessage extends BoltMessage {
  /// Creates an IGNORED message.
  BoltIgnoredMessage() : super(0, 0x7E, []);

  /// Creates an IGNORED message from parsed values.
  factory BoltIgnoredMessage.fromValues(List<PsDataType> values) {
    if (values.isNotEmpty) {
      throw ArgumentError(
        'IGNORED message must have 0 fields, got ${values.length}',
      );
    }
    return BoltIgnoredMessage();
  }

  @override
  bool get isRequest => false;

  @override
  bool get isSummary => true;

  @override
  bool get isDetail => false;
}

/// RECORD message - carries a sequence of values corresponding to a single entry in a result.
/// Signature: 0x71
class BoltRecordMessage extends BoltMessage {
  /// Creates a RECORD message.
  ///
  /// [data] - list of values for this record
  BoltRecordMessage(PsList data) : super(1, 0x71, [data]);

  /// Creates a RECORD message from parsed values.
  factory BoltRecordMessage.fromValues(List<PsDataType> values) {
    if (values.length != 1) {
      throw ArgumentError(
        'RECORD message must have 1 field, got ${values.length}',
      );
    }
    return BoltRecordMessage(values[0] as PsList);
  }

  /// The data values for this record.
  PsList get data => values[0] as PsList;

  @override
  bool get isRequest => false;

  @override
  bool get isSummary => false;

  @override
  bool get isDetail => true;
}
