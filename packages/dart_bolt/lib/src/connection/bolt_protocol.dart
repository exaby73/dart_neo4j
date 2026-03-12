import 'dart:async';
import 'dart:typed_data';

import 'package:dart_bolt/src/connection/bolt_socket.dart';
import 'package:dart_bolt/src/connection/connection_exceptions.dart';
import 'package:dart_bolt/src/messages/bolt_message.dart';
import 'package:dart_packstream/dart_packstream.dart';

/// Handles Bolt protocol operations including handshake, chunking, and message parsing.
class BoltProtocol {
  static const int _magicPreamble = 0x6060B017;
  static const int _maxChunkSize = 0xFFFF;

  /// Supported protocol versions in descending order of preference.
  static const List<BoltVersion> _supportedVersions = [
    BoltVersion(major: 5, minor: 8), // Version 5.8
    BoltVersion(major: 5, minor: 5), // Version 5.5
    BoltVersion(major: 4, minor: 5), // Version 4.5
    BoltVersion(major: 4, minor: 4), // Version 4.4
  ];

  final BoltSocket _socket;
  int? _agreedVersion;

  // For chunk parsing
  ByteData? _partialData;
  final List<int> _currentMessageData = [];

  /// Creates a new Bolt protocol handler.
  BoltProtocol(this._socket);

  /// The agreed protocol version after handshake.
  int? get agreedVersion => _agreedVersion;

  /// Performs the Bolt protocol handshake.
  ///
  /// Returns the agreed protocol version.
  /// Throws [ProtocolException] if version negotiation fails.
  /// Throws [ConnectionTimeoutException] if handshake times out.
  Future<int> performHandshake([List<BoltVersion>? forcedVersions]) async {
    // Create handshake message
    final handshake = ByteData(20);
    handshake.setUint32(0, _magicPreamble, Endian.big);

    final versions = forcedVersions ?? _supportedVersions;

    // Add supported versions
    for (int i = 0; i < 4 && i < versions.length; i++) {
      handshake.setUint32(4 + (i * 4), versions[i].rawVersion, Endian.big);
    }

    // Fill remaining slots with zeros if needed
    for (int i = versions.length; i < 4; i++) {
      handshake.setUint32(4 + (i * 4), 0, Endian.big);
    }

    // Send handshake
    _socket.send(handshake.buffer.asUint8List());

    // Wait for version negotiation response
    final versionCompleter = Completer<int>();
    late StreamSubscription<Uint8List> handshakeSubscription;

    handshakeSubscription = _socket.dataStream.listen((data) {
      if (data.length >= 4) {
        final version = ByteData.view(data.buffer).getUint32(0, Endian.big);
        handshakeSubscription.cancel();
        versionCompleter.complete(version);
      }
    });

    final timeout = const Duration(seconds: 10);
    final version = _agreedVersion = await versionCompleter.future.timeout(
      timeout,
      onTimeout: () => throw ConnectionTimeoutException(
        'Handshake timeout: server did not respond to version negotiation',
        timeout,
      ),
    );

    if (version == 0) {
      throw ProtocolException(
        'Server does not support any of the requested protocol versions',
        version,
      );
    }

    if (!versions.contains(BoltVersion.raw(version))) {
      throw ProtocolException(
        'Server negotiated an unexpected protocol version',
        version,
      );
    }

    return version;
  }

  /// Sends a Bolt message by chunking it according to the protocol.
  void sendMessage(BoltMessage message) {
    final messageData = message.toByteData().buffer.asUint8List();
    final chunkedData = chunkMessage(messageData);
    _socket.send(chunkedData);
  }

