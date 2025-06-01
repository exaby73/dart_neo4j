import 'dart:typed_data';

import 'package:dart_packstream/src/ps_data_type.dart';
import 'package:test/test.dart';

// Example concrete Structure implementation for testing
class TestStructure extends PsStructure {
  TestStructure(List<PsDataType> values) : super(values.length, 0x4E, values);
}

// Another test structure
class TestStructureWithDifferentTag extends PsStructure {
  TestStructureWithDifferentTag(List<PsDataType> values)
    : super(values.length, 0x52, values);
}

void main() {
  group('StructureRegistry', () {
    setUp(() {
      PsStructureRegistry.clear();
    });

    tearDown(() {
      PsStructureRegistry.clear();
    });

    test('register and create structure', () {
      PsStructureRegistry.register(0x4E, (values) => TestStructure(values));

      expect(PsStructureRegistry.isRegistered(0x4E), isTrue);
      expect(PsStructureRegistry.isRegistered(0x52), isFalse);

      final values = [PsDataType.fromValue(42), PsDataType.fromValue('test')];
      final structure = PsStructureRegistry.createStructure(0x4E, values);

      expect(structure, isA<TestStructure>());
      expect(structure.tagByte, equals(0x4E));
      expect(structure.numberOfFields, equals(2));
      expect(structure.values.length, equals(2));
    });

    test('register throws on invalid tag byte', () {
      expect(
        () =>
            PsStructureRegistry.register(-1, (values) => TestStructure(values)),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => PsStructureRegistry.register(
          128,
          (values) => TestStructure(values),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createStructure throws when no factory registered', () {
      expect(
        () => PsStructureRegistry.createStructure(0x4E, []),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'No factory registered for tag byte: 78 (0x4e)',
          ),
        ),
      );
    });

    test('unregister removes factory', () {
      PsStructureRegistry.register(0x4E, (values) => TestStructure(values));
      expect(PsStructureRegistry.isRegistered(0x4E), isTrue);

      PsStructureRegistry.unregister(0x4E);
      expect(PsStructureRegistry.isRegistered(0x4E), isFalse);
    });

    test('clear removes all factories', () {
      PsStructureRegistry.register(0x4E, (values) => TestStructure(values));
      PsStructureRegistry.register(
        0x52,
        (values) => TestStructureWithDifferentTag(values),
      );

      expect(PsStructureRegistry.isRegistered(0x4E), isTrue);
      expect(PsStructureRegistry.isRegistered(0x52), isTrue);

      PsStructureRegistry.clear();

      expect(PsStructureRegistry.isRegistered(0x4E), isFalse);
      expect(PsStructureRegistry.isRegistered(0x52), isFalse);
    });
  });

  group('Structure', () {
    setUp(() {
      PsStructureRegistry.clear();
      PsStructureRegistry.register(0x4E, (values) => TestStructure(values));
    });

    tearDown(() {
      PsStructureRegistry.clear();
    });

    test('creates structure with correct properties', () {
      final values = [
        PsDataType.fromValue(42),
        PsDataType.fromValue('hello'),
        PsDataType.fromValue(true),
      ];
      final structure = TestStructure(values);

      expect(structure.numberOfFields, equals(3));
      expect(structure.tagByte, equals(0x4E));
      expect(structure.values, equals(values));
      expect(structure.marker, equals(0xB3)); // 0xB0 + 3
      expect(structure.value, equals(values));
      expect(structure.dartValue, equals([42, 'hello', true]));
    });

    test('marker calculation is correct', () {
      final emptyStructure = TestStructure([]);
      expect(emptyStructure.marker, equals(0xB0));

      final oneFieldStructure = TestStructure([PsDataType.fromValue(1)]);
      expect(oneFieldStructure.marker, equals(0xB1));

      final maxFieldStructure = TestStructure(
        List.generate(15, (i) => PsDataType.fromValue(i)),
      );
      expect(maxFieldStructure.marker, equals(0xBF));
    });

    test('throws on invalid number of fields', () {
      expect(
        () => TestStructure(List.generate(16, (i) => PsDataType.fromValue(i))),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => TestStructureWithInvalidNumberOfFields(),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toByteData serializes correctly', () {
      final values = [PsDataType.fromValue(1), PsDataType.fromValue(2)];
      final structure = TestStructure(values);

      final bytes = structure.toByteData();

      // Should be: marker (0xB2), tag (0x4E), value1 (0x01), value2 (0x02)
      expect(bytes.getUint8(0), equals(0xB2)); // marker for 2 fields
      expect(bytes.getUint8(1), equals(0x4E)); // tag byte
      expect(bytes.getUint8(2), equals(0x01)); // first value
      expect(bytes.getUint8(3), equals(0x02)); // second value
    });

    test('toByteData throws on mismatched fields and values', () {
      // Create structure with mismatched numberOfFields and values length
      final structure = TestStructureWithInvalidState();

      expect(() => structure.toByteData(), throwsA(isA<StateError>()));
    });

    test('fromPackStreamBytes parses structure correctly', () {
      final originalValues = [
        PsDataType.fromValue(42),
        PsDataType.fromValue('test'),
      ];
      final originalStructure = TestStructure(originalValues);
      final bytes = originalStructure.toByteData();

      final parsedStructure = PsDataType.fromPackStreamBytes(bytes);

      expect(parsedStructure, isA<TestStructure>());
      final structure = parsedStructure as TestStructure;
      expect(structure.numberOfFields, equals(2));
      expect(structure.tagByte, equals(0x4E));
      expect(structure.values.length, equals(2));
      expect((structure.values[0] as PsInt).value, equals(42));
      expect((structure.values[1] as PsString).value, equals('test'));
    });

    test('fromPackStreamBytes handles empty structure', () {
      final emptyStructure = TestStructure([]);
      final bytes = emptyStructure.toByteData();

      final parsedStructure = PsDataType.fromPackStreamBytes(bytes);

      expect(parsedStructure, isA<TestStructure>());
      final structure = parsedStructure as TestStructure;
      expect(structure.numberOfFields, equals(0));
      expect(structure.tagByte, equals(0x4E));
      expect(structure.values, isEmpty);
    });

    test('fromPackStreamBytes throws on insufficient bytes', () {
      final bytes = ByteData(1);
      bytes.setUint8(0, 0xB1); // Structure with 1 field but no tag byte

      expect(
        () => PsDataType.fromPackStreamBytes(bytes),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromPackStreamBytes throws on invalid tag byte', () {
      final bytes = ByteData(2);
      bytes.setUint8(0, 0xB0); // Structure with 0 fields
      bytes.setUint8(1, 128); // Invalid tag byte (> 127)

      expect(
        () => PsDataType.fromPackStreamBytes(bytes),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromPackStreamBytes throws when no factory registered', () {
      PsStructureRegistry.clear(); // Remove all factories

      final bytes = ByteData(2);
      bytes.setUint8(0, 0xB0); // Structure with 0 fields
      bytes.setUint8(1, 0x4E); // Valid tag byte but no factory

      expect(
        () => PsDataType.fromPackStreamBytes(bytes),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('equality works correctly', () {
      final values1 = [PsDataType.fromValue(42)];
      final values2 = [PsDataType.fromValue(42)];
      final values3 = [PsDataType.fromValue(43)];

      final structure1 = TestStructure(values1);
      final structure2 = TestStructure(values2);
      final structure3 = TestStructure(values3);

      expect(structure1, equals(structure2));
      expect(structure1, isNot(equals(structure3)));
      expect(structure1.hashCode, equals(structure2.hashCode));
    });

    test('toString returns useful representation', () {
      final values = [PsDataType.fromValue(42)];
      final structure = TestStructure(values);

      final string = structure.toString();
      expect(string, contains('Structure'));
      expect(string, contains('fields: 1'));
      expect(string, contains('tag: 0x4e'));
    });

    test('complex structure with nested data', () {
      final complexValues = [
        PsDataType.fromValue(123),
        PsDataType.fromValue(['a', 'b', 'c']),
        PsDataType.fromValue({'key': 'value', 'number': 42}),
        PsDataType.fromValue(3.14),
      ];
      final structure = TestStructure(complexValues);

      final bytes = structure.toByteData();
      final parsedStructure =
          PsDataType.fromPackStreamBytes(bytes) as TestStructure;

      expect(parsedStructure.numberOfFields, equals(4));
      expect(parsedStructure.tagByte, equals(0x4E));
      expect((parsedStructure.values[0] as PsInt).dartValue, equals(123));
      expect(
        (parsedStructure.values[1] as PsList).dartValue,
        equals(['a', 'b', 'c']),
      );
      expect(
        (parsedStructure.values[2] as PsDictionary).dartValue,
        equals({'key': 'value', 'number': 42}),
      );
      expect((parsedStructure.values[3] as PsFloat).dartValue, equals(3.14));
    });
  });
}

// Helper class for testing invalid state
class TestStructureWithInvalidState extends PsStructure {
  TestStructureWithInvalidState() : super(2, 0x4E, [PsDataType.fromValue(1)]) {
    // This should be allowed for testing purposes - we want to test the toByteData validation
  }
}

// Helper class for testing invalid number of fields
class TestStructureWithInvalidNumberOfFields extends PsStructure {
  TestStructureWithInvalidNumberOfFields()
    : super(-1, 0x4E, []); // Invalid: -1 fields
}
