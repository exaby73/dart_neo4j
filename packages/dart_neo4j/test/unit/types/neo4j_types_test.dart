import 'package:dart_bolt/dart_bolt.dart';
import 'package:dart_neo4j/src/exceptions/type_exception.dart';
import 'package:dart_neo4j/src/types/neo4j_types.dart';
import 'package:test/test.dart';

void main() {
  group('Neo4j Types', () {
    group('Node', () {
      late BoltNode boltNode;
      late Node node;

      setUp(() {
        boltNode = BoltNode(
          PsInt.compact(123),
          PsList([PsString('Person'), PsString('User')]),
          PsDictionary({
            PsString('name'): PsString('John Doe'),
            PsString('age'): PsInt.compact(30),
            PsString('active'): PsBoolean(true),
          }),
        );
        node = Node.fromBolt(boltNode);
      });

      test('should create node from BoltNode', () {
        expect(node.id, equals(123));
        expect(node.labels, equals(['Person', 'User']));
        expect(node.properties['name'], equals('John Doe'));
        expect(node.properties['age'], equals(30));
        expect(node.properties['active'], equals(true));
      });

      test('should return immutable properties map', () {
        expect(() => node.properties['newKey'] = 'value', throwsUnsupportedError);
      });

      test('should get property by name and type', () {
        expect(node.getProperty<String>('name'), equals('John Doe'));
        expect(node.getProperty<int>('age'), equals(30));
        expect(node.getProperty<bool>('active'), equals(true));
      });

      test('should throw FieldNotFoundException for missing property', () {
        expect(
          () => node.getProperty<String>('missing'),
          throwsA(isA<FieldNotFoundException>()),
        );
      });

      test('should throw TypeMismatchException for wrong type', () {
        expect(
          () => node.getProperty<int>('name'), // name is String, not int
          throwsA(isA<TypeMismatchException>()),
        );
      });

      test('should return null for missing property with getPropertyOrNull', () {
        expect(node.getPropertyOrNull<String>('missing'), isNull);
      });

      test('should return null for wrong type with getPropertyOrNull', () {
        expect(node.getPropertyOrNull<int>('name'), isNull);
      });

      test('should check if property exists', () {
        expect(node.hasProperty('name'), isTrue);
        expect(node.hasProperty('missing'), isFalse);
      });

      test('should check if node has label', () {
        expect(node.hasLabel('Person'), isTrue);
        expect(node.hasLabel('User'), isTrue);
        expect(node.hasLabel('Admin'), isFalse);
      });

      test('should have proper string representation', () {
        final str = node.toString();
        expect(str, contains('Node'));
        expect(str, contains('123'));
        expect(str, contains('Person'));
        expect(str, contains('User'));
      });

      test('should be equal when same ID', () {
        final boltNode2 = BoltNode(
          PsInt.compact(123),
          PsList([PsString('Different')]),
          PsDictionary({PsString('different'): PsString('properties')}),
        );
        final node2 = Node.fromBolt(boltNode2);
        
        expect(node, equals(node2));
        expect(node.hashCode, equals(node2.hashCode));
      });

      test('should not be equal when different ID', () {
        final boltNode2 = BoltNode(
          PsInt.compact(456),
          PsList([PsString('Person')]),
          PsDictionary({PsString('name'): PsString('John Doe')}),
        );
        final node2 = Node.fromBolt(boltNode2);
        
        expect(node, isNot(equals(node2)));
      });
    });

    group('Relationship', () {
      late BoltRelationship boltRelationship;
      late Relationship relationship;

      setUp(() {
        boltRelationship = BoltRelationship(
          PsInt.compact(456),
          PsInt.compact(123),
          PsInt.compact(789),
          PsString('KNOWS'),
          PsDictionary({
            PsString('since'): PsInt.compact(2020),
            PsString('weight'): PsFloat(0.8),
          }),
        );
        relationship = Relationship.fromBolt(boltRelationship);
      });

      test('should create relationship from BoltRelationship', () {
        expect(relationship.id, equals(456));
        expect(relationship.startNodeId, equals(123));
        expect(relationship.endNodeId, equals(789));
        expect(relationship.type, equals('KNOWS'));
        expect(relationship.properties['since'], equals(2020));
        expect(relationship.properties['weight'], equals(0.8));
      });

      test('should return immutable properties map', () {
        expect(() => relationship.properties['newKey'] = 'value', throwsUnsupportedError);
      });

      test('should get property by name and type', () {
        expect(relationship.getProperty<int>('since'), equals(2020));
        expect(relationship.getProperty<double>('weight'), equals(0.8));
      });

      test('should throw FieldNotFoundException for missing property', () {
        expect(
          () => relationship.getProperty<String>('missing'),
          throwsA(isA<FieldNotFoundException>()),
        );
      });

      test('should return null for missing property with getPropertyOrNull', () {
        expect(relationship.getPropertyOrNull<String>('missing'), isNull);
      });

      test('should check if property exists', () {
        expect(relationship.hasProperty('since'), isTrue);
        expect(relationship.hasProperty('missing'), isFalse);
      });

      test('should have proper string representation', () {
        final str = relationship.toString();
        expect(str, contains('Relationship'));
        expect(str, contains('456'));
        expect(str, contains('KNOWS'));
        expect(str, contains('123'));
        expect(str, contains('789'));
      });

      test('should be equal when same ID', () {
        final boltRel2 = BoltRelationship(
          PsInt.compact(456),
          PsInt.compact(999),
          PsInt.compact(888),
          PsString('DIFFERENT'),
          PsDictionary({}),
        );
        final rel2 = Relationship.fromBolt(boltRel2);
        
        expect(relationship, equals(rel2));
        expect(relationship.hashCode, equals(rel2.hashCode));
      });
    });

    group('UnboundRelationship', () {
      late BoltUnboundRelationship boltUnboundRelationship;
      late UnboundRelationship unboundRelationship;

      setUp(() {
        boltUnboundRelationship = BoltUnboundRelationship(
          PsInt.compact(456),
          PsString('KNOWS'),
          PsDictionary({
            PsString('since'): PsInt.compact(2020),
            PsString('strength'): PsString('strong'),
          }),
        );
        unboundRelationship = UnboundRelationship.fromBolt(boltUnboundRelationship);
      });

      test('should create unbound relationship from BoltUnboundRelationship', () {
        expect(unboundRelationship.id, equals(456));
        expect(unboundRelationship.type, equals('KNOWS'));
        expect(unboundRelationship.properties['since'], equals(2020));
        expect(unboundRelationship.properties['strength'], equals('strong'));
      });

      test('should get property by name and type', () {
        expect(unboundRelationship.getProperty<int>('since'), equals(2020));
        expect(unboundRelationship.getProperty<String>('strength'), equals('strong'));
      });

      test('should have proper string representation', () {
        final str = unboundRelationship.toString();
        expect(str, contains('UnboundRelationship'));
        expect(str, contains('456'));
        expect(str, contains('KNOWS'));
      });
    });

    group('Path', () {
      late BoltPath boltPath;
      late Path path;

      setUp(() {
        final node1 = BoltNode(PsInt.compact(1), PsList([PsString('Person')]), PsDictionary({PsString('name'): PsString('Alice')}));
        final node2 = BoltNode(PsInt.compact(2), PsList([PsString('Person')]), PsDictionary({PsString('name'): PsString('Bob')}));
        final node3 = BoltNode(PsInt.compact(3), PsList([PsString('Person')]), PsDictionary({PsString('name'): PsString('Charlie')}));
        
        final rel1 = BoltUnboundRelationship(PsInt.compact(10), PsString('KNOWS'), PsDictionary({}));
        final rel2 = BoltUnboundRelationship(PsInt.compact(20), PsString('WORKS_WITH'), PsDictionary({}));

        boltPath = BoltPath(
          PsList([node1, node2, node3]),
          PsList([rel1, rel2]),
          PsList([PsInt.compact(1), PsInt.compact(2)]),
        );
        path = Path.fromBolt(boltPath);
      });

      test('should create path from BoltPath', () {
        expect(path.nodes.length, equals(3));
        expect(path.relationships.length, equals(2));
        expect(path.length, equals(2));
      });

      test('should return immutable nodes and relationships lists', () {
        expect(() => path.nodes.add(path.nodes.first), throwsUnsupportedError);
        expect(() => path.relationships.add(path.relationships.first), throwsUnsupportedError);
      });

      test('should have correct path properties', () {
        expect(path.isEmpty, isFalse);
        expect(path.isNotEmpty, isTrue);
        expect(path.start?.id, equals(1));
        expect(path.end?.id, equals(3));
      });

      test('should handle empty path', () {
        final emptyPath = BoltPath(PsList([]), PsList([]), PsList([]));
        final path = Path.fromBolt(emptyPath);
        
        expect(path.isEmpty, isTrue);
        expect(path.isNotEmpty, isFalse);
        expect(path.start, isNull);
        expect(path.end, isNull);
        expect(path.length, equals(0));
      });

      test('should have proper string representation', () {
        final str = path.toString();
        expect(str, contains('Path'));
        expect(str, contains('2')); // length
        expect(str, contains('3')); // nodes count
        expect(str, contains('2')); // relationships count
      });

      test('should be equal when same structure', () {
        final path2 = Path.fromBolt(boltPath);
        expect(path, equals(path2));
        expect(path.hashCode, equals(path2.hashCode));
      });
    });
  });
}