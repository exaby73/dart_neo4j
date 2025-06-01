import 'dart:typed_data';
import 'package:dart_packstream/src/ps_data_type.dart';
import 'package:test/test.dart';

void main() {
  group('PsString', () {
    test('creates string values correctly', () {
      const value = 'Hello, World!';
      final psString = PsString(value);
      expect(psString.value, value);
    });

    test('handles empty string', () {
      const value = '';
      final psString = PsString(value);
      expect(psString.value, value);
    });

    test('handles UTF-8 characters correctly', () {
      const value = 'Größenmaßstäbe';
      final psString = PsString(value);
      expect(psString.value, value);
    });

    test('handles emojis and special characters', () {
      const value = '😊 👍 🎉 こんにちは 你好';
      final psString = PsString(value);
      expect(psString.value, value);
    });

    test('dartValue returns the correct Dart native string value', () {
      const testCases = [
        '',
        'Hello, World!',
        'Größenmaßstäbe',
        '😊 👍 🎉 こんにちは 你好',
      ];

      for (final value in testCases) {
        final psString = PsString(value);
        expect(psString.dartValue, value);
        expect(psString.dartValue, isA<String>());
        expect(psString.dartValue, equals(psString.value));
      }
    });

    test('converts tiny string to bytes correctly', () {
      const value = 'abc';
      final psString = PsString(value);
      final bytes = psString.toBytes();

      // Expected: marker 0x83 (size 3) followed by UTF-8 bytes for 'abc'
      expect(bytes.length, 4);
      expect(bytes, containsAllInOrder([0x83, 0x61, 0x62, 0x63]));
    });

    test('converts empty string to bytes correctly', () {
      const value = '';
      final psString = PsString(value);
      final bytes = psString.toBytes();

      // Expected: marker 0x80 (size 0) with no data
      expect(bytes.length, 1);
      expect(bytes, containsAllInOrder([0x80]));
    });

    test('converts string with 8-bit size to bytes correctly', () {
      // Create a string that's longer than 15 bytes but shorter than 256 bytes
      final value = 'a' * 20;
      final psString = PsString(value);
      final bytes = psString.toBytes();

      // Expected: marker 0xD0 followed by 8-bit size (20) followed by UTF-8 bytes
      expect(bytes.length, 22); // 1 + 1 + 20

      final expectedBytes = [0xD0, 20];
      for (var i = 0; i < 20; i++) {
        expectedBytes.add(0x61); // 'a'
      }
      expect(bytes, containsAllInOrder(expectedBytes));
    });

    test('parses tiny string from bytes correctly', () {
      final data = ByteData(4);
      data.setUint8(0, 0x83); // Size 3
      data.setUint8(1, 0x61); // 'a'
      data.setUint8(2, 0x62); // 'b'
      data.setUint8(3, 0x63); // 'c'

      final psString = PsString.fromPackStreamBytes(data);
      expect(psString.value, 'abc');
    });

    test('parses empty string from bytes correctly', () {
      final data = ByteData(1);
      data.setUint8(0, 0x80); // Size 0

      final psString = PsString.fromPackStreamBytes(data);
      expect(psString.value, '');
    });

    test('parses string with 8-bit size from bytes correctly', () {
      // Create a test string with 20 'a' characters
      final size = 20;
      final data = ByteData(2 + size);
      data.setUint8(0, 0xD0); // 8-bit size marker
      data.setUint8(1, size); // Size value

      // Set content bytes
      for (var i = 0; i < size; i++) {
        data.setUint8(2 + i, 0x61); // 'a'
      }

      final psString = PsString.fromPackStreamBytes(data);
      expect(psString.value, 'a' * size);
    });

    test('parses string with 16-bit size from bytes correctly', () {
      final size = 300;
      final data = ByteData(3 + size);
      data.setUint8(0, 0xD1); // 16-bit size marker
      data.setUint16(1, size, Endian.big); // Size value

      // Set content bytes
      for (var i = 0; i < size; i++) {
        data.setUint8(3 + i, 0x61); // 'a'
      }

      final psString = PsString.fromPackStreamBytes(data);
      expect(psString.value, 'a' * size);
    });

    test('throws ArgumentError for invalid marker byte', () {
      final data = ByteData(1);
      data.setUint8(0, 0xC0); // Not a string marker

      expect(() => PsString.fromPackStreamBytes(data), throwsArgumentError);
    });

    test('throws ArgumentError for not enough bytes', () {
      // Tiny string with size 3 but only 2 bytes of data
      final data = ByteData(3);
      data.setUint8(0, 0x83); // Size 3
      data.setUint8(1, 0x61); // 'a'
      data.setUint8(2, 0x62); // 'b'
      // Missing the third byte

      expect(() => PsString.fromPackStreamBytes(data), throwsArgumentError);
    });

    test('appropriate marker is selected based on string length', () {
      // Empty string uses tiny string marker 0x80
      expect(PsString('').marker, 0x80);

      // Small string uses tiny string marker (0x80 + length)
      expect(PsString('a').marker, 0x81);
      expect(PsString('abc').marker, 0x83);
      expect(PsString('a' * 15).marker, 0x8F);

      // String with 16-255 bytes uses 8-bit size marker
      expect(PsString('a' * 16).marker, 0xD0);
      expect(PsString('a' * 255).marker, 0xD0);

      // String with 256-65535 bytes uses 16-bit size marker
      expect(PsString('a' * 256).marker, 0xD1);

      // Test with UTF-8 characters that take more than one byte
      final emoji = '😊'; // Takes 4 bytes in UTF-8
      expect(PsString(emoji).marker, 0x84);
      expect(PsString(emoji * 4).marker, 0xD0); // 16 bytes, should use D0
    });
  });
}
