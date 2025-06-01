import 'dart:typed_data';
import 'package:dart_packstream/src/ps_data_type.dart';
import 'package:test/test.dart';

void main() {
  group('PsList', () {
    test('constructor creates a valid List', () {
      final emptyList = PsList([]);
      expect(emptyList.isEmpty, true);
      expect(emptyList.isNotEmpty, false);
      expect(emptyList.length, 0);

      final psList = PsList([
        PsInt.compact(1),
        PsString('test'),
        PsBoolean(true),
      ]);

      expect(psList.length, 3);
      expect(psList.isEmpty, false);
      expect(psList.isNotEmpty, true);
      expect(psList[0].value, 1);
      expect(psList[1].value, 'test');
      expect(psList[2].value, true);
    });

    test(
      'dartValue returns the correct Dart native list with dart native values',
      () {
        // Empty list
        final emptyList = PsList([]);
        expect(emptyList.dartValue, isEmpty);
        expect(emptyList.dartValue, isA<List<Object?>>());

        // List with mixed types
        final mixedList = PsList([
          PsInt.compact(42),
          PsString('hello'),
          PsBoolean(true),
          PsNull(),
          PsFloat(3.14),
          PsBytes(Uint8List.fromList([1, 2, 3])),
          // Nested list
          PsList([PsInt.compact(1), PsInt.compact(2)]),
          // Nested dictionary
          PsDictionary({PsString('key'): PsString('value')}),
        ]);

        final dartValues = mixedList.dartValue;

        expect(dartValues.length, equals(8));
        expect(dartValues[0], equals(42));
        expect(dartValues[1], equals('hello'));
        expect(dartValues[2], equals(true));
        expect(dartValues[3], isNull);
        expect(dartValues[4], closeTo(3.14, 0.0001));
        expect(dartValues[5], isA<Uint8List>());
        expect(dartValues[6], isA<List<Object?>>());
        expect(dartValues[7], isA<Map<String, Object?>>());

        // Check nested list values
        final nestedList = dartValues[6] as List<Object?>;
        expect(nestedList.length, equals(2));
        expect(nestedList[0], equals(1));
        expect(nestedList[1], equals(2));

        // Check nested dictionary values
        final nestedDict = dartValues[7] as Map<String, Object?>;
        expect(nestedDict.length, equals(1));
        expect(nestedDict['key'], equals('value'));
      },
    );

    test('marker returns correct value based on list size', () {
      // Tiny list (0-15 items)
      final emptyList = PsList([]);
      expect(emptyList.marker, 0x90);

      final smallList = PsList(List.generate(5, (i) => PsInt.compact(i)));
      expect(smallList.marker, 0x95);

      final maxTinyList = PsList(List.generate(15, (i) => PsInt.compact(i)));
      expect(maxTinyList.marker, 0x9F);

      // 8-bit list (16-255 items)
      final smallMediumList = PsList(
        List.generate(16, (i) => PsInt.compact(i)),
      );
      expect(smallMediumList.marker, 0xD4);

      final mediumList = PsList(List.generate(255, (i) => PsInt.compact(i)));
      expect(mediumList.marker, 0xD4);

      // 16-bit list (256-65535 items)
      final largeList = PsList(List.generate(256, (i) => PsInt.compact(i)));
      expect(largeList.marker, 0xD5);
    });

    test('toByteData correctly serializes the list', () {
      // Empty list
      final emptyList = PsList([]);
      final emptyBytes = emptyList.toByteData();
      expect(emptyBytes.lengthInBytes, 1);
      expect(emptyBytes.getUint8(0), 0x90);

      // List with single item
      final singleItemList = PsList([PsInt.compact(42)]);
      final singleItemBytes = singleItemList.toByteData();
      expect(singleItemBytes.lengthInBytes, 2);
      expect(singleItemBytes.getUint8(0), 0x91);
      expect(singleItemBytes.getUint8(1), 42);

      // List with mixed types
      final mixedList = PsList([
        PsInt.compact(1),
        PsString('abc'),
        PsBoolean(true),
      ]);
      final mixedBytes = mixedList.toByteData();

      // Manually check the bytes
      expect(mixedBytes.getUint8(0), 0x93); // List with 3 items
      expect(mixedBytes.getUint8(1), 0x01); // Int 1
      expect(mixedBytes.getUint8(2), 0x83); // String marker for 3 chars
      expect(mixedBytes.getUint8(3), 0x61); // 'a'
      expect(mixedBytes.getUint8(4), 0x62); // 'b'
      expect(mixedBytes.getUint8(5), 0x63); // 'c'
      expect(mixedBytes.getUint8(6), 0xC3); // Boolean true
    });

    test('fromBytes correctly parses different list formats', () {
      // Empty list
      final emptyData = ByteData.view(Uint8List.fromList([0x90]).buffer);
      final emptyList = PsList.fromPackStreamBytes(emptyData);
      expect(emptyList.isEmpty, true);

      // Tiny list with integers
      final tinyData = ByteData.view(
        Uint8List.fromList([0x93, 0x01, 0x02, 0x03]).buffer,
      );
      final tinyList = PsList.fromPackStreamBytes(tinyData);
      expect(tinyList.length, 3);
      expect(tinyList[0].value, 1);
      expect(tinyList[1].value, 2);
      expect(tinyList[2].value, 3);

      // 8-bit list
      final list8BitData = ByteData.view(
        Uint8List.fromList([
          0xD4, 0x05, // List with 5 items
          0x01, 0x02, 0x03, 0x04, 0x05,
        ]).buffer,
      );
      final list8Bit = PsList.fromPackStreamBytes(list8BitData);
      expect(list8Bit.length, 5);
      for (int i = 0; i < 5; i++) {
        expect(list8Bit[i].value, i + 1);
      }

      // 16-bit list (just test the marker and size parsing)
      final list16BitData = ByteData.view(
        Uint8List.fromList([
          0xD5, 0x00, 0x03, // List with 3 items (16-bit)
          0x01, 0x02, 0x03,
        ]).buffer,
      );
      final list16Bit = PsList.fromPackStreamBytes(list16BitData);
      expect(list16Bit.length, 3);
      for (int i = 0; i < 3; i++) {
        expect(list16Bit[i].value, i + 1);
      }
    });

    test('handles mixed-type lists correctly', () {
      // Create a list with different data types
      final intValue = PsInt.compact(42);
      final floatValue = PsFloat(3.14);
      final stringValue = PsString('hello');
      final boolValue = PsBoolean(true);
      final nullValue = PsNull();
      final bytesValue = PsBytes(Uint8List.fromList([1, 2, 3]));

      // Create the list with multiple data types
      final mixedList = PsList([
        intValue,
        floatValue,
        stringValue,
        boolValue,
        nullValue,
        bytesValue,
      ]);

      // Check basic properties
      expect(mixedList.length, 6);
      expect(mixedList[0], same(intValue));
      expect(mixedList[1], same(floatValue));
      expect(mixedList[2], same(stringValue));
      expect(mixedList[3], same(boolValue));
      expect(mixedList[4], same(nullValue));
      expect(mixedList[5], same(bytesValue));
    });

    test('serializes and deserializes correctly (roundtrip)', () {
      // Create a simple list with integers
      final originalList = PsList(
        List.generate(5, (i) => PsInt.compact(i + 10)),
      );

      // Serialize the list
      final bytes = originalList.toByteData();

      // Deserialize the list
      final deserializedList = PsList.fromPackStreamBytes(bytes);

      // Check if values match
      expect(deserializedList.length, originalList.length);
      for (int i = 0; i < originalList.length; i++) {
        expect(deserializedList[i].value, originalList[i].value);
      }
    });

    test('fromBytes correctly parses nested lists', () {
      final nestedData = ByteData.view(
        Uint8List.fromList([
          0x92, // List with 2 items
          0x91, 0x01, // First item: list with 1 item (integer 1)
          0x92, 0x02, 0x03, // Second item: list with 2 items (integers 2 and 3)
        ]).buffer,
      );

      final nestedList = PsList.fromPackStreamBytes(nestedData);
      expect(nestedList.length, 2);

      // Check first inner list
      expect(nestedList[0], isA<PsList>());
      final firstInnerList = nestedList[0] as PsList;
      expect(firstInnerList.length, 1);
      expect(firstInnerList[0].value, 1);

      // Check second inner list
      expect(nestedList[1], isA<PsList>());
      final secondInnerList = nestedList[1] as PsList;
      expect(secondInnerList.length, 2);
      expect(secondInnerList[0].value, 2);
      expect(secondInnerList[1].value, 3);
    });

    test('throws ArgumentError for insufficient bytes', () {
      expect(
        () => PsList.fromPackStreamBytes(
          ByteData.view(
            Uint8List.fromList([0x91]).buffer,
          ), // List with 1 item but missing the item
        ),
        throwsArgumentError,
      );
    });

    test('[] operator works correctly', () {
      final list = PsList([
        PsInt.compact(10),
        PsString('test'),
        PsBoolean(false),
      ]);

      expect(list[0].value, 10);
      expect(list[1].value, 'test');
      expect(list[2].value, false);

      // Check that it throws when index is out of bounds
      expect(() => list[3], throwsRangeError);
    });

    test('forEach iterates over all elements', () {
      final list = PsList([
        PsInt.compact(1),
        PsInt.compact(2),
        PsInt.compact(3),
      ]);

      int sum = 0;
      for (final element in list) {
        sum += element.value as int;
      }

      expect(sum, 6); // 1 + 2 + 3 = 6
    });
  });
}
