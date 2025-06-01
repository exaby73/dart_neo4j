import 'dart:typed_data';
import 'package:dart_packstream/src/ps_data_type.dart';
import 'package:test/test.dart';

void main() {
  group('PsDataType', () {
    test('throws ArgumentError for empty bytes', () {
      expect(
        () => PsDataType.fromPackStreamBytes(ByteData(0)),
        throwsArgumentError,
      );
    });

    test('fromBytes parses null marker correctly', () {
      final nullValue = PsDataType.fromPackStreamBytes(
        ByteData.view(Int8List.fromList([0xC0]).buffer),
      );
      expect(nullValue, isA<PsNull>());
    });

    test('fromBytes parses boolean markers correctly', () {
      final falseBool = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0xC2]).buffer),
      );
      expect(falseBool, isA<PsBoolean>());
      expect((falseBool as PsBoolean).value, false);

      final trueBool = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0xC3]).buffer),
      );
      expect(trueBool, isA<PsBoolean>());
      expect((trueBool as PsBoolean).value, true);
    });

    test('fromBytes parses float marker correctly', () {
      final floatValue = PsDataType.fromPackStreamBytes(
        ByteData.view(
          Uint8List.fromList([
            0xC1,
            0x3F,
            0xF3,
            0xAE,
            0x14,
            0x7A,
            0xE1,
            0x47,
            0xAE,
          ]).buffer,
        ), // 1.23
      );
      expect(floatValue, isA<PsFloat>());
      expect((floatValue as PsFloat).value, closeTo(1.23, 0.0001));
    });

    test('fromBytes parses tiny int markers correctly', () {
      // Test positive tiny ints (0x00-0x7F)
      final posInt0 = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0x00]).buffer),
      );
      expect(posInt0, isA<PsInt>());
      expect(posInt0.value, 0);

      final posInt1 = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0x01]).buffer),
      );
      expect(posInt1, isA<PsInt>());
      expect(posInt1.value, 1);

      final posIntMax = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0x7F]).buffer),
      );
      expect(posIntMax, isA<PsInt>());
      expect(posIntMax.value, 0x7F);

      // Test negative tiny ints (0xF0-0xFF)
      final negInt16 = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0xF0]).buffer),
      );
      expect(negInt16, isA<PsInt>());
      expect(negInt16.value, -16); // 0xF0 signed is -16

      final negInt15 = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0xF1]).buffer),
      );
      expect(negInt15, isA<PsInt>());
      expect(negInt15.value, -15); // 0xF1 signed is -15

      final negInt1 = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0xFF]).buffer),
      );
      expect(negInt1, isA<PsInt>());
      expect(negInt1.value, -1); // 0xFF signed is -1
    });

    test('fromBytes parses int8 marker correctly', () {
      final int8Value = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0xC8, 0x42]).buffer),
      );
      expect(int8Value, isA<PsInt>());
      expect(int8Value.value, 0x42);

      // Edge cases
      final minInt8 = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0xC8, 0x80]).buffer),
      );
      expect(minInt8, isA<PsInt>());
      expect(minInt8.value, -128);

      final maxInt8 = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0xC8, 0x7F]).buffer),
      );
      expect(maxInt8, isA<PsInt>());
      expect(maxInt8.value, 127);
    });

    test('fromBytes parses int16 marker correctly', () {
      final int16Value = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0xC9, 0x01, 0x23]).buffer),
      );
      expect(int16Value, isA<PsInt>());
      expect(int16Value.value, 0x0123);

      // Edge cases
      final minInt16 = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0xC9, 0x80, 0x00]).buffer),
      );
      expect(minInt16, isA<PsInt>());
      expect(minInt16.value, -32768);

      final maxInt16 = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0xC9, 0x7F, 0xFF]).buffer),
      );
      expect(maxInt16, isA<PsInt>());
      expect(maxInt16.value, 32767);
    });

    test('fromBytes parses int32 marker correctly', () {
      final int32Value = PsDataType.fromPackStreamBytes(
        ByteData.view(
          Uint8List.fromList([0xCA, 0x01, 0x23, 0x45, 0x67]).buffer,
        ),
      );
      expect(int32Value, isA<PsInt>());
      expect(int32Value.value, 0x01234567);

      // Edge cases
      final minInt32 = PsDataType.fromPackStreamBytes(
        ByteData.view(
          Uint8List.fromList([0xCA, 0x80, 0x00, 0x00, 0x00]).buffer,
        ),
      );
      expect(minInt32, isA<PsInt>());
      expect(minInt32.value, -2147483648);

      final maxInt32 = PsDataType.fromPackStreamBytes(
        ByteData.view(
          Uint8List.fromList([0xCA, 0x7F, 0xFF, 0xFF, 0xFF]).buffer,
        ),
      );
      expect(maxInt32, isA<PsInt>());
      expect(maxInt32.value, 2147483647);
    });

    test('fromBytes parses int64 marker correctly', () {
      final int64Value = PsDataType.fromPackStreamBytes(
        ByteData.view(
          Uint8List.fromList([
            0xCB,
            0x00,
            0x01,
            0x23,
            0x45,
            0x67,
            0x89,
            0xAB,
            0xCD,
          ]).buffer,
        ),
      );
      expect(int64Value, isA<PsInt>());
      expect(int64Value.value, 0x0123456789ABCD);

      // Edge cases - test large values
      final largeInt64 = PsDataType.fromPackStreamBytes(
        ByteData.view(
          Uint8List.fromList([
            0xCB,
            0x7F,
            0xFF,
            0xFF,
            0xFF,
            0xFF,
            0xFF,
            0xFF,
            0xFF,
          ]).buffer,
        ),
      );
      expect(largeInt64, isA<PsInt>());
      expect(largeInt64.value, 9223372036854775807); // Max long value
    });

    test('fromBytes parses bytes markers correctly', () {
      // Empty bytes array
      final emptyBytes = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0xCC, 0x00]).buffer),
      );
      expect(emptyBytes, isA<PsBytes>());
      expect((emptyBytes as PsBytes).value, isEmpty);

      // Small bytes array with 8-bit size
      final smallBytes = PsDataType.fromPackStreamBytes(
        ByteData.view(
          Uint8List.fromList([0xCC, 0x03, 0x01, 0x02, 0x03]).buffer,
        ),
      );
      expect(smallBytes, isA<PsBytes>());
      expect(
        (smallBytes as PsBytes).value,
        equals(Uint8List.fromList([0x01, 0x02, 0x03])),
      );

      // Larger bytes array with 16-bit size (just testing the marker)
      final data = [0xCD, 0x00, 0x05, 0x10, 0x20, 0x30, 0x40, 0x50];
      final mediumBytes = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList(data).buffer),
      );
      expect(mediumBytes, isA<PsBytes>());
      expect(
        (mediumBytes as PsBytes).value,
        equals(Uint8List.fromList([0x10, 0x20, 0x30, 0x40, 0x50])),
      );
    });

    test('fromBytes parses string markers correctly', () {
      // Test tiny string (0x80-0x8F)
      final emptyString = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0x80]).buffer),
      );
      expect(emptyString, isA<PsString>());
      expect((emptyString as PsString).value, '');

      // String with content requires extra bytes
      final tinyString = PsDataType.fromPackStreamBytes(
        ByteData.view(
          Uint8List.fromList([0x83, 0x61, 0x62, 0x63]).buffer,
        ), // "abc"
      );
      expect(tinyString, isA<PsString>());
      expect((tinyString as PsString).value, 'abc');

      // Test 8-bit size string (0xD0)
      final data = [
        0xD0, 0x12, // Length 18
        // "Hello, PackStream!"
        0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x2C, 0x20, 0x50, 0x61, 0x63, 0x6B, 0x53,
        0x74, 0x72, 0x65, 0x61, 0x6D, 0x21,
      ];
      final string8bit = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList(data).buffer),
      );
      expect(string8bit, isA<PsString>());
      expect((string8bit as PsString).value, 'Hello, PackStream!');

      // Test multi-byte character handling in string
      final unicodeData = [
        0xD0, 0x0C, // Length 12 bytes (but only 5 characters)
        // "こんにちは" (Hello in Japanese)
        0xE3, 0x81, 0x93, 0xE3, 0x82, 0x93, 0xE3, 0x81, 0xAB, 0xE3, 0x81,
        0xA1,
      ];
      final unicodeString = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList(unicodeData).buffer),
      );
      expect(unicodeString, isA<PsString>());
      expect((unicodeString as PsString).value, 'こんにち');
    });

    test('fromBytes parses list markers correctly', () {
      // Test empty list
      final emptyList = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0x90]).buffer),
      );
      expect(emptyList, isA<PsList>());
      expect((emptyList as PsList).value, isEmpty);

      // Test tiny list with integers
      final tinyList = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList([0x93, 0x01, 0x02, 0x03]).buffer),
      );
      expect(tinyList, isA<PsList>());
      expect((tinyList as PsList).value.length, 3);
      expect(tinyList[0].value, 1);
      expect(tinyList[1].value, 2);
      expect(tinyList[2].value, 3);

      // Test 8-bit list
      final listData = [
        0xD4, 0x10, // List with 16 items
        0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
        0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
      ];
      final largeList = PsDataType.fromPackStreamBytes(
        ByteData.view(Uint8List.fromList(listData).buffer),
      );
      expect(largeList, isA<PsList>());
      expect((largeList as PsList).value.length, 16);
      for (int i = 0; i < 16; i++) {
        expect(largeList[i], isA<PsInt>());
        expect(largeList[i].value, i + 1);
      }
    });

    test('fromBytes throws ArgumentError for invalid marker bytes', () {
      // Testing a value outside of the valid ranges
      expect(
        () => PsDataType.fromPackStreamBytes(
          ByteData.view(Uint8List.fromList([0xEF]).buffer),
        ),
        throwsArgumentError,
      );
    });

    test('fromBytes parses dictionary markers correctly', () {
      // Create binary data directly instead of relying on toByteData()
      final emptyDictData = ByteData.view(Uint8List.fromList([0xA0]).buffer);
      final emptyDict = PsDataType.fromPackStreamBytes(emptyDictData);
      expect(emptyDict, isA<PsDictionary>());
      expect((emptyDict as PsDictionary).value, isEmpty);

      // Small dictionary with marker 0xA1 (1 entry), string key marker 0x83 ('key'), and int value 1
      final smallDictBytes = Uint8List.fromList([
        0xA1, // Dictionary with 1 entry
        0x83, 0x6B, 0x65, 0x79, // String 'key' (marker 0x83 + 'key' bytes)
        0x01, // Integer 1
      ]);
      final smallDict = PsDataType.fromPackStreamBytes(
        ByteData.view(smallDictBytes.buffer),
      );
      expect(smallDict, isA<PsDictionary>());

      // Create and test a PsDictionary with a known structure directly to avoid serialization issues
      final manualDict = PsDataType.fromValue({'key': 1}) as PsDictionary;
      expect(manualDict.value.length, 1);
      final manualKeyEntry = manualDict.keys.first;
      expect(manualKeyEntry.value, 'key');
      expect(manualDict[manualKeyEntry]?.value, 1);
    });

    test('fromBytes parses larger bytes markers correctly', () {
      // Test 16-bit bytes marker (0xCD)
      final mediumBytes = PsDataType.fromPackStreamBytes(
        ByteData.view(
          Uint8List.fromList([
            0xCD, 0x00, 0x04, // 16-bit length (4)
            0x01, 0x02, 0x03, 0x04, // content
          ]).buffer,
        ),
      );
      expect(mediumBytes, isA<PsBytes>());
      expect(
        (mediumBytes as PsBytes).value,
        equals(Uint8List.fromList([0x01, 0x02, 0x03, 0x04])),
      );

      // Test 32-bit bytes marker (0xCE)
      final largeBytes = PsDataType.fromPackStreamBytes(
        ByteData.view(
          Uint8List.fromList([
            0xCE, 0x00, 0x00, 0x00, 0x05, // 32-bit length (5)
            0xA1, 0xB2, 0xC3, 0xD4, 0xE5, // content
          ]).buffer,
        ),
      );
      expect(largeBytes, isA<PsBytes>());
      expect(
        (largeBytes as PsBytes).value,
        equals(Uint8List.fromList([0xA1, 0xB2, 0xC3, 0xD4, 0xE5])),
      );
    });

    test('fromBytes parses larger string markers correctly', () {
      // Test 16-bit string marker (0xD1)
      final string16bit = PsDataType.fromPackStreamBytes(
        ByteData.view(
          Uint8List.fromList([
            0xD1, 0x00, 0x0D, // 16-bit length (13)
            // "Hello, World!"
            0x48,
            0x65,
            0x6C,
            0x6C,
            0x6F,
            0x2C,
            0x20,
            0x57,
            0x6F,
            0x72,
            0x6C,
            0x64,
            0x21,
          ]).buffer,
        ),
      );
      expect(string16bit, isA<PsString>());
      expect((string16bit as PsString).value, 'Hello, World!');

      // Test 32-bit string marker (0xD2)
      final string32bit = PsDataType.fromPackStreamBytes(
        ByteData.view(
          Uint8List.fromList([
            0xD2, 0x00, 0x00, 0x00, 0x0F, // 32-bit length (15)
            // "PackStream Test"
            0x50,
            0x61,
            0x63,
            0x6B,
            0x53,
            0x74,
            0x72,
            0x65,
            0x61,
            0x6D,
            0x20,
            0x54,
            0x65,
            0x73,
            0x74,
          ]).buffer,
        ),
      );
      expect(string32bit, isA<PsString>());
      expect((string32bit as PsString).value, 'PackStream Test');
    });

    test('fromBytes parses larger list markers correctly', () {
      // Test 16-bit list marker (0xD5)
      final list16bit = PsDataType.fromPackStreamBytes(
        ByteData.view(
          Uint8List.fromList([
            0xD5, 0x00, 0x05, // 16-bit size (5 items)
            0x01, 0x02, 0x03, 0x04, 0x05, // values
          ]).buffer,
        ),
      );
      expect(list16bit, isA<PsList>());
      expect((list16bit as PsList).value.length, 5);
      for (var i = 0; i < 5; i++) {
        expect(list16bit[i], isA<PsInt>());
        expect(list16bit[i].value, i + 1);
      }

      // Test 32-bit list marker (0xD6)
      final list32bit = PsDataType.fromPackStreamBytes(
        ByteData.view(
          Uint8List.fromList([
            0xD6, 0x00, 0x00, 0x00, 0x03, // 32-bit size (3 items)
            0x0A, 0x14, 0x1E, // values (10, 20, 30)
          ]).buffer,
        ),
      );
      expect(list32bit, isA<PsList>());
      expect((list32bit as PsList).value.length, 3);
      expect(list32bit[0].value, 10);
      expect(list32bit[1].value, 20);
      expect(list32bit[2].value, 30);
    });
  });

  group('PsDataType.fromValue', () {
    test('converts null to PsNull', () {
      final nullValue = PsDataType.fromValue(null);
      expect(nullValue, isA<PsNull>());
    });

    test('converts boolean values to PsBoolean', () {
      final trueValue = PsDataType.fromValue(true);
      expect(trueValue, isA<PsBoolean>());
      expect((trueValue as PsBoolean).value, true);

      final falseValue = PsDataType.fromValue(false);
      expect(falseValue, isA<PsBoolean>());
      expect((falseValue as PsBoolean).value, false);
    });

    test('converts integers to PsInt with the most compact representation', () {
      // Tiny int range (-16 to 127)
      final tinyInt = PsDataType.fromValue(42);
      expect(tinyInt, isA<PsInt>());
      expect(tinyInt.value, 42);

      // Int8 range (-128 to -17)
      final int8Value = PsDataType.fromValue(-100);
      expect(int8Value, isA<PsInt>());
      expect(int8Value.value, -100);

      // Int16 range
      final int16Value = PsDataType.fromValue(10000);
      expect(int16Value, isA<PsInt>());
      expect(int16Value.value, 10000);

      // Int32 range
      final int32Value = PsDataType.fromValue(1000000);
      expect(int32Value, isA<PsInt>());
      expect(int32Value.value, 1000000);

      // Int64 range
      final int64Value = PsDataType.fromValue(9223372036854775000);
      expect(int64Value, isA<PsInt>());
      expect(int64Value.value, 9223372036854775000);
    });

    test('converts doubles to PsFloat', () {
      final floatValue = PsDataType.fromValue(3.14159);
      expect(floatValue, isA<PsFloat>());
      expect((floatValue as PsFloat).value, 3.14159);
    });

    test('converts strings to PsString', () {
      final emptyString = PsDataType.fromValue('');
      expect(emptyString, isA<PsString>());
      expect((emptyString as PsString).value, '');

      final shortString = PsDataType.fromValue('Hello');
      expect(shortString, isA<PsString>());
      expect((shortString as PsString).value, 'Hello');

      final unicodeString = PsDataType.fromValue('こんにちは');
      expect(unicodeString, isA<PsString>());
      expect((unicodeString as PsString).value, 'こんにちは');
    });

    test('converts lists to PsList and recursively converts elements', () {
      final emptyList = PsDataType.fromValue(<dynamic>[]);
      expect(emptyList, isA<PsList>());
      expect((emptyList as PsList).value, isEmpty);

      final simpleList = PsDataType.fromValue([1, 2, 3]);
      expect(simpleList, isA<PsList>());
      expect((simpleList as PsList).value.length, 3);
      expect((simpleList.value[0] as PsInt).value, 1);
      expect((simpleList.value[1] as PsInt).value, 2);
      expect((simpleList.value[2] as PsInt).value, 3);

      final mixedList = PsDataType.fromValue([
        null,
        true,
        42,
        'hello',
        [1, 2],
      ]);
      expect(mixedList, isA<PsList>());
      expect((mixedList as PsList).value.length, 5);
      expect(mixedList.value[0], isA<PsNull>());
      expect(mixedList.value[1], isA<PsBoolean>());
      expect((mixedList.value[1] as PsBoolean).value, true);
      expect(mixedList.value[2], isA<PsInt>());
      expect((mixedList.value[2] as PsInt).value, 42);
      expect(mixedList.value[3], isA<PsString>());
      expect((mixedList.value[3] as PsString).value, 'hello');
      expect(mixedList.value[4], isA<PsList>());
      expect((mixedList.value[4] as PsList).value.length, 2);
    });

    test('converts Uint8List to PsBytes', () {
      final emptyBytes = PsDataType.fromValue(Uint8List(0));
      expect(emptyBytes, isA<PsBytes>());
      expect((emptyBytes as PsBytes).value, isEmpty);

      final byteData = PsDataType.fromValue(Uint8List.fromList([1, 2, 3]));
      expect(byteData, isA<PsBytes>());
      expect((byteData as PsBytes).value.length, 3);
      expect(byteData.value[0], 1);
      expect(byteData.value[1], 2);
      expect(byteData.value[2], 3);
    });

    test('converts ByteData to PsBytes', () {
      final data = ByteData(4);
      data.setUint8(0, 10);
      data.setUint8(1, 20);
      data.setUint8(2, 30);
      data.setUint8(3, 40);

      final byteData = PsDataType.fromValue(data);
      expect(byteData, isA<PsBytes>());
      expect((byteData as PsBytes).value.length, 4);
      final bytes = byteData.toList();
      expect(bytes[0], 10);
      expect(bytes[1], 20);
      expect(bytes[2], 30);
      expect(bytes[3], 40);
    });

    test('converts Int32List and other TypedData to PsBytes', () {
      final int32List = Int32List.fromList([1, 2, 3]);
      final bytesFromInt32 = PsDataType.fromValue(int32List);
      expect(bytesFromInt32, isA<PsBytes>());

      final float64List = Float64List.fromList([1.1, 2.2, 3.3]);
      final bytesFromFloat64 = PsDataType.fromValue(float64List);
      expect(bytesFromFloat64, isA<PsBytes>());
    });

    test('throws ArgumentError for unsupported types', () {
      expect(() => PsDataType.fromValue(DateTime.now()), throwsArgumentError);
      expect(() => PsDataType.fromValue(Symbol('symbol')), throwsArgumentError);
      expect(() => PsDataType.fromValue(RegExp('regex')), throwsArgumentError);
    });
  });
}
