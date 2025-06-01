import 'dart:typed_data';

import 'package:dart_packstream/src/ps_data_type.dart';
import 'package:test/test.dart';

void main() {
  group('PsFloat', () {
    test('creates float values correctly', () {
      const value = 1.23;
      final float = PsFloat(value);
      expect(float.value, value);
    });

    test('has correct marker', () {
      final float = PsFloat(1.0);
      expect(float.marker, 0xC1);
    });

    test('dartValue returns the correct Dart native double value', () {
      final testValues = [
        0.0,
        1.23,
        -3.14159,
        double.infinity,
        double.negativeInfinity,
        double.maxFinite,
        double.minPositive,
      ];

      for (final value in testValues) {
        final psFloat = PsFloat(value);
        expect(psFloat.dartValue, value);
        expect(psFloat.dartValue, isA<double>());
        expect(psFloat.dartValue, equals(psFloat.value));
      }

      // Special handling for NaN since equals doesn't work with NaN
      final nanFloat = PsFloat(double.nan);
      expect(nanFloat.dartValue.isNaN, isTrue);
      expect(nanFloat.dartValue, isA<double>());
    });

    test('converts to bytes correctly', () {
      final float = PsFloat(1.23);
      final bytes = float.toBytes();
      expect(bytes.length, 9);
      expect(bytes[0], 0xC1);

      // Create a ByteData to verify the double value
      final byteData = ByteData.view(
        Uint8List.fromList(bytes.sublist(1)).buffer,
      );
      expect(byteData.getFloat64(0, Endian.big), 1.23);
    });

    test('parses bytes correctly', () {
      // Create test bytes for value 1.23
      final byteData = ByteData(9);
      byteData.setUint8(0, 0xC1);
      byteData.setFloat64(1, 1.23, Endian.big);

      final float = PsDataType.fromPackStreamBytes(byteData) as PsFloat;
      expect(float.value, 1.23);
    });

    test('fromPackStreamBytes throws on empty bytes', () {
      final emptyBytes = ByteData(0);
      expect(
        () => PsFloat.fromPackStreamBytes(emptyBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Bytes must not be empty',
          ),
        ),
      );
    });

    test('fromPackStreamBytes throws on invalid marker', () {
      final invalidBytes = ByteData(9);
      invalidBytes.setUint8(0, 0xC2); // Boolean marker instead of Float

      expect(
        () => PsFloat.fromPackStreamBytes(invalidBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Invalid marker byte for Float: 0xc2',
          ),
        ),
      );
    });

    test('handles special values correctly', () {
      // Test special values like Infinity, NaN
      expect(PsFloat(double.infinity).value, double.infinity);
      expect(PsFloat(double.negativeInfinity).value, double.negativeInfinity);
      expect(PsFloat(0.0).value, 0.0);

      final nanFloat = PsFloat(double.nan);
      expect(nanFloat.value.isNaN, true);
    });
  });
}
