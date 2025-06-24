import 'package:dart_bolt/dart_bolt.dart';
import 'package:dart_neo4j/src/exceptions/type_exception.dart';
import 'package:dart_neo4j/src/result/record.dart';
import 'package:dart_neo4j/src/types/neo4j_types.dart';
import 'package:test/test.dart';

void main() {
  group('Record', () {
    late Record record;

    setUp(() {
      final keys = ['name', 'age', 'active', 'score', 'tags', 'profile'];
      final values = <PsDataType>[
        PsString('John Doe'),
        PsInt.compact(30),
        PsBoolean(true),
        PsFloat(95.5),
        PsList([PsString('developer'), PsString('cyclist')]),
        PsDictionary({
          PsString('city'): PsString('New York'),
          PsString('country'): PsString('USA'),
        }),
      ];
      record = Record.fromBolt(keys, values);
    });

    group('basic functionality', () {
      test('should create record from keys and values', () {
        expect(
          record.keys,
          equals(['name', 'age', 'active', 'score', 'tags', 'profile']),
        );
        expect(record.length, equals(6));
        expect(record.isEmpty, isFalse);
        expect(record.isNotEmpty, isTrue);
      });

      test('should return immutable keys and values', () {
        expect(() => record.keys.add('newKey'), throwsUnsupportedError);
        expect(() => record.values.add('newValue'), throwsUnsupportedError);
      });

      test('should throw ArgumentError for mismatched keys and values', () {
        expect(
          () => Record.fromBolt(
            ['key1'],
            [PsString('value1'), PsString('value2')],
          ),
          throwsArgumentError,
        );
      });

      test('should access fields by index', () {
        expect(record[0], equals('John Doe'));
        expect(record[1], equals(30));
        expect(record[2], equals(true));
      });

      test('should throw RangeError for invalid index', () {
        expect(() => record[10], throwsRangeError);
        expect(() => record[-1], throwsRangeError);
      });

      test('should check if field exists', () {
        expect(record.containsKey('name'), isTrue);
        expect(record.containsKey('missing'), isFalse);
      });

      test('should get field value by key', () {
        expect(record.get('name'), equals('John Doe'));
        expect(record.get('age'), equals(30));
        expect(record.get('active'), equals(true));
      });

      test('should throw FieldNotFoundException for missing key', () {
        expect(
          () => record.get('missing'),
          throwsA(isA<FieldNotFoundException>()),
        );
      });
    });

    group('type-safe getters', () {
      test('should get string values', () {
        expect(record.getString('name'), equals('John Doe'));
      });

      test('should get string or null', () {
        expect(record.getStringOrNull('name'), equals('John Doe'));
        expect(record.getStringOrNull('missing'), isNull);
        expect(record.getStringOrNull('age'), isNull); // wrong type
      });

      test('should get int values', () {
        expect(record.getInt('age'), equals(30));
      });

      test('should get int or null', () {
        expect(record.getIntOrNull('age'), equals(30));
        expect(record.getIntOrNull('missing'), isNull);
        expect(record.getIntOrNull('name'), isNull); // wrong type
      });

      test('should get bool values', () {
        expect(record.getBool('active'), equals(true));
      });

      test('should get bool or null', () {
        expect(record.getBoolOrNull('active'), equals(true));
        expect(record.getBoolOrNull('missing'), isNull);
        expect(record.getBoolOrNull('name'), isNull); // wrong type
      });

      test('should get double values', () {
        expect(record.getDouble('score'), equals(95.5));
      });

      test('should get double or null', () {
        expect(record.getDoubleOrNull('score'), equals(95.5));
        expect(record.getDoubleOrNull('missing'), isNull);
        expect(record.getDoubleOrNull('name'), isNull); // wrong type
      });

      test('should get num values (int or double)', () {
        expect(record.getNum('age'), equals(30));
        expect(record.getNum('score'), equals(95.5));
      });

      test('should get num or null', () {
        expect(record.getNumOrNull('age'), equals(30));
        expect(record.getNumOrNull('score'), equals(95.5));
        expect(record.getNumOrNull('missing'), isNull);
        expect(record.getNumOrNull('name'), isNull); // wrong type
      });

      test('should get list values', () {
        final tags = record.getList('tags');
        expect(tags, equals(['developer', 'cyclist']));
      });

      test('should get list or null', () {
        expect(record.getListOrNull('tags'), equals(['developer', 'cyclist']));
        expect(record.getListOrNull('missing'), isNull);
        expect(record.getListOrNull('name'), isNull); // wrong type
      });

      test('should get map values', () {
        final profile = record.getMap('profile');
        expect(profile, equals({'city': 'New York', 'country': 'USA'}));
      });

      test('should get map or null', () {
        expect(
          record.getMapOrNull('profile'),
          equals({'city': 'New York', 'country': 'USA'}),
        );
        expect(record.getMapOrNull('missing'), isNull);
        expect(record.getMapOrNull('name'), isNull); // wrong type
      });

      test('should throw TypeMismatchException for wrong type', () {
        expect(
          () => record.getString('age'), // age is int, not string
          throwsA(isA<TypeMismatchException>()),
        );

        expect(
          () => record.getInt('name'), // name is string, not int
          throwsA(isA<TypeMismatchException>()),
        );
      });

      test('should throw FieldNotFoundException for missing field', () {
        expect(
          () => record.getString('missing'),
          throwsA(isA<FieldNotFoundException>()),
        );
      });
    });

    group('Neo4j type getters', () {
      late Record recordWithNeo4jTypes;

      setUp(() {
        final node = BoltNode(
          PsInt.compact(1),
          PsList([PsString('Person')]),
          PsDictionary({PsString('name'): PsString('Alice')}),
        );
        final relationship = BoltRelationship(
          PsInt.compact(2),
          PsInt.compact(1),
          PsInt.compact(3),
          PsString('KNOWS'),
          PsDictionary({PsString('since'): PsInt.compact(2020)}),
        );
        final unboundRel = BoltUnboundRelationship(
          PsInt.compact(4),
          PsString('LIKES'),
          PsDictionary({PsString('rating'): PsInt.compact(5)}),
        );
        final path = BoltPath(
          PsList([node]),
          PsList([unboundRel]),
          PsList([PsInt.compact(1)]),
        );

        final keys = ['person', 'knows', 'likes', 'journey'];
        final values = [node, relationship, unboundRel, path];
        recordWithNeo4jTypes = Record.fromBolt(keys, values);
      });

      test('should get Node values', () {
        final node = recordWithNeo4jTypes.getNode('person');
        expect(node.id, equals(1));
        expect(node.labels, contains('Person'));
      });

      test('should get Node or null', () {
        expect(recordWithNeo4jTypes.getNodeOrNull('person'), isA<Node>());
        expect(recordWithNeo4jTypes.getNodeOrNull('missing'), isNull);
        expect(
          recordWithNeo4jTypes.getNodeOrNull('knows'),
          isNull,
        ); // wrong type
      });

      test('should get Relationship values', () {
        final rel = recordWithNeo4jTypes.getRelationship('knows');
        expect(rel.id, equals(2));
        expect(rel.type, equals('KNOWS'));
      });

      test('should get Relationship or null', () {
        expect(
          recordWithNeo4jTypes.getRelationshipOrNull('knows'),
          isA<Relationship>(),
        );
        expect(recordWithNeo4jTypes.getRelationshipOrNull('missing'), isNull);
        expect(
          recordWithNeo4jTypes.getRelationshipOrNull('person'),
          isNull,
        ); // wrong type
      });

      test('should get UnboundRelationship values', () {
        final rel = recordWithNeo4jTypes.getUnboundRelationship('likes');
        expect(rel.id, equals(4));
        expect(rel.type, equals('LIKES'));
      });

      test('should get UnboundRelationship or null', () {
        expect(
          recordWithNeo4jTypes.getUnboundRelationshipOrNull('likes'),
          isA<UnboundRelationship>(),
        );
        expect(
          recordWithNeo4jTypes.getUnboundRelationshipOrNull('missing'),
          isNull,
        );
        expect(
          recordWithNeo4jTypes.getUnboundRelationshipOrNull('person'),
          isNull,
        ); // wrong type
      });

      test('should get Path values', () {
        final path = recordWithNeo4jTypes.getPath('journey');
        expect(path.nodes.length, equals(1));
        expect(path.relationships.length, equals(1));
      });

      test('should get Path or null', () {
        expect(recordWithNeo4jTypes.getPathOrNull('journey'), isA<Path>());
        expect(recordWithNeo4jTypes.getPathOrNull('missing'), isNull);
        expect(
          recordWithNeo4jTypes.getPathOrNull('person'),
          isNull,
        ); // wrong type
      });
    });

    group('convenience methods', () {
      test('should convert to map', () {
        final map = record.asMap();
        expect(map['name'], equals('John Doe'));
        expect(map['age'], equals(30));
        expect(map['active'], equals(true));
        expect(map.length, equals(6));
      });

      test('should return immutable map from asMap', () {
        final map = record.asMap();
        expect(() => map['newKey'] = 'value', throwsUnsupportedError);
      });

      test('should have proper string representation', () {
        final str = record.toString();
        expect(str, contains('Record'));
        expect(str, contains('6')); // length
      });

      test('should be equal when same keys and values', () {
        final keys = ['name', 'age'];
        final values = <PsDataType>[PsString('John'), PsInt.compact(25)];
        final record1 = Record.fromBolt(keys, values);
        final record2 = Record.fromBolt(keys, values);

        expect(record1, equals(record2));
        expect(record1.hashCode, equals(record2.hashCode));
      });

      test('should not be equal when different values', () {
        final record1 = Record.fromBolt(['name'], [PsString('John')]);
        final record2 = Record.fromBolt(['name'], [PsString('Jane')]);

        expect(record1, isNot(equals(record2)));
      });
    });

    group('edge cases', () {
      test('should handle empty record', () {
        final emptyRecord = Record.fromBolt([], []);
        expect(emptyRecord.isEmpty, isTrue);
        expect(emptyRecord.length, equals(0));
        expect(emptyRecord.keys, isEmpty);
        expect(emptyRecord.values, isEmpty);
      });

      test('should handle null values', () {
        final recordWithNull = Record.fromBolt(['nullable'], [const PsNull()]);
        expect(recordWithNull.get('nullable'), isNull);
        expect(recordWithNull.getStringOrNull('nullable'), isNull);
        expect(recordWithNull.getIntOrNull('nullable'), isNull);
      });

      test('should handle complex nested structures', () {
        final complexValue = PsDictionary({
          PsString('nested'): PsList([
            PsDictionary({PsString('deep'): PsString('value')}),
            PsInt.compact(42),
          ]),
        });

        final complexRecord = Record.fromBolt(['complex'], [complexValue]);
        final result = complexRecord.getMap('complex');
        expect(result['nested'], isA<List>());
      });
    });
  });
}
