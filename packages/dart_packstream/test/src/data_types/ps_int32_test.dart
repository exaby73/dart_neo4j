import 'dart:typed_data';

import 'package:dart_packstream/src/ps_data_type.dart';
import 'package:test/test.dart';

void main() {
  group('PsInt32', () {
    test('creates valid int32 within range', () {
      expect(() => PsInt32(-2147483648), returnsNormally); // Min int32 value
      expect(() => PsInt32(0), returnsNormally);
      expect(() => PsInt32(2147483647), returnsNormally); // Max int32 value
    });

    test('converts to bytes correctly', () {
      final int32 = PsInt32(0);
      final bytes = int32.toBytes();
      expect(bytes, [0xCA, 0, 0, 0, 0]); // Marker byte + 4 bytes of zeros
      expect(bytes.length, 5);
    });

    test('handles edge case values correctly', () {
      // Minimum value (-2147483648)
      final minValue = PsInt32(-2147483648);
      expect(minValue.toBytes(), [0xCA, 0x80, 0x00, 0x00, 0x00]);

      // Maximum value (2147483647)
      final maxValue = PsInt32(2147483647);
      expect(maxValue.toBytes(), [0xCA, 0x7F, 0xFF, 0xFF, 0xFF]);

      // Near minimum (-2147483647)
      final nearMin = PsInt32(-2147483647);
      expect(nearMin.toBytes(), [0xCA, 0x80, 0x00, 0x00, 0x01]);

      // Near maximum (2147483646)
      final nearMax = PsInt32(2147483646);
      expect(nearMax.toBytes(), [0xCA, 0x7F, 0xFF, 0xFF, 0xFE]);
    });

    test('boundary values', () {
      // -1
      final negOne = PsInt32(-1);
      expect(negOne.toBytes(), [0xCA, 0xFF, 0xFF, 0xFF, 0xFF]);

      // 1
      final posOne = PsInt32(1);
      expect(posOne.toBytes(), [0xCA, 0x00, 0x00, 0x00, 0x01]);

      // -65536 (boundary where 3rd byte becomes significant)
      final negBoundary = PsInt32(-65536);
      expect(negBoundary.toBytes(), [0xCA, 0xFF, 0xFF, 0x00, 0x00]);

      // 65536 (boundary where 3rd byte becomes significant)
      final posBoundary = PsInt32(65536);
      expect(posBoundary.toBytes(), [0xCA, 0x00, 0x01, 0x00, 0x00]);

      // 16777216 (boundary where 4th byte becomes significant)
      final largeBoundary = PsInt32(16777216);
      expect(largeBoundary.toBytes(), [0xCA, 0x01, 0x00, 0x00, 0x00]);
    });

    test('dartValue returns the correct Dart native int value', () {
      final testValues = [
        -2147483648, // minimum value
        -65536,
        -42,
        -1,
        0,
        1,
        42,
        65536,
        16777216,
        2147483647, // maximum value
      ];

      for (final value in testValues) {
        final psInt32 = PsInt32(value);
        expect(psInt32.dartValue, value);
        expect(psInt32.dartValue, isA<int>());
        expect(psInt32.dartValue, equals(psInt32.value));
      }
    });

    test('fromPackStreamBytes throws on empty bytes', () {
      final emptyBytes = ByteData(0);
      expect(
        () => PsInt32.fromPackStreamBytes(emptyBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Invalid marker byte: 0xempty',
          ),
        ),
      );
    });

    test('fromPackStreamBytes throws on invalid marker', () {
      final invalidBytes = ByteData(5);
      invalidBytes.setUint8(0, 0xC9); // Int16 marker instead of Int32
      invalidBytes.setInt32(1, 42, Endian.big);

      expect(
        () => PsInt32.fromPackStreamBytes(invalidBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Invalid marker byte: 0xc9',
          ),
        ),
      );
    });

    test('fromPackStreamBytes throws on insufficient bytes', () {
      // Only 3 bytes (marker + 2 bytes), need 5 bytes total
      final insufficientBytes = ByteData(3);
      insufficientBytes.setUint8(
        0,
        0xCA,
      ); // Correct marker but not enough value bytes

      expect(
        () => PsInt32.fromPackStreamBytes(insufficientBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Not enough bytes for Int32',
          ),
        ),
      );
    });

    test('fromPackStreamBytes parses values correctly', () {
      // Test with value 42
      final positiveBytes = ByteData(5);
      positiveBytes.setUint8(0, 0xCA);
      positiveBytes.setInt32(1, 42, Endian.big);

      final positive = PsInt32.fromPackStreamBytes(positiveBytes);
      expect(positive.value, 42);

      // Test with negative value -42
      final negativeBytes = ByteData(5);
      negativeBytes.setUint8(0, 0xCA);
      negativeBytes.setInt32(1, -42, Endian.big);

      final negative = PsInt32.fromPackStreamBytes(negativeBytes);
      expect(negative.value, -42);

      // Test with min value -2147483648
      final minBytes = ByteData(5);
      minBytes.setUint8(0, 0xCA);
      minBytes.setInt32(1, -2147483648, Endian.big);

      final min = PsInt32.fromPackStreamBytes(minBytes);
      expect(min.value, -2147483648);

      // Test with max value 2147483647
      final maxBytes = ByteData(5);
      maxBytes.setUint8(0, 0xCA);
      maxBytes.setInt32(1, 2147483647, Endian.big);

      final max = PsInt32.fromPackStreamBytes(maxBytes);
      expect(max.value, 2147483647);
    });
  });
}
