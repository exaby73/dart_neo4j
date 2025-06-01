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

  group('BoltPath', () {
    test('creates path structure', () {
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

      final path = BoltPath(nodes, rels, indices);

      expect(path.numberOfFields, equals(3));
      expect(path.tagByte, equals(0x50));
      expect(path.nodes.value.length, equals(2));
      expect(path.relationships.value.length, equals(1));
      expect(path.indices.value.length, equals(2));
    });

    test('serializes and deserializes correctly', () {
      final nodes = PsList(<PsDataType>[
        BoltNode(
          PsInt.compact(1),
          PsList(<PsDataType>[PsString('A')]),
          PsDictionary({}),
        ),
        BoltNode(
          PsInt.compact(2),
          PsList(<PsDataType>[PsString('B')]),
          PsDictionary({}),
        ),
      ]);
      final rels = PsList(<PsDataType>[
        BoltUnboundRelationship(
          PsInt.compact(20),
          PsString('TO'),
          PsDictionary({}),
        ),
      ]);
      final indices = PsList(<PsDataType>[PsInt.compact(1), PsInt.compact(1)]);

      final original = BoltPath(nodes, rels, indices);

      final bytes = original.toByteData();
      expect(bytes.getUint8(0), equals(0xB3)); // 3 fields
      expect(bytes.getUint8(1), equals(0x50)); // Path tag

      final parsed = PsDataType.fromPackStreamBytes(bytes) as BoltPath;
      expect(parsed.nodes.value.length, equals(2));
      expect(parsed.relationships.value.length, equals(1));
    });

    test('creates from parsed values', () {
      final nodeValues = <PsDataType>[
        BoltNode(PsInt.compact(3), PsList(<PsDataType>[]), PsDictionary({})),
        BoltNode(PsInt.compact(4), PsList(<PsDataType>[]), PsDictionary({})),
      ];
      final relValues = <PsDataType>[
        BoltUnboundRelationship(
          PsInt.compact(30),
          PsString('LINKS'),
          PsDictionary({}),
        ),
      ];
      final indexValues = <PsDataType>[PsInt.compact(1), PsInt.compact(1)];

      final values = <PsDataType>[
        PsList(nodeValues),
        PsList(relValues),
        PsList(indexValues),
      ];

      final path = BoltPath.fromValues(values);
      expect(path.nodes.value.length, equals(2));
      expect(path.relationships.value.length, equals(1));
      expect(path.indices.value.length, equals(2));
    });

    test('throws error for invalid field count', () {
      expect(
        () => BoltPath.fromValues(<PsDataType>[
          PsList(<PsDataType>[]),
          PsList(<PsDataType>[]),
        ]),
        throwsArgumentError,
      );
    });
  });
}
