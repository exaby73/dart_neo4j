import 'dart:typed_data';

import 'package:dart_packstream/src/ps_data_type.dart';
import 'package:test/test.dart';

void main() {
  group('PsTinyInt', () {
    // Valid values: 0x00 to 0x7F (decimal 0 to 127) and 0xF0 to 0xFF (decimal -16 to -1)
    test('creates valid tiny int within range', () {
      // For negative values, we need to use unsigned integers in the test
      final negSixteen = ByteData(1)..setUint8(0, 0xF0);
      expect(
        () => PsTinyInt.fromPackStreamBytes(negSixteen),
        returnsNormally,
      ); // -16 as signed

      final zero = ByteData(1)..setUint8(0, 0);
      expect(() => PsTinyInt.fromPackStreamBytes(zero), returnsNormally);

      final oneTwentySeven = ByteData(1)..setUint8(0, 0x7F);
      expect(
        () => PsTinyInt.fromPackStreamBytes(oneTwentySeven),
        returnsNormally,
      ); // 127 as signed
    });

    test('throws ArgumentError for values outside range', () {
      final belowRange = ByteData(1)..setUint8(0, 0xEF);
      expect(
        () => PsTinyInt.fromPackStreamBytes(belowRange),
        throwsArgumentError,
      ); // below 0xF0

      final aboveRange = ByteData(1)..setUint8(0, 0x80);
      expect(
        () => PsTinyInt.fromPackStreamBytes(aboveRange),
        throwsArgumentError,
      ); // above 0x7F
    });

    test('converts to bytes correctly', () {
      final tinyInt = PsTinyInt(0); // Value of 0 is in the valid range
      final bytes = tinyInt.toByteData();
      expect(bytes.buffer.asUint8List(), [0]);
      expect(bytes.lengthInBytes, 1);
    });

    test('value getter correctly transforms internal representation', () {
      // Test positive values (should remain unchanged)
      final positiveInt = PsTinyInt(0x42); // Internal value 0x42 (66)
      expect(positiveInt.value, 0x42); // Should be 66

      // Test boundary positive values
      final zero = PsTinyInt(0x00);
      expect(zero.value, 0);

      final max = PsTinyInt(0x7F);
      expect(max.value, 127);

      // Test negative values (should be transformed)
      final negativeInt = PsTinyInt(0xF5); // Internal value 0xF5 (245)
      expect(negativeInt.value, -11); // Should be -11 (0xF5 - 0x100)

      // Test boundary negative values
      final minNeg = PsTinyInt(0xF0);
      expect(minNeg.value, -16);

      final maxNeg = PsTinyInt(0xFF);
      expect(maxNeg.value, -1);
    });

    test('dartValue returns the correct Dart native int value', () {
      // Test positive values
      final positiveInt = PsTinyInt(0x42); // 66
      expect(positiveInt.dartValue, 66);
      expect(positiveInt.dartValue, isA<int>());
      expect(positiveInt.dartValue, equals(positiveInt.value));

      // Test negative values
      final negativeInt = PsTinyInt(0xF5); // -11
      expect(negativeInt.dartValue, -11);
      expect(negativeInt.dartValue, isA<int>());
      expect(negativeInt.dartValue, equals(negativeInt.value));

      // Test boundary values
      final testValues = [
        PsTinyInt(0x00), // 0
        PsTinyInt(0x7F), // 127
        PsTinyInt(0xF0), // -16
        PsTinyInt(0xFF), // -1
      ];

      for (final tinyInt in testValues) {
        expect(tinyInt.dartValue, equals(tinyInt.value));
      }
    });

    test('throws ArgumentError for empty ByteData', () {
      expect(
        () => PsTinyInt.fromPackStreamBytes(ByteData(0)),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Invalid number of bytes for TinyInt: 0',
          ),
        ),
      );
    });

    test('throws ArgumentError for ByteData with too many bytes', () {
      final tooManyBytes = ByteData(2)
        ..setUint8(0, 0x00)
        ..setUint8(1, 0x00);
      expect(
        () => PsTinyInt.fromPackStreamBytes(tooManyBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Invalid number of bytes for TinyInt: 2',
          ),
        ),
      );
    });

    test('fromPackStreamBytes correctly parses positive values', () {
      final data = ByteData(1)..setUint8(0, 0x42); // 66 in decimal
      final tinyInt = PsTinyInt.fromPackStreamBytes(data);
      expect(tinyInt.value, 66);
    });

    test('fromPackStreamBytes correctly parses negative values', () {
      final data = ByteData(1)
        ..setUint8(0, 0xFE); // -2 in TinyInt representation
      final tinyInt = PsTinyInt.fromPackStreamBytes(data);
      expect(tinyInt.value, -2);
    });

    test('fromPackStreamBytes handles boundary values correctly', () {
      // -16 (lower bound for negative values)
      final lowerBound = ByteData(1)..setUint8(0, 0xF0);
      final lowerTinyInt = PsTinyInt.fromPackStreamBytes(lowerBound);
      expect(lowerTinyInt.value, -16);

      // -1 (upper bound for negative values)
      final upperNegBound = ByteData(1)..setUint8(0, 0xFF);
      final upperNegTinyInt = PsTinyInt.fromPackStreamBytes(upperNegBound);
      expect(upperNegTinyInt.value, -1);

      // 0 (lower bound for positive values)
      final lowerPosBound = ByteData(1)..setUint8(0, 0x00);
      final lowerPosTinyInt = PsTinyInt.fromPackStreamBytes(lowerPosBound);
      expect(lowerPosTinyInt.value, 0);

      // 127 (upper bound for positive values)
      final upperPosBound = ByteData(1)..setUint8(0, 0x7F);
      final upperPosTinyInt = PsTinyInt.fromPackStreamBytes(upperPosBound);
      expect(upperPosTinyInt.value, 127);
    });
  });
}
