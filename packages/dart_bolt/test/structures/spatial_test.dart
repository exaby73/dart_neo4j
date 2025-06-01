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

  group('BoltPoint2D', () {
    test('creates 2D point structure', () {
      final point = BoltPoint2D(
        PsInt.compact(4326), // WGS84 SRID
        PsFloat(12.345),
        PsFloat(67.890),
      );

      expect(point.numberOfFields, equals(3));
      expect(point.tagByte, equals(0x58));
      expect(point.srid.dartValue, equals(4326));
      expect(point.x.dartValue, equals(12.345));
      expect(point.y.dartValue, equals(67.890));
    });

    test('serializes and deserializes correctly', () {
      final original = BoltPoint2D(
        PsInt.compact(7203), // Cartesian SRID
        PsFloat(100.0),
        PsFloat(200.0),
      );

      final bytes = original.toByteData();
      expect(bytes.getUint8(0), equals(0xB3)); // 3 fields
      expect(bytes.getUint8(1), equals(0x58)); // Point2D tag

      final parsed = PsDataType.fromPackStreamBytes(bytes) as BoltPoint2D;
      expect(parsed.srid.dartValue, equals(7203));
      expect(parsed.x.dartValue, equals(100.0));
      expect(parsed.y.dartValue, equals(200.0));
    });

    test('creates from parsed values', () {
      final values = <PsDataType>[
        PsInt.compact(4979), // SRID
        PsFloat(-74.006),
        PsFloat(40.7128),
      ];

      final point = BoltPoint2D.fromValues(values);
      expect(point.srid.dartValue, equals(4979));
      expect(point.x.dartValue, equals(-74.006));
      expect(point.y.dartValue, equals(40.7128));
    });

    test('throws error for invalid field count', () {
      expect(
        () => BoltPoint2D.fromValues(<PsDataType>[
          PsInt.compact(1),
          PsFloat(1.0),
        ]),
        throwsArgumentError,
      );
    });
  });

  group('BoltPoint3D', () {
    test('creates 3D point structure', () {
      final point = BoltPoint3D(
        PsInt.compact(4979), // WGS84-3D SRID
        PsFloat(12.345),
        PsFloat(67.890),
        PsFloat(123.456),
      );

      expect(point.numberOfFields, equals(4));
      expect(point.tagByte, equals(0x59));
      expect(point.srid.dartValue, equals(4979));
      expect(point.x.dartValue, equals(12.345));
      expect(point.y.dartValue, equals(67.890));
      expect(point.z.dartValue, equals(123.456));
    });

    test('serializes and deserializes correctly', () {
      final original = BoltPoint3D(
        PsInt.compact(9157), // Cartesian 3D SRID
        PsFloat(1.0),
        PsFloat(2.0),
        PsFloat(3.0),
      );

      final bytes = original.toByteData();
      expect(bytes.getUint8(0), equals(0xB4)); // 4 fields
      expect(bytes.getUint8(1), equals(0x59)); // Point3D tag

      final parsed = PsDataType.fromPackStreamBytes(bytes) as BoltPoint3D;
      expect(parsed.srid.dartValue, equals(9157));
      expect(parsed.x.dartValue, equals(1.0));
      expect(parsed.y.dartValue, equals(2.0));
      expect(parsed.z.dartValue, equals(3.0));
    });

    test('creates from parsed values', () {
      final values = <PsDataType>[
        PsInt.compact(4326), // SRID
        PsFloat(-122.419),
        PsFloat(37.7749),
        PsFloat(52.0), // elevation
      ];

      final point = BoltPoint3D.fromValues(values);
      expect(point.srid.dartValue, equals(4326));
      expect(point.x.dartValue, equals(-122.419));
      expect(point.y.dartValue, equals(37.7749));
      expect(point.z.dartValue, equals(52.0));
    });

    test('throws error for invalid field count', () {
      expect(
        () => BoltPoint3D.fromValues(<PsDataType>[
          PsInt.compact(1),
          PsFloat(1.0),
          PsFloat(2.0),
        ]),
        throwsArgumentError,
      );
    });
  });
}
