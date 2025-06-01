import 'dart:typed_data';

import 'package:dart_packstream/src/ps_data_type.dart';
import 'package:test/test.dart';

void main() {
  group('PsInt16', () {
    test('creates valid int16 within range', () {
      expect(() => PsInt16(0xFF00), returnsNormally); // -256 as signed
      expect(() => PsInt16(0), returnsNormally);
      expect(() => PsInt16(0x7FFF), returnsNormally); // 32767 as signed
    });

    test('converts to bytes correctly', () {
      final int16 = PsInt16(0);
      final bytes = int16.toBytes();
      expect(bytes, [0xC9, 0, 0]); // Marker byte + 2 bytes of zeros
      expect(bytes.length, 3);
    });

    test('dartValue returns the correct Dart native int value', () {
      final testValues = [
        -32768, // minimum value
        -1,
        0,
        1,
        32767, // maximum value
      ];

      for (final value in testValues) {
        final psInt16 = PsInt16(value);
        expect(psInt16.dartValue, value);
        expect(psInt16.dartValue, isA<int>());
        expect(psInt16.dartValue, equals(psInt16.value));
      }
    });

    test('handles edge case values correctly', () {
      // Minimum value (-32768)
      final minValue = PsInt16(-32768);
      expect(minValue.toBytes(), [0xC9, 0x80, 0x00]);

      // Maximum value (32767)
      final maxValue = PsInt16(32767);
      expect(maxValue.toBytes(), [0xC9, 0x7F, 0xFF]);

      // Near minimum (-32767)
      final nearMin = PsInt16(-32767);
      expect(nearMin.toBytes(), [0xC9, 0x80, 0x01]);

      // Near maximum (32766)
      final nearMax = PsInt16(32766);
      expect(nearMax.toBytes(), [0xC9, 0x7F, 0xFE]);
    });

    test('boundary between positive and negative', () {
      // -1
      final negOne = PsInt16(-1);
      expect(negOne.toBytes(), [0xC9, 0xFF, 0xFF]);

      // 1
      final posOne = PsInt16(1);
      expect(posOne.toBytes(), [0xC9, 0x00, 0x01]);

      // -256
      final negBoundary = PsInt16(-256);
      expect(negBoundary.toBytes(), [0xC9, 0xFF, 0x00]);

      // 256
      final posBoundary = PsInt16(256);
      expect(posBoundary.toBytes(), [0xC9, 0x01, 0x00]);
    });

    test('fromPackStreamBytes throws on empty bytes', () {
      final emptyBytes = ByteData(0);
      expect(
        () => PsInt16.fromPackStreamBytes(emptyBytes),
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
      final invalidBytes = ByteData(3);
      invalidBytes.setUint8(0, 0xC8); // Int8 marker instead of Int16
      invalidBytes.setInt16(1, 42, Endian.big);

      expect(
        () => PsInt16.fromPackStreamBytes(invalidBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Invalid marker byte: 0xc8',
          ),
        ),
      );
    });

    test('fromPackStreamBytes throws on insufficient bytes', () {
      // Only 2 bytes (marker + 1 byte), need 3 bytes total
      final insufficientBytes = ByteData(2);
      insufficientBytes.setUint8(
        0,
        0xC9,
      ); // Correct marker but not enough value bytes

      expect(
        () => PsInt16.fromPackStreamBytes(insufficientBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Not enough bytes for Int16',
          ),
        ),
      );
    });

    test('fromPackStreamBytes parses values correctly', () {
      // Test with value 42
      final positiveBytes = ByteData(3);
      positiveBytes.setUint8(0, 0xC9);
      positiveBytes.setInt16(1, 42, Endian.big);

      final positive = PsInt16.fromPackStreamBytes(positiveBytes);
      expect(positive.value, 42);

      // Test with negative value -42
      final negativeBytes = ByteData(3);
      negativeBytes.setUint8(0, 0xC9);
      negativeBytes.setInt16(1, -42, Endian.big);

      final negative = PsInt16.fromPackStreamBytes(negativeBytes);
      expect(negative.value, -42);

      // Test with min value -32768
      final minBytes = ByteData(3);
      minBytes.setUint8(0, 0xC9);
      minBytes.setInt16(1, -32768, Endian.big);

      final min = PsInt16.fromPackStreamBytes(minBytes);
      expect(min.value, -32768);

      // Test with max value 32767
      final maxBytes = ByteData(3);
      maxBytes.setUint8(0, 0xC9);
      maxBytes.setInt16(1, 32767, Endian.big);

      final max = PsInt16.fromPackStreamBytes(maxBytes);
      expect(max.value, 32767);
    });
  });
}
