import 'dart:typed_data';

import 'package:dart_packstream/src/ps_data_type.dart';
import 'package:test/test.dart';

void main() {
  group('PsNull', () {
    test('converts to bytes correctly', () {
      const nullValue = PsNull();
      expect(nullValue.toBytes(), [0xC0]);
    });

    test('has correct marker', () {
      const nullValue = PsNull();
      expect(nullValue.marker, 0xC0);
    });

    test('dartValue returns null', () {
      const nullValue = PsNull();
      expect(nullValue.dartValue, isNull);
      expect(nullValue.dartValue, equals(nullValue.value));
    });

    test('fromPackStreamBytes throws on invalid number of bytes', () {
      // Two bytes is too many for null
      final tooManyBytes = ByteData(2);
      tooManyBytes.setUint8(0, 0xC0);
      tooManyBytes.setUint8(1, 0);

      expect(
        () => PsNull.fromPackStreamBytes(tooManyBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Invalid number of bytes for Null: 2',
          ),
        ),
      );

      // Zero bytes is too few
      final tooFewBytes = ByteData(0);

      expect(
        () => PsNull.fromPackStreamBytes(tooFewBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Invalid number of bytes for Null: 0',
          ),
        ),
      );
    });

    test('fromPackStreamBytes throws on invalid marker', () {
      final invalidBytes = ByteData(1);
      invalidBytes.setUint8(0, 0xC1); // Float marker instead of Null

      expect(
        () => PsNull.fromPackStreamBytes(invalidBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Invalid marker for Null: 193',
          ),
        ),
      );
    });

    test('fromPackStreamBytes parses null correctly', () {
      final correctBytes = ByteData(1);
      correctBytes.setUint8(0, 0xC0);

      final nullValue = PsNull.fromPackStreamBytes(correctBytes);
      expect(nullValue, isA<PsNull>());
      expect(nullValue.value, isNull);
    });
  });
}
