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

  group('Registry-based PackStream Parsing', () {
    test('parses Node structures correctly via registry', () {
      // Create a Node and serialize it
      final original = BoltNode(
        PsInt.compact(42),
        PsList(<PsDataType>[PsString('Person')]),
        PsDictionary({PsString('name'): PsString('Alice')}),
        elementId: PsString('node42'),
      );
      final bytes = original.toByteData();

      // When we parse with PsDataType.fromPackStreamBytes, the registry
      // automatically returns the correct BoltNode type
      final parsed = PsDataType.fromPackStreamBytes(bytes);

      expect(parsed, isA<BoltNode>());
      final node = parsed as BoltNode;
      expect(node.id.dartValue, equals(42));
      expect(node.elementId?.dartValue, equals('node42'));
    });

    test('parses Relationship structures correctly via registry', () {
      final original = BoltRelationship(
        PsInt.compact(100),
        PsInt.compact(1),
        PsInt.compact(2),
        PsString('KNOWS'),
        PsDictionary({PsString('since'): PsInt.compact(2020)}),
        elementId: PsString('rel100'),
        startNodeElementId: PsString('node1'),
        endNodeElementId: PsString('node2'),
      );
      final bytes = original.toByteData();

      final parsed = PsDataType.fromPackStreamBytes(bytes);

      expect(parsed, isA<BoltRelationship>());
      final rel = parsed as BoltRelationship;
      expect(rel.id.dartValue, equals(100));
      expect(rel.elementId?.dartValue, equals('rel100'));
    });

    test('parses UnboundRelationship structures correctly via registry', () {
      final original = BoltUnboundRelationship(
        PsInt.compact(500),
        PsString('CONNECTS'),
        PsDictionary({PsString('weight'): PsInt.compact(5)}),
        elementId: PsString('unbound500'),
      );
      final bytes = original.toByteData();

      final parsed = PsDataType.fromPackStreamBytes(bytes);

      expect(parsed, isA<BoltUnboundRelationship>());
      final unbound = parsed as BoltUnboundRelationship;
      expect(unbound.id.dartValue, equals(500));
      expect(unbound.elementId?.dartValue, equals('unbound500'));
    });

    test('parses Path structures correctly via registry', () {
      final nodes = PsList(<PsDataType>[
        BoltNode(PsInt.compact(1), PsList(<PsDataType>[]), PsDictionary({})),
        BoltNode(PsInt.compact(2), PsList(<PsDataType>[]), PsDictionary({})),
      ]);
      final rels = PsList(<PsDataType>[
        BoltUnboundRelationship(
          PsInt.compact(10),
          PsString('CONNECTS'),
          PsDictionary({}),
        ),
      ]);
      final indices = PsList(<PsDataType>[PsInt.compact(1), PsInt.compact(1)]);

      final original = BoltPath(nodes, rels, indices);
      final bytes = original.toByteData();

      final parsed = PsDataType.fromPackStreamBytes(bytes);

      expect(parsed, isA<BoltPath>());
      final path = parsed as BoltPath;
      expect(path.nodes.value.length, equals(2));
      expect(path.relationships.value.length, equals(1));
    });

    test('parses temporal structures correctly via registry', () {
      // Test Date
      final date = BoltDate(PsInt.compact(18628)); // 2021-01-01
      final dateBytes = date.toByteData();
      final parsedDate = PsDataType.fromPackStreamBytes(dateBytes);
      expect(parsedDate, isA<BoltDate>());

      // Test Time
      final time = BoltTime(PsInt.compact(43200000000000), PsInt.compact(3600));
      final timeBytes = time.toByteData();
      final parsedTime = PsDataType.fromPackStreamBytes(timeBytes);
      expect(parsedTime, isA<BoltTime>());

      // Test DateTime
      final dateTime = BoltDateTime(
        PsInt.compact(1609459200), // 2021-01-01T00:00:00Z
        PsInt.compact(0),
        PsInt.compact(0),
      );
      final dateTimeBytes = dateTime.toByteData();
      final parsedDateTime = PsDataType.fromPackStreamBytes(dateTimeBytes);
      expect(parsedDateTime, isA<BoltDateTime>());
    });

    test('parses spatial structures correctly via registry', () {
      // Test Point2D
      final point2d = BoltPoint2D(
        PsInt.compact(4326), // WGS84
        PsFloat(12.34),
        PsFloat(56.78),
      );
      final point2dBytes = point2d.toByteData();
      final parsedPoint2d = PsDataType.fromPackStreamBytes(point2dBytes);
      expect(parsedPoint2d, isA<BoltPoint2D>());

      // Test Point3D
      final point3d = BoltPoint3D(
        PsInt.compact(4979), // WGS84 3D
        PsFloat(12.34),
        PsFloat(56.78),
        PsFloat(90.12),
      );
      final point3dBytes = point3d.toByteData();
      final parsedPoint3d = PsDataType.fromPackStreamBytes(point3dBytes);
      expect(parsedPoint3d, isA<BoltPoint3D>());
    });

    test('parses legacy structures correctly via registry', () {
      // Test Legacy DateTime
      final legacyDateTime = BoltLegacyDateTime(
        PsInt.compact(1609459200),
        PsInt.compact(0),
        PsInt.compact(0),
      );
      final legacyDateTimeBytes = legacyDateTime.toByteData();
      final parsedLegacyDateTime = PsDataType.fromPackStreamBytes(
        legacyDateTimeBytes,
      );
      expect(parsedLegacyDateTime, isA<BoltLegacyDateTime>());

      // Test Legacy DateTimeZoneId
      final legacyDateTimeZoneId = BoltLegacyDateTimeZoneId(
        PsInt.compact(1609459200),
        PsInt.compact(0),
        PsString('UTC'),
      );
      final legacyDateTimeZoneIdBytes = legacyDateTimeZoneId.toByteData();
      final parsedLegacyDateTimeZoneId = PsDataType.fromPackStreamBytes(
        legacyDateTimeZoneIdBytes,
      );
      expect(parsedLegacyDateTimeZoneId, isA<BoltLegacyDateTimeZoneId>());
    });

    test('registry parsing is type-safe and preserves all data', () {
      // Create a complex nested structure
      final complexNode = BoltNode(
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
          PsString('scores'): PsList(<PsDataType>[
            PsInt.compact(95),
            PsInt.compact(87),
            PsInt.compact(92),
          ]),
          PsString('metadata'): PsDictionary({
            PsString('created'): PsString('2023-01-01'),
            PsString('updated'): PsString('2023-12-31'),
          }),
        }),
        elementId: PsString('node-12345'),
      );

      // Serialize and parse back
      final bytes = complexNode.toByteData();
      final parsed = PsDataType.fromPackStreamBytes(bytes) as BoltNode;

      // Verify all data is preserved with correct types
      expect(parsed.id.dartValue, equals(12345));
      expect(parsed.labels.value.length, equals(3));
      expect((parsed.labels.value[0] as PsString).dartValue, equals('Person'));

      expect(parsed.properties.value.length, equals(5));
      expect(
        (parsed.properties.value[PsString('name')] as PsString).dartValue,
        equals('John Doe'),
      );
      expect(
        (parsed.properties.value[PsString('age')] as PsInt).dartValue,
        equals(30),
      );
      expect(
        (parsed.properties.value[PsString('active')] as PsBoolean).dartValue,
        equals(true),
      );

      final scores = parsed.properties.value[PsString('scores')] as PsList;
      expect(scores.value.length, equals(3));
      expect((scores.value[0] as PsInt).dartValue, equals(95));

      final metadata =
          parsed.properties.value[PsString('metadata')] as PsDictionary;
      expect(metadata.value.length, equals(2));
      expect(
        (metadata.value[PsString('created')] as PsString).dartValue,
        equals('2023-01-01'),
      );

      expect(parsed.elementId?.dartValue, equals('node-12345'));
      expect(parsed.hasElementId, isTrue);
    });
  });
}
