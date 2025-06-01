import 'package:dart_packstream/dart_packstream.dart';

/// Base class for all Bolt protocol messages.
///
/// Bolt messages are implemented as PackStream structures with specific
/// signatures (tag bytes) that define the message type. Each message can
/// be serialized to ByteData for transmission over a socket connection.
abstract class BoltMessage extends PsStructure {
  /// Creates a new Bolt message.
  ///
  /// [numberOfFields] - the number of fields in this message
  /// [signature] - the message signature (tag byte) that identifies the message type
  /// [values] - the field values for this message
  BoltMessage(super.numberOfFields, super.signature, super.values);

  /// The message signature (tag byte) that identifies the message type.
  int get signature => tagByte;

  /// Returns true if this is a request message (sent from client to server).
  bool get isRequest;

  /// Returns true if this is a summary message (sent from server to client).
  bool get isSummary;

  /// Returns true if this is a detail message (sent from server to client).
  bool get isDetail;
}
