import 'dart:typed_data';

import 'package:dart_packstream/src/ps_data_type.dart';
import 'package:test/test.dart';

void main() {
  group('PsInt8', () {
    test('creates valid int8 within range', () {
      expect(() => PsInt8(0xF0), returnsNormally); // -16 as signed
      expect(() => PsInt8(0), returnsNormally);
      expect(() => PsTinyInt(0x7F), returnsNormally); // 127 as signed
    });

    test('converts to bytes correctly', () {
      final int8 = PsInt8(0); // Value of 0 is in the valid range
      final bytes = int8.toBytes();
      expect(bytes, [0xC8, 0]);
      expect(bytes.length, 2);
    });

    test('handles edge case values correctly', () {
      // Minimum value (-128)
      final minValue = PsInt8(0x80);
      expect(minValue.toBytes(), [0xC8, 0x80]);

      // Maximum value (127)
      final maxValue = PsInt8(0x7F);
      expect(maxValue.toBytes(), [0xC8, 0x7F]);

      // Near minimum (-127)
      final nearMin = PsInt8(0x81);
      expect(nearMin.toBytes(), [0xC8, 0x81]);

      // Near maximum (126)
      final nearMax = PsInt8(0x7E);
      expect(nearMax.toBytes(), [0xC8, 0x7E]);
    });

    test('boundary between positive and negative', () {
      // -1 (0xFF as uint8)
      final negOne = PsInt8(0xFF);
      expect(negOne.toBytes(), [0xC8, 0xFF]);

      // 1
      final posOne = PsInt8(0x01);
      expect(posOne.toBytes(), [0xC8, 0x01]);
    });

    test('dartValue returns the correct Dart native int value', () {
      final testValues = [
        -128, // minimum value
        -42,
        -1,
        0,
        1,
        42,
        127, // maximum value
      ];

      for (final value in testValues) {
        final psInt8 = PsInt8(value);
        expect(psInt8.dartValue, value);
        expect(psInt8.dartValue, isA<int>());
        expect(psInt8.dartValue, equals(psInt8.value));
      }
    });

    test('fromPackStreamBytes throws on empty bytes', () {
      final emptyBytes = ByteData(0);
      expect(
        () => PsInt8.fromPackStreamBytes(emptyBytes),
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
      final invalidBytes = ByteData(2);
      invalidBytes.setUint8(0, 0xC1); // Float marker instead of Int8
      invalidBytes.setInt8(1, 42);

      expect(
        () => PsInt8.fromPackStreamBytes(invalidBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Invalid marker byte: 0xc1',
          ),
        ),
      );
    });

    test('fromPackStreamBytes throws on insufficient bytes', () {
      final insufficientBytes = ByteData(1);
      insufficientBytes.setUint8(0, 0xC8); // Correct marker but no value byte

      expect(
        () => PsInt8.fromPackStreamBytes(insufficientBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Not enough bytes for Int8',
          ),
        ),
      );
    });

    test('fromPackStreamBytes parses values correctly', () {
      // Test with value 42
      final positiveBytes = ByteData(2);
      positiveBytes.setUint8(0, 0xC8);
      positiveBytes.setInt8(1, 42);

      final positive = PsInt8.fromPackStreamBytes(positiveBytes);
      expect(positive.value, 42);

      // Test with negative value -42
      final negativeBytes = ByteData(2);
      negativeBytes.setUint8(0, 0xC8);
      negativeBytes.setInt8(1, -42);

      final negative = PsInt8.fromPackStreamBytes(negativeBytes);
      expect(negative.value, -42);

      // Test with min value -128
      final minBytes = ByteData(2);
      minBytes.setUint8(0, 0xC8);
      minBytes.setInt8(1, -128);

      final min = PsInt8.fromPackStreamBytes(minBytes);
      expect(min.value, -128);

      // Test with max value 127
      final maxBytes = ByteData(2);
      maxBytes.setUint8(0, 0xC8);
      maxBytes.setInt8(1, 127);

      final max = PsInt8.fromPackStreamBytes(maxBytes);
      expect(max.value, 127);
    });
  });
}
