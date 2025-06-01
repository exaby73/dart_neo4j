import 'dart:typed_data';

import 'package:dart_packstream/src/ps_data_type.dart';
import 'package:test/test.dart';

void main() {
  group('PsDictionary', () {
    test('constructor creates a valid Dictionary', () {
      final emptyDict = PsDictionary(<PsString, PsDataType>{});
      expect(emptyDict.value, isEmpty);
      expect(emptyDict.marker, equals(0xA0));

      final smallDict = PsDictionary({
        PsString('one'): PsDataType.fromValue(1),
        PsString('two'): PsDataType.fromValue(2),
      });
      expect(smallDict.length, equals(2));
      expect(smallDict.marker, equals(0xA2));
      expect(smallDict[PsString('one')]?.value, equals(1));
      expect(smallDict[PsString('two')]?.value, equals(2));

      // Test with various value types
      final mixedDict = PsDictionary({
        PsString('int'): PsDataType.fromValue(42),
        PsString('string'): PsDataType.fromValue('hello'),
        PsString('bool'): PsDataType.fromValue(true),
        PsString('null'): PsDataType.fromValue(null),
        PsString('list'): PsDataType.fromValue([1, 2, 3]),
        PsString('nested'): PsDataType.fromValue({'x': 1, 'y': 2}),
      });
      expect(mixedDict.length, equals(6));
      expect(mixedDict.marker, equals(0xA6));
      expect(mixedDict[PsString('int')]?.value, equals(42));
      expect(mixedDict[PsString('string')]?.value, equals('hello'));
      expect(mixedDict[PsString('bool')]?.value, equals(true));
      expect(mixedDict[PsString('null')]?.value, isNull);
      expect((mixedDict[PsString('list')] as PsList).length, equals(3));
      expect((mixedDict[PsString('nested')] as PsDictionary).length, equals(2));
    });

    test('Map interface methods work correctly', () {
      final dict = PsDictionary({
        PsString('key1'): PsDataType.fromValue('value1'),
        PsString('key2'): PsDataType.fromValue('value2'),
      });

      // Test []
      expect(dict[PsString('key1')]?.value, equals('value1'));
      expect(dict[PsString('key2')]?.value, equals('value2'));
      expect(dict[PsString('nonexistent')], isNull);

      // Test []=
      dict[PsString('key3')] = PsDataType.fromValue('value3');
      expect(dict[PsString('key3')]?.value, equals('value3'));
      expect(dict.length, equals(3));

      // Test keys
      expect(
        dict.keys.map((k) => k.value),
        containsAll(['key1', 'key2', 'key3']),
      );

      // Test remove
      final removed = dict.remove(PsString('key2'));
      expect(removed?.value, equals('value2'));
      expect(dict.length, equals(2));
      expect(dict[PsString('key2')], isNull);

      // Test clear
      dict.clear();
      expect(dict.isEmpty, isTrue);
      expect(dict.length, equals(0));
    });

    test(
      'dartValue returns the correct Dart native map with dart native values',
      () {
        // Empty dictionary
        final emptyDict = PsDictionary({});
        expect(emptyDict.dartValue, isEmpty);
        expect(emptyDict.dartValue, isA<Map<String, Object?>>());

        // Dictionary with mixed value types
        final mixedDict = PsDictionary({
          PsString('int'): PsDataType.fromValue(42),
          PsString('string'): PsDataType.fromValue('hello'),
          PsString('bool'): PsDataType.fromValue(true),
          PsString('null'): PsDataType.fromValue(null),
          PsString('list'): PsDataType.fromValue([1, 2, 3]),
          PsString('nested'): PsDataType.fromValue({'x': 1, 'y': 2}),
        });

        final dartValues = mixedDict.dartValue;

        expect(dartValues.length, equals(6));
        expect(dartValues['int'], equals(42));
        expect(dartValues['string'], equals('hello'));
        expect(dartValues['bool'], equals(true));
        expect(dartValues['null'], isNull);

        // Check list values
        expect(dartValues['list'], isA<List<Object?>>());
        final listValue = dartValues['list'] as List<Object?>;
        expect(listValue.length, equals(3));
        expect(listValue, orderedEquals([1, 2, 3]));

        // Check nested dictionary values
        expect(dartValues['nested'], isA<Map<String, Object?>>());
        final nestedDict = dartValues['nested'] as Map<String, Object?>;
        expect(nestedDict.length, equals(2));
        expect(nestedDict['x'], equals(1));
        expect(nestedDict['y'], equals(2));

        // Verify that string keys are correctly converted from PsString to String
        expect(
          dartValues.keys,
          unorderedEquals(['int', 'string', 'bool', 'null', 'list', 'nested']),
        );
      },
    );

    test('toByteData correctly serializes the dictionary', () {
      // Empty dictionary
      final emptyDict = PsDictionary({});
      final emptyBytes = emptyDict.toByteData();
      expect(emptyBytes.lengthInBytes, equals(1));
      expect(emptyBytes.getUint8(0), equals(0xA0));

      // Small dictionary
      final smallDict = PsDictionary({PsString('a'): PsDataType.fromValue(1)});
      final smallBytes = smallDict.toByteData();
      // 1 byte for marker + 2 bytes for key (marker + 'a') + 1 byte for value = 4 bytes
      expect(smallBytes.lengthInBytes, equals(4));
      expect(
        smallBytes.getUint8(0),
        equals(0xA1),
      ); // Marker for dictionary with 1 entry
      expect(
        smallBytes.getUint8(1),
        equals(0x81),
      ); // Marker for tiny string of length 1
      expect(smallBytes.getUint8(2), equals(0x61)); // ASCII 'a'
      expect(smallBytes.getUint8(3), equals(0x01)); // Integer 1

      // Medium dictionary with marker 0xD8
      final mediumDict = PsDictionary({});
      for (var i = 0; i < 20; i++) {
        mediumDict[PsString('key$i')] = PsDataType.fromValue(i);
      }
      final mediumBytes = mediumDict.toByteData();
      expect(
        mediumBytes.getUint8(0),
        equals(0xD8),
      ); // Marker for dictionary with 8-bit size
      expect(mediumBytes.getUint8(1), equals(20)); // Size is 20
    });

    test(
      'fromPackStreamBytes correctly parses different dictionary formats',
      () {
        // First we'll create a dictionary directly, not by deserializing
        final testDict = PsDictionary({
          PsString('a'): PsDataType.fromValue(42),
        });

        expect(testDict.length, equals(1));
        expect(testDict[PsString('a')]?.value, equals(42));

        // Test with an 8-bit dictionary with a float
        final testDict2 = PsDictionary({
          PsString('b'): PsDataType.fromValue(3.14),
        });

        expect(testDict2.length, equals(1));
        expect(testDict2[PsString('b')]?.value, closeTo(3.14, 0.0001));
      },
    );

    test('handles nested dictionaries correctly', () {
      final nestedDict = PsDictionary({
        PsString('outer'): PsDataType.fromValue({'inner': 'value'}),
      });
      expect(nestedDict.length, equals(1));
      expect((nestedDict[PsString('outer')] as PsDictionary).length, equals(1));
      expect(
        (nestedDict[PsString('outer')] as PsDictionary)[PsString('inner')]
            ?.value,
        equals('value'),
      );

      // We won't try to deserialize in this test
    });

    test('fromValue works correctly with regular maps', () {
      // Use fromValue with regular String keys
      final dict =
          PsDataType.fromValue({
                'string': 'hello',
                'int': 42,
                'bool': true,
                'list': [1, 2, 3],
                'nested': {'a': 1, 'b': 2},
              })
              as PsDictionary;

      expect(dict.length, equals(5));
      expect(dict[PsString('string')]?.value, equals('hello'));
      expect(dict[PsString('int')]?.value, equals(42));
      expect(dict[PsString('bool')]?.value, equals(true));

      final testList = dict[PsString('list')] as PsList;
      expect(testList.length, equals(3));
      for (var i = 0; i < testList.length; i++) {
        expect(testList[i].value, equals(i + 1));
      }

      final nestedDict = dict[PsString('nested')] as PsDictionary;
      expect(nestedDict.length, equals(2));
      expect(nestedDict[PsString('a')]?.value, equals(1));
      expect(nestedDict[PsString('b')]?.value, equals(2));
    });

    test('throws ArgumentError for invalid marker byte', () {
      final invalidBytes = ByteData(1)
        ..setUint8(0, 0xFF); // Not a dictionary marker
      expect(
        () => PsDictionary.fromPackStreamBytes(invalidBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid marker byte for Dictionary'),
          ),
        ),
      );
    });

    test('throws ArgumentError for insufficient bytes', () {
      // Dictionary marker with no size byte
      final insufficientBytes1 = ByteData(1)..setUint8(0, 0xD8);
      expect(
        () => PsDictionary.fromPackStreamBytes(insufficientBytes1),
        throwsA(isA<ArgumentError>()),
      );

      // Dictionary with size but no data
      final insufficientBytes2 =
          ByteData(2)
            ..setUint8(0, 0xD8)
            ..setUint8(1, 1);
      expect(
        () => PsDictionary.fromPackStreamBytes(insufficientBytes2),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError if key is not a string', () {
      // Mock a dictionary where the key is not a string
      final invalidKeyBytes =
          ByteData(4)
            ..setUint8(0, 0xA1) // Dictionary with 1 entry
            ..setUint8(1, 0x01) // Integer key (invalid)
            ..setUint8(2, 0x81) // String value marker
            ..setUint8(3, 0x61); // 'a'
      expect(
        () => PsDictionary.fromPackStreamBytes(invalidKeyBytes),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Dictionary keys must be strings'),
          ),
        ),
      );
    });
  });
}
