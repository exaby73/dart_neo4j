import 'dart:typed_data';

import 'package:dart_packstream/src/ps_data_type.dart';
import 'package:test/test.dart';

void main() {
  group('PsInt', () {
    group('compact()', () {
      test('returns PsTinyInt for values between -16 and 127', () {
        // Test positive tiny ints (0 to 127)
        expect(PsInt.compact(0), isA<PsTinyInt>());
        expect(PsInt.compact(1), isA<PsTinyInt>());
        expect(PsInt.compact(127), isA<PsTinyInt>());

        // Test negative tiny ints (-16 to -1)
        expect(PsInt.compact(-1), isA<PsTinyInt>());
        expect(PsInt.compact(-16), isA<PsTinyInt>());
      });

      test('returns PsInt8 for values between -128 and -17', () {
        expect(PsInt.compact(-17), isA<PsInt8>());
        expect(PsInt.compact(-128), isA<PsInt8>());
        expect(PsInt.compact(-100), isA<PsInt8>());
      });

      test(
        'returns PsInt16 for values between -32768 and -129 or 128 to 32767',
        () {
          // Test negative range
          expect(PsInt.compact(-129), isA<PsInt16>());
          expect(PsInt.compact(-32768), isA<PsInt16>());
          expect(PsInt.compact(-1000), isA<PsInt16>());

          // Test positive range
          expect(PsInt.compact(128), isA<PsInt16>());
          expect(PsInt.compact(32767), isA<PsInt16>());
          expect(PsInt.compact(1000), isA<PsInt16>());
        },
      );

      test(
        'returns PsInt32 for values between -2147483648 and -32769 or 32768 to 2147483647',
        () {
          // Test negative range
          expect(PsInt.compact(-32769), isA<PsInt32>());
          expect(PsInt.compact(-2147483648), isA<PsInt32>());
          expect(PsInt.compact(-1000000), isA<PsInt32>());

          // Test positive range
          expect(PsInt.compact(32768), isA<PsInt32>());
          expect(PsInt.compact(2147483647), isA<PsInt32>());
          expect(PsInt.compact(1000000), isA<PsInt32>());
        },
      );

      test('returns PsInt64 for values outside 32-bit range', () {
        // Values less than -2147483648
        expect(PsInt.compact(-2147483649), isA<PsInt64>());
        expect(
          PsInt.compact(-9223372036854775808),
          isA<PsInt64>(),
        ); // Min int64 value

        // Values greater than 2147483647
        expect(PsInt.compact(2147483648), isA<PsInt64>());
        expect(
          PsInt.compact(9223372036854775807),
          isA<PsInt64>(),
        ); // Max int64 value
      });

      test('preserves actual value in all ranges', () {
        // TinyInt range
        expect(PsInt.compact(0).value, 0);
        expect(PsInt.compact(127).value, 127);
        expect(PsInt.compact(-16).value, -16);

        // Int8 range
        expect(PsInt.compact(-17).value, -17);
        expect(PsInt.compact(-128).value, -128);

        // Int16 range
        expect(PsInt.compact(128).value, 128);
        expect(PsInt.compact(32767).value, 32767);
        expect(PsInt.compact(-129).value, -129);
        expect(PsInt.compact(-32768).value, -32768);

        // Int32 range
        expect(PsInt.compact(32768).value, 32768);
        expect(PsInt.compact(2147483647).value, 2147483647);
        expect(PsInt.compact(-32769).value, -32769);
        expect(PsInt.compact(-2147483648).value, -2147483648);

        // Int64 range
        expect(PsInt.compact(2147483648).value, 2147483648);
        expect(PsInt.compact(-2147483649).value, -2147483649);
      });
    });

    group('compactFromBytes()', () {
      test('extracts value correctly from TINY_INT bytes', () {
        // Positive tiny int (0x00 = 0)
        final posZero = PsInt.compactFromBytes(
          ByteData.view(Uint8List.fromList([0x00]).buffer),
        );
        expect(posZero, isA<PsTinyInt>());
        expect(posZero.value, 0);

        // Positive tiny int (0x7F = 127)
        final posMax = PsInt.compactFromBytes(
          ByteData.view(Uint8List.fromList([0x7F]).buffer),
        );
        expect(posMax, isA<PsTinyInt>());
        expect(posMax.value, 127);

        // Negative tiny int (0xF0 = -16)
        final negMin = PsInt.compactFromBytes(
          ByteData.view(Uint8List.fromList([0xF0]).buffer),
        );
        expect(negMin, isA<PsTinyInt>());
        expect(negMin.value, -16);
      });

      test('extracts value correctly from INT_8 bytes', () {
        // INT_8 marker with value 0x7F (127)
        final int8Max = PsInt.compactFromBytes(
          ByteData.view(Uint8List.fromList([0xC8, 0x7F]).buffer),
        );
        expect(int8Max.value, 127);

        // INT_8 marker with value 0x80 (-128)
        final int8Min = PsInt.compactFromBytes(
          ByteData.view(Uint8List.fromList([0xC8, 0x80]).buffer),
        );
        expect(int8Min.value, -128);

        // INT_8 marker with value 0xEF (-17)
        final int8Neg17 = PsInt.compactFromBytes(
          ByteData.view(Uint8List.fromList([0xC8, 0xEF]).buffer),
        );
        expect(int8Neg17.value, -17);
      });

      test('extracts value correctly from INT_16 bytes', () {
        // INT_16 marker with value 0x0080 (128)
        final int16Min = PsInt.compactFromBytes(
          ByteData.view(Uint8List.fromList([0xC9, 0x00, 0x80]).buffer),
        );
        expect(int16Min.value, 128);

        // INT_16 marker with value 0x7FFF (32767)
        final int16Max = PsInt.compactFromBytes(
          ByteData.view(Uint8List.fromList([0xC9, 0x7F, 0xFF]).buffer),
        );
        expect(int16Max.value, 32767);

        // INT_16 marker with value 0xFF7F (-129)
        final int16Neg129 = PsInt.compactFromBytes(
          ByteData.view(Uint8List.fromList([0xC9, 0xFF, 0x7F]).buffer),
        );
        expect(int16Neg129.value, -129);
      });

      test('extracts value correctly from INT_32 bytes', () {
        // INT_32 marker with value 0x00008000 (32768)
        final int32Min = PsInt.compactFromBytes(
          ByteData.view(
            Uint8List.fromList([0xCA, 0x00, 0x00, 0x80, 0x00]).buffer,
          ),
        );
        expect(int32Min.value, 32768);

        // INT_32 marker with value 0x7FFFFFFF (2147483647)
        final int32Max = PsInt.compactFromBytes(
          ByteData.view(
            Uint8List.fromList([0xCA, 0x7F, 0xFF, 0xFF, 0xFF]).buffer,
          ),
        );
        expect(int32Max.value, 2147483647);
      });

      test('extracts value correctly from INT_64 bytes', () {
        // INT_64 marker with value 0x0000000080000000 (2147483648)
        final bytes = ByteData(9);
        bytes.setUint8(0, 0xCB);
        bytes.setInt64(1, 2147483648, Endian.big);

        final int64Min = PsInt.compactFromBytes(bytes);
        expect(int64Min.value, 2147483648);
      });

      test('throws for invalid marker byte', () {
        expect(
          () => PsInt.compactFromBytes(
            ByteData.view(Uint8List.fromList([0xD0]).buffer),
          ),
          throwsArgumentError,
        );
      });

      test('throws for insufficient bytes', () {
        // INT_8 with no data byte
        expect(
          () => PsInt.compactFromBytes(
            ByteData.view(Uint8List.fromList([0xC8]).buffer),
          ),
          throwsArgumentError,
        );

        // INT_16 with only one data byte
        expect(
          () => PsInt.compactFromBytes(
            ByteData.view(Uint8List.fromList([0xC9, 0x00]).buffer),
          ),
          throwsArgumentError,
        );
      });
    });
  });
}
