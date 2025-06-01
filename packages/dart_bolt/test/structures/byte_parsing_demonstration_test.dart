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

  group('Byte Parsing Demonstration', () {
    test(
      'PackStream registry automatically returns correct Bolt types from bytes',
      () {
        // This test demonstrates that custom fromPackStreamBytes methods are redundant
        // because the PackStream library's registry system handles this automatically.

        // 1. Create different Bolt structures
        final node = BoltNode(
          PsInt.compact(42),
          PsList(<PsDataType>[PsString('Person')]),
          PsDictionary({PsString('name'): PsString('Alice')}),
          elementId: PsString('node42'),
        );

        final relationship = BoltRelationship(
          PsInt.compact(100),
          PsInt.compact(1),
          PsInt.compact(2),
          PsString('KNOWS'),
          PsDictionary({PsString('since'): PsInt.compact(2020)}),
        );

        final date = BoltDate(PsInt.compact(18628)); // 2021-01-01

        // 2. Serialize them to bytes
        final nodeBytes = node.toByteData();
        final relationshipBytes = relationship.toByteData();
        final dateBytes = date.toByteData();

        // 3. Demonstrate that PsDataType.fromPackStreamBytes() automatically
        //    returns the correct Bolt structure types based on tag bytes
        //    WITHOUT needing custom fromPackStreamBytes methods

        // Node (tag 0x4E) -> BoltNode
        final parsedNode = PsDataType.fromPackStreamBytes(nodeBytes);
        expect(parsedNode, isA<BoltNode>());
        expect(parsedNode.runtimeType, equals(BoltNode));
        final typedNode = parsedNode as BoltNode;
        expect(typedNode.id.dartValue, equals(42));

        // Relationship (tag 0x52) -> BoltRelationship
        final parsedRelationship = PsDataType.fromPackStreamBytes(
          relationshipBytes,
        );
        expect(parsedRelationship, isA<BoltRelationship>());
        expect(parsedRelationship.runtimeType, equals(BoltRelationship));
        final typedRelationship = parsedRelationship as BoltRelationship;
        expect(typedRelationship.id.dartValue, equals(100));

        // Date (tag 0x44) -> BoltDate
        final parsedDate = PsDataType.fromPackStreamBytes(dateBytes);
        expect(parsedDate, isA<BoltDate>());
        expect(parsedDate.runtimeType, equals(BoltDate));
        final typedDate = parsedDate as BoltDate;
        expect(typedDate.days.dartValue, equals(18628));
      },
    );

    test('registry lookup happens automatically based on tag bytes', () {
      // This test shows how the registry works internally

      // 1. Create a structure and serialize it
      final unbound = BoltUnboundRelationship(
        PsInt.compact(500),
        PsString('CONNECTS'),
        PsDictionary({PsString('weight'): PsInt.compact(5)}),
      );
      final bytes = unbound.toByteData();

      // 2. The PackStream library reads the tag byte (0x72 for UnboundRelationship)
      expect(bytes.getUint8(1), equals(0x72)); // Tag byte is at position 1

      // 3. It looks up the registered factory for tag 0x72
      expect(PsStructureRegistry.isRegistered(0x72), isTrue);

      // 4. It calls BoltUnboundRelationship.fromValues() automatically
      final parsed = PsDataType.fromPackStreamBytes(bytes);
      expect(parsed, isA<BoltUnboundRelationship>());
      expect((parsed as BoltUnboundRelationship).id.dartValue, equals(500));
    });

    test('demonstrates why custom fromPackStreamBytes would be redundant', () {
      // If we had a custom fromPackStreamBytes method like this:
      // factory BoltNode.fromPackStreamBytes(ByteData bytes) {
      //   final structure = PsDataType.fromPackStreamBytes(bytes) as PsStructure;
      //   return BoltNode.fromValues(structure.values);
      // }
      //
      // It would be redundant because PsDataType.fromPackStreamBytes(bytes)
      // already returns a BoltNode when the registry is properly set up!

      final original = BoltNode(
        PsInt.compact(999),
        PsList(<PsDataType>[PsString('Test')]),
        PsDictionary({PsString('test'): PsString('value')}),
      );
      final bytes = original.toByteData();

      // The registry-based approach already gives us the right type
      final parsed = PsDataType.fromPackStreamBytes(bytes);
      expect(parsed, isA<BoltNode>());
      expect(parsed.runtimeType, equals(BoltNode));

      // No need for a custom fromPackStreamBytes method!
      final typedParsed = parsed as BoltNode;
      expect(typedParsed.id.dartValue, equals(999));
    });

    test('raw byte parsing without registry would require custom methods', () {
      // This shows when custom fromPackStreamBytes methods would be useful:
      // if we weren't using the registry system

      final node = BoltNode(
        PsInt.compact(123),
        PsList(<PsDataType>[PsString('Example')]),
        PsDictionary({PsString('prop'): PsString('value')}),
      );
      final bytes = node.toByteData();

      // Clear the registry to simulate not having structures registered
      PsStructureRegistry.clear();

      // Now PsDataType.fromPackStreamBytes would throw an error
      expect(() => PsDataType.fromPackStreamBytes(bytes), throwsArgumentError);

      // In this case, we would need custom parsing methods
      // But since we DO use the registry, they're redundant

      // Restore the registry for other tests
      registerBoltStructures();
    });

    test('byte format inspection', () {
      // This test shows the actual byte format to understand how parsing works

      final node = BoltNode(
        PsInt.compact(42),
        PsList(<PsDataType>[PsString('Person')]),
        PsDictionary({PsString('name'): PsString('Alice')}),
      );
      final bytes = node.toByteData();

      // Inspect the byte format
      expect(bytes.getUint8(0), equals(0xB3)); // Structure marker (3 fields)
      expect(bytes.getUint8(1), equals(0x4E)); // Node tag byte ('N')
      // Followed by the serialized field values...

      // The PackStream library uses these bytes to:
      // 1. Recognize it's a structure (0xB3)
      // 2. Determine field count (3)
      // 3. Read tag byte (0x4E)
      // 4. Look up BoltNode.fromValues in registry
      // 5. Parse field values and call the factory
      // 6. Return a BoltNode instance

      final parsed = PsDataType.fromPackStreamBytes(bytes) as BoltNode;
      expect(parsed.id.dartValue, equals(42));
    });
  });
}
