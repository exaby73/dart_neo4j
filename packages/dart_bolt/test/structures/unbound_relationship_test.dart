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

  group('BoltUnboundRelationship', () {
    test('creates unbound relationship without element ID (pre Bolt 5.0)', () {
      final unbound = BoltUnboundRelationship(
        PsInt.compact(500),
        PsString('CONNECTS'),
        PsDictionary({PsString('weight'): PsInt.compact(5)}),
      );

      expect(unbound.numberOfFields, equals(3));
      expect(unbound.tagByte, equals(0x72));
      expect(unbound.id.dartValue, equals(500));
      expect(unbound.type.dartValue, equals('CONNECTS'));
      expect(unbound.elementId, isNull);
      expect(unbound.hasElementId, isFalse);
    });

    test('creates unbound relationship with element ID (Bolt 5.0+)', () {
      final unbound = BoltUnboundRelationship(
        PsInt.compact(600),
        PsString('RELATES_TO'),
        PsDictionary({}),
        elementId: PsString('unbound600'),
      );

      expect(unbound.numberOfFields, equals(4));
      expect(unbound.tagByte, equals(0x72));
      expect(unbound.elementId?.dartValue, equals('unbound600'));
      expect(unbound.hasElementId, isTrue);
    });

    test('serializes and deserializes correctly', () {
      final original = BoltUnboundRelationship(
        PsInt.compact(700),
        PsString('INCLUDES'),
        PsDictionary({PsString('priority'): PsString('high')}),
        elementId: PsString('unbound700'),
      );

      final bytes = original.toByteData();
      expect(bytes.getUint8(0), equals(0xB4)); // 4 fields
      expect(bytes.getUint8(1), equals(0x72)); // UnboundRelationship tag

      final parsed =
          PsDataType.fromPackStreamBytes(bytes) as BoltUnboundRelationship;
      expect(parsed.id.dartValue, equals(700));
      expect(parsed.elementId?.dartValue, equals('unbound700'));
    });

    test('creates from parsed values', () {
      final values = <PsDataType>[
        PsInt.compact(800),
        PsString('BELONGS_TO'),
        PsDictionary({PsString('category'): PsString('test')}),
        PsString('unbound800'),
      ];

      final unbound = BoltUnboundRelationship.fromValues(values);
      expect(unbound.id.dartValue, equals(800));
      expect(unbound.type.dartValue, equals('BELONGS_TO'));
      expect(unbound.elementId?.dartValue, equals('unbound800'));
    });

    test('throws error for invalid field count', () {
      expect(
        () =>
            BoltUnboundRelationship.fromValues(<PsDataType>[PsInt.compact(1)]),
        throwsArgumentError,
      );
    });
  });
}
