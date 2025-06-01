import 'dart:typed_data';

import 'package:dart_packstream/src/ps_data_type.dart';
import 'package:test/test.dart';

void main() {
  group('PsBytes', () {
    test('creates byte arrays with 8-bit size correctly', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final psBytes = PsBytes(bytes);

      expect(psBytes.value, equals(bytes));
      expect(psBytes.marker, equals(0xCC));
    });

    test('creates byte arrays with 16-bit size correctly', () {
      // Create an array with 256 bytes (more than 8-bit can represent)
      final bytes = Uint8List(256);
      for (var i = 0; i < bytes.length; i++) {
        bytes[i] = i % 256;
      }

      final psBytes = PsBytes(bytes);

      expect(psBytes.value, equals(bytes));
      expect(psBytes.marker, equals(0xCD));
    });

    test('dartValue returns the original Uint8List', () {
      // Test with small array
      final smallBytes = Uint8List.fromList([1, 2, 3]);
      final smallPsBytes = PsBytes(smallBytes);

      expect(smallPsBytes.dartValue, equals(smallBytes));
      expect(smallPsBytes.dartValue, isA<Uint8List>());
      expect(smallPsBytes.dartValue, same(smallPsBytes.value));

      // Test with larger array (256 bytes)
      final largeBytes = Uint8List(256);
      for (var i = 0; i < largeBytes.length; i++) {
        largeBytes[i] = i % 256;
      }

      final largePsBytes = PsBytes(largeBytes);
      expect(largePsBytes.dartValue, equals(largeBytes));
      expect(largePsBytes.dartValue, isA<Uint8List>());
      expect(largePsBytes.dartValue, same(largePsBytes.value));

      // Test with empty array
      final emptyBytes = Uint8List(0);
      final emptyPsBytes = PsBytes(emptyBytes);

      expect(emptyPsBytes.dartValue, equals(emptyBytes));
      expect(emptyPsBytes.dartValue, isA<Uint8List>());
      expect(emptyPsBytes.dartValue.length, equals(0));
    });

    test('converts to bytes correctly for 8-bit size', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final psBytes = PsBytes(bytes);
      final encoded = psBytes.toBytes();

      expect(encoded.length, equals(5)); // marker(1) + size(1) + data(3)
      expect(encoded, containsAllInOrder([0xCC, 3, 1, 2, 3]));
    });

    test('converts to bytes correctly for 16-bit size', () {
      // Create an array with 256 bytes (more than 8-bit can represent)
      final bytes = Uint8List(256);
      for (var i = 0; i < bytes.length; i++) {
        bytes[i] = i % 256;
      }

      final psBytes = PsBytes(bytes);
      final encoded = psBytes.toBytes();

      expect(encoded.length, equals(259)); // marker(1) + size(2) + data(256)

      // Check header (marker and size)
      expect(encoded.sublist(0, 3), containsAllInOrder([0xCD, 1, 0]));

      // Check a few values from the data
      expect(encoded.sublist(3, 5), containsAllInOrder([0, 1]));
      expect(encoded[258], equals(255));
    });

    test('parses bytes correctly for 8-bit size', () {
      final rawBytes = Uint8List.fromList([0xCC, 3, 1, 2, 3]);
      final byteData = ByteData.view(rawBytes.buffer);

      final psBytes = PsBytes.fromPackStreamBytes(byteData);

      expect(psBytes.value.length, equals(3));
      expect(psBytes.value, containsAllInOrder([1, 2, 3]));
    });

    test('throws ArgumentError for invalid marker byte', () {
      final rawBytes = Uint8List.fromList([
        0xC0,
        3,
        1,
        2,
        3,
      ]); // Using null marker
      final byteData = ByteData.view(rawBytes.buffer);

      expect(() => PsBytes.fromPackStreamBytes(byteData), throwsArgumentError);
    });

    test('throws ArgumentError for not enough bytes', () {
      // Missing size byte
      final rawBytes1 = Uint8List.fromList([0xCC]);
      final byteData1 = ByteData.view(rawBytes1.buffer);

      expect(() => PsBytes.fromPackStreamBytes(byteData1), throwsArgumentError);

      // Missing data bytes
      final rawBytes2 = Uint8List.fromList([
        0xCC,
        5,
        1,
        2,
      ]); // Declares 5 bytes but only has 2
      final byteData2 = ByteData.view(rawBytes2.buffer);

      expect(() => PsBytes.fromPackStreamBytes(byteData2), throwsArgumentError);
    });
  });
}
