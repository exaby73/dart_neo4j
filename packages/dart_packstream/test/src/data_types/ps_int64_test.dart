import 'dart:typed_data';

import 'package:dart_packstream/src/ps_data_type.dart';
import 'package:test/test.dart';

void main() {
  group('PsInt64', () {
    test('creates valid int64 within range', () {
      expect(
        () => PsInt64(-9223372036854775808),
        returnsNormally,
      ); // Min int64 value
      expect(() => PsInt64(0), returnsNormally);
      expect(
        () => PsInt64(9223372036854775807),
        returnsNormally,
      ); // Max int64 value
    });

    test('converts to bytes correctly', () {
      final int64 = PsInt64(0);
      final bytes = int64.toBytes();
      expect(bytes, [
        0xCB,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ]); // Marker byte + 8 bytes of zeros
      expect(bytes.length, 9);
    });

    test('handles edge case values correctly', () {
      // Minimum value (-9223372036854775808)
      final minValue = PsInt64(-9223372036854775808);
      expect(minValue.toBytes(), [
        0xCB,
        0x80,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
      ]);

      // Maximum value (9223372036854775807)
      final maxValue = PsInt64(9223372036854775807);
      expect(maxValue.toBytes(), [
        0xCB,
        0x7F,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
      ]);

      // Near minimum (-9223372036854775807)
      final nearMin = PsInt64(-9223372036854775807);
      expect(nearMin.toBytes(), [
        0xCB,
        0x80,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x01,
      ]);

      // Near maximum (9223372036854775806)
      final nearMax = PsInt64(9223372036854775806);
      expect(nearMax.toBytes(), [
        0xCB,
        0x7F,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFE,
      ]);
    });

    test('boundary values', () {
      // -1
      final negOne = PsInt64(-1);
      expect(negOne.toBytes(), [
        0xCB,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
      ]);

      // 1
      final posOne = PsInt64(1);
      expect(posOne.toBytes(), [
        0xCB,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x01,
      ]);

      // -2147483649 (boundary where int32 is no longer sufficient)
      final negBoundary = PsInt64(-2147483649);
      expect(negBoundary.toBytes(), [
        0xCB,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0x7F,
        0xFF,
        0xFF,
        0xFF,
      ]);

      // 2147483648 (boundary where int32 is no longer sufficient)
      final posBoundary = PsInt64(2147483648);
      expect(posBoundary.toBytes(), [
        0xCB,
        0x00,
        0x00,
        0x00,
        0x00,
        0x80,
        0x00,
        0x00,
        0x00,
      ]);

      // 281474976710656 (2^48, boundary where 3rd byte becomes significant)
      final largeBoundary = PsInt64(281474976710656);
      expect(largeBoundary.toBytes(), [
        0xCB,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
      ]);
    });

    test('dartValue returns the correct Dart native int value', () {
      final testValues = [
        -9223372036854775808, // minimum value
        -2147483649, // just outside int32 range
        -42,
        -1,
        0,
        1,
        42,
        2147483648, // just outside int32 range
        281474976710656, // 2^48
        9223372036854775807, // maximum value
      ];

      for (final value in testValues) {
        final psInt64 = PsInt64(value);
        expect(psInt64.dartValue, value);
        expect(psInt64.dartValue, isA<int>());
        expect(psInt64.dartValue, equals(psInt64.value));
      }
    });

    test('fromPackStreamBytes throws on empty bytes', () {
      final emptyBytes = ByteData(0);
      expect(
        () => PsInt64.fromPackStreamBytes(emptyBytes),
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
      final invalidBytes = ByteData(9);
      invalidBytes.setUint8(0, 0xCA); // Int32 marker instead of Int64
      invalidBytes.setInt64(1, 42, Endian.big);

      expect(
        () => PsInt64.fromPackStreamBytes(invalidBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Invalid marker byte: 0xca',
          ),
        ),
      );
    });

    test('fromPackStreamBytes throws on insufficient bytes', () {
      // Only 5 bytes (marker + 4 bytes), need 9 bytes total
      final insufficientBytes = ByteData(5);
      insufficientBytes.setUint8(
        0,
        0xCB,
      ); // Correct marker but not enough value bytes

      expect(
        () => PsInt64.fromPackStreamBytes(insufficientBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Not enough bytes for Int64',
          ),
        ),
      );
    });

    test('fromPackStreamBytes parses values correctly', () {
      // Test with value 42
      final positiveBytes = ByteData(9);
      positiveBytes.setUint8(0, 0xCB);
      positiveBytes.setInt64(1, 42, Endian.big);

      final positive = PsInt64.fromPackStreamBytes(positiveBytes);
      expect(positive.value, 42);

      // Test with negative value -42
      final negativeBytes = ByteData(9);
      negativeBytes.setUint8(0, 0xCB);
      negativeBytes.setInt64(1, -42, Endian.big);

      final negative = PsInt64.fromPackStreamBytes(negativeBytes);
      expect(negative.value, -42);

      // Test with large positive value
      final largePositiveBytes = ByteData(9);
      largePositiveBytes.setUint8(0, 0xCB);
      largePositiveBytes.setInt64(
        1,
        9223372036854775807,
        Endian.big,
      ); // Max int64

      final largePositive = PsInt64.fromPackStreamBytes(largePositiveBytes);
      expect(largePositive.value, 9223372036854775807);

      // Test with large negative value
      final largeNegativeBytes = ByteData(9);
      largeNegativeBytes.setUint8(0, 0xCB);
      largeNegativeBytes.setInt64(
        1,
        -9223372036854775808,
        Endian.big,
      ); // Min int64

      final largeNegative = PsInt64.fromPackStreamBytes(largeNegativeBytes);
      expect(largeNegative.value, -9223372036854775808);
    });
  });
}
