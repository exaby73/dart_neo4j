import 'package:dart_bolt/dart_bolt.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    // Register all Bolt structures before running tests
    registerBoltStructures();
  });

  tearDown(() {
    // Clear registry after each test to ensure clean state
    PsStructureRegistry.clear();
    registerBoltStructures();
  });

  group('BoltNode', () {
    test('creates node without element ID (pre Bolt 5.0)', () {
      final node = BoltNode(
        PsInt.compact(42),
        PsList(<PsDataType>[PsString('Person'), PsString('User')]),
        PsDictionary({
          PsString('name'): PsString('Alice'),
          PsString('age'): PsInt.compact(30),
        }),
      );

      expect(node.numberOfFields, equals(3));
      expect(node.tagByte, equals(0x4E));
      expect(node.id.dartValue, equals(42));
      expect(node.labels.value.length, equals(2));
      expect((node.labels.value[0] as PsString).dartValue, equals('Person'));
      expect((node.labels.value[1] as PsString).dartValue, equals('User'));
      expect(node.properties.value.length, equals(2));
      expect(node.elementId, isNull);
      expect(node.hasElementId, isFalse);
    });

    test('creates node with element ID (Bolt 5.0+)', () {
      final node = BoltNode(
        PsInt.compact(123),
        PsList(<PsDataType>[PsString('Test')]),
        PsDictionary({PsString('prop'): PsString('value')}),
        elementId: PsString('element123'),
      );

      expect(node.numberOfFields, equals(4));
      expect(node.tagByte, equals(0x4E));
      expect(node.id.dartValue, equals(123));
      expect(node.elementId?.dartValue, equals('element123'));
      expect(node.hasElementId, isTrue);
    });

    test('serializes and deserializes correctly via registry', () {
      final original = BoltNode(
        PsInt.compact(123),
        PsList(<PsDataType>[PsString('Test')]),
        PsDictionary({PsString('prop'): PsString('value')}),
        elementId: PsString('element123'),
      );

      final bytes = original.toByteData();
      expect(bytes.getUint8(0), equals(0xB4)); // 4 fields
      expect(bytes.getUint8(1), equals(0x4E)); // Node tag

      // Test round-trip parsing via registry
      final parsed = PsDataType.fromPackStreamBytes(bytes) as BoltNode;
      expect(parsed.id.dartValue, equals(123));
      expect(parsed.elementId?.dartValue, equals('element123'));
    });

    test('creates from parsed values', () {
      final values = <PsDataType>[
        PsInt.compact(99),
        PsList(<PsDataType>[PsString('Label')]),
        PsDictionary({PsString('key'): PsString('value')}),
        PsString('elem99'),
      ];

      final node = BoltNode.fromValues(values);
      expect(node.id.dartValue, equals(99));
      expect(node.elementId?.dartValue, equals('elem99'));
    });

    test('throws error for invalid field count', () {
      expect(
        () => BoltNode.fromValues(<PsDataType>[
          PsInt.compact(1),
          PsList(<PsDataType>[]),
        ]),
        throwsArgumentError,
      );
    });

    test('round-trip serialization preserves all data', () {
      final original = BoltNode(
        PsInt.compact(12345),
        PsList(<PsDataType>[
          PsString('Person'),
          PsString('User'),
          PsString('Admin'),
        ]),
        PsDictionary({
          PsString('name'): PsString('John Doe'),
          PsString('age'): PsInt.compact(30),
          PsString('active'): PsBoolean(true),
        }),
        elementId: PsString('node-12345'),
      );

      final bytes = original.toByteData();
      final parsed = PsDataType.fromPackStreamBytes(bytes) as BoltNode;

      expect(parsed.id.dartValue, equals(original.id.dartValue));
      expect(parsed.labels.value.length, equals(original.labels.value.length));
      expect(
        parsed.properties.value.length,
        equals(original.properties.value.length),
      );
      expect(
        parsed.elementId?.dartValue,
        equals(original.elementId?.dartValue),
      );
      expect(parsed.hasElementId, equals(original.hasElementId));
    });
  });
}
