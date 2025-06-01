import 'package:dart_bolt/dart_bolt.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    registerBoltStructures();
  });

  tearDown(() {
    PsStructureRegistry.clear();
    registerBoltStructures();
  });

  group('BoltRelationship', () {
    test('creates relationship without element IDs (pre Bolt 5.0)', () {
      final rel = BoltRelationship(
        PsInt.compact(100),
        PsInt.compact(1),
        PsInt.compact(2),
        PsString('KNOWS'),
        PsDictionary({PsString('since'): PsInt.compact(2020)}),
      );

      expect(rel.numberOfFields, equals(5));
      expect(rel.tagByte, equals(0x52));
      expect(rel.id.dartValue, equals(100));
      expect(rel.startNodeId.dartValue, equals(1));
      expect(rel.endNodeId.dartValue, equals(2));
      expect(rel.type.dartValue, equals('KNOWS'));
      expect(rel.elementId, isNull);
      expect(rel.hasElementIds, isFalse);
    });

    test('creates relationship with element IDs (Bolt 5.0+)', () {
      final rel = BoltRelationship(
        PsInt.compact(200),
        PsInt.compact(3),
        PsInt.compact(4),
        PsString('FOLLOWS'),
        PsDictionary({}),
        elementId: PsString('rel200'),
        startNodeElementId: PsString('node3'),
        endNodeElementId: PsString('node4'),
      );

      expect(rel.numberOfFields, equals(8));
      expect(rel.tagByte, equals(0x52));
      expect(rel.elementId?.dartValue, equals('rel200'));
      expect(rel.startNodeElementId?.dartValue, equals('node3'));
      expect(rel.endNodeElementId?.dartValue, equals('node4'));
      expect(rel.hasElementIds, isTrue);
    });

    test('serializes and deserializes correctly', () {
      final original = BoltRelationship(
        PsInt.compact(300),
        PsInt.compact(5),
        PsInt.compact(6),
        PsString('LIKES'),
        PsDictionary({PsString('strength'): PsInt.compact(10)}),
        elementId: PsString('rel300'),
        startNodeElementId: PsString('node5'),
        endNodeElementId: PsString('node6'),
      );

      final bytes = original.toByteData();
      expect(bytes.getUint8(0), equals(0xB8)); // 8 fields
      expect(bytes.getUint8(1), equals(0x52)); // Relationship tag

      final parsed = PsDataType.fromPackStreamBytes(bytes) as BoltRelationship;
      expect(parsed.id.dartValue, equals(300));
      expect(parsed.elementId?.dartValue, equals('rel300'));
    });

    test('creates from parsed values', () {
      final values = <PsDataType>[
        PsInt.compact(400),
        PsInt.compact(7),
        PsInt.compact(8),
        PsString('WORKS_FOR'),
        PsDictionary({PsString('role'): PsString('Developer')}),
        PsString('rel400'),
        PsString('node7'),
        PsString('node8'),
      ];

      final rel = BoltRelationship.fromValues(values);
      expect(rel.id.dartValue, equals(400));
      expect(rel.type.dartValue, equals('WORKS_FOR'));
      expect(rel.elementId?.dartValue, equals('rel400'));
    });

    test('throws error for invalid field count', () {
      expect(
        () => BoltRelationship.fromValues(<PsDataType>[
          PsInt.compact(1),
          PsInt.compact(2),
        ]),
        throwsArgumentError,
      );
    });
  });
}