  /// Chunks a message according to the Bolt protocol specification.
  ///
  /// Messages are split into chunks with 2-byte size prefixes.
  /// Each chunk is prefixed with its size (big-endian uint16).
  /// The message is terminated with a zero-length chunk (0x00 0x00).
  static Uint8List chunkMessage(Uint8List messageData) {
    final chunks = <Uint8List>[];

    int offset = 0;
    while (offset < messageData.length) {
      final int chunkSize = (messageData.length - offset).clamp(
        0,
        _maxChunkSize,
      );
      final chunk = Uint8List(2 + chunkSize);

      // Write chunk size (big-endian uint16)
      chunk[0] = (chunkSize >> 8) & 0xFF;
      chunk[1] = chunkSize & 0xFF;

      // Write chunk data
      chunk.setRange(2, 2 + chunkSize, messageData, offset);
      chunks.add(chunk);

      offset += chunkSize;
    }

    // Add terminating chunk (size 0)
    chunks.add(Uint8List.fromList([0x00, 0x00]));

    // Combine all chunks
    final totalLength = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    final result = Uint8List(totalLength);
    int resultOffset = 0;
    for (final chunk in chunks) {
      result.setRange(resultOffset, resultOffset + chunk.length, chunk);
      resultOffset += chunk.length;
    }

    return result;
  }

  /// Processes incoming data and extracts complete messages.
  ///
  /// Returns a list of parsed Bolt messages.
  /// Handles partial data across multiple calls.
  List<BoltMessage> parseData(Uint8List data) {
    final messages = <BoltMessage>[];

    // Combine with any partial data from previous reads
    if (_partialData != null) {
      final combined = Uint8List(_partialData!.lengthInBytes + data.length);
      combined.setRange(
        0,
        _partialData!.lengthInBytes,
        _partialData!.buffer.asUint8List(),
      );
      combined.setRange(_partialData!.lengthInBytes, combined.length, data);
      _partialData = ByteData.view(combined.buffer);
    } else {
      _partialData = ByteData.view(data.buffer);
    }

    // Process chunks
    int offset = 0;
    while (offset + 2 <= _partialData!.lengthInBytes) {
      // Read chunk size (big-endian uint16)
      final chunkSize = _partialData!.getUint16(offset, Endian.big);
      offset += 2;

      if (chunkSize == 0) {
        // End of message - parse the accumulated chunk data
        if (_currentMessageData.isNotEmpty) {
          try {
            final messageData = ByteData.view(
              Uint8List.fromList(_currentMessageData).buffer,
            );
            final message = PsDataType.fromPackStreamBytes(messageData);

            if (message is BoltMessage) {
              messages.add(message);
            }
          } catch (e) {
            throw ProtocolException('Failed to parse message: $e');
          }
          _currentMessageData.clear();
        }
        continue;
      }

      // Check if we have enough data for the chunk
      if (offset + chunkSize > _partialData!.lengthInBytes) {
        // Not enough data - wait for more
        offset -= 2; // Back up to before the chunk size
        break;
      }

      // Read chunk data
      final chunkData = Uint8List(chunkSize);
      for (int i = 0; i < chunkSize; i++) {
        chunkData[i] = _partialData!.getUint8(offset + i);
      }
      _currentMessageData.addAll(chunkData);
      offset += chunkSize;
    }

    // Keep any remaining partial data
    if (offset < _partialData!.lengthInBytes) {
      final remaining = Uint8List(_partialData!.lengthInBytes - offset);
      for (int i = 0; i < remaining.length; i++) {
        remaining[i] = _partialData!.getUint8(offset + i);
      }
      _partialData = ByteData.view(remaining.buffer);
    } else {
      _partialData = null;
    }

    return messages;
  }

  /// Resets the parser state, clearing any partial data.
  void reset() {
    _partialData = null;
    _currentMessageData.clear();
  }
}

/// Bolt version based on big-endian representation
extension type const BoltVersion.raw(int rawVersion) {
  const BoltVersion({required int major, required int minor})
    : this.raw((minor << 8) | major);

  int get major => rawVersion & 0xFF;
  int get minor => (rawVersion & 0xFF00) >> 8;

  bool operator <(BoltVersion other) =>
      (major < other.major) || (major == other.major && minor < other.minor);

  bool operator <=(BoltVersion other) =>
      (major < other.major) || (major == other.major && minor <= other.minor);

  bool operator >(BoltVersion other) =>
      (major > other.major) || (major == other.major && minor > other.minor);

  bool operator >=(BoltVersion other) =>
      (major > other.major) || (major == other.major && minor >= other.minor);

  static const v5_1 = BoltVersion(major: 5, minor: 1);
}
