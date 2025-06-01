import 'dart:typed_data';

import 'package:dart_packstream/src/ps_data_type.dart';
import 'package:test/test.dart';

void main() {
  group('PsBoolean', () {
    test('creates boolean values correctly', () {
      final falseBool = PsBoolean(false);
      final trueBool = PsBoolean(true);
      expect(falseBool.value, false);
      expect(trueBool.value, true);
    });

    test('converts to bytes correctly', () {
      final falseBool = PsBoolean(false);
      final trueBool = PsBoolean(true);
      expect(falseBool.toBytes(), [0xC2]);
      expect(trueBool.toBytes(), [0xC3]);
    });

    test('has correct marker', () {
      final falseBool = PsBoolean(false);
      final trueBool = PsBoolean(true);
      expect(falseBool.marker, 0xC2);
      expect(trueBool.marker, 0xC3);
    });

    test('dartValue returns the correct Dart native boolean value', () {
      final falseBool = PsBoolean(false);
      final trueBool = PsBoolean(true);

      expect(falseBool.dartValue, false);
      expect(falseBool.dartValue, isA<bool>());

      expect(trueBool.dartValue, true);
      expect(trueBool.dartValue, isA<bool>());

      // Verify dartValue and value are the same for PsBoolean
      expect(falseBool.dartValue, equals(falseBool.value));
      expect(trueBool.dartValue, equals(trueBool.value));
    });

    test('fromPackStreamBytes throws on empty bytes', () {
      final emptyBytes = ByteData(0);
      expect(
        () => PsBoolean.fromPackStreamBytes(emptyBytes),
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
      final invalidBytes = ByteData(1);
      invalidBytes.setUint8(0, 0xC1); // Float marker instead of Boolean

      expect(
        () => PsBoolean.fromPackStreamBytes(invalidBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Invalid marker byte for Boolean: 0xc1',
          ),
        ),
      );
    });

    test('fromPackStreamBytes parses true and false correctly', () {
      final trueBytes = ByteData(1);
      trueBytes.setUint8(0, 0xC3);

      final falseBytes = ByteData(1);
      falseBytes.setUint8(0, 0xC2);

      expect(PsBoolean.fromPackStreamBytes(trueBytes).value, true);
      expect(PsBoolean.fromPackStreamBytes(falseBytes).value, false);
    });
  });
}
