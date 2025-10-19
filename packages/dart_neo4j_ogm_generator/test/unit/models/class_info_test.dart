import 'package:dart_neo4j_ogm_generator/src/models/class_info.dart';
import 'package:dart_neo4j_ogm_generator/src/models/field_info.dart';
import 'package:test/test.dart';

void main() {
  group('ClassInfo', () {
    test('creates instance with required parameters', () {
      const classInfo = ClassInfo(
        className: 'User',
        label: 'Person',
        fields: [],
      );

      expect(classInfo.className, equals('User'));
      expect(classInfo.label, equals('Person'));
      expect(classInfo.fields, isEmpty);
    });

    test('toMap returns correct structure', () {
      const fieldInfo = FieldInfo(
        name: 'id',
        type: 'String',
        cypherName: 'id',
        isIgnored: false,
      );

      const classInfo = ClassInfo(
        className: 'User',
        label: 'Person',
        fields: [fieldInfo],
      );

      final map = classInfo.toMap();

      expect(map['className'], equals('User'));
      expect(map['label'], equals('Person'));
      expect(map['fields'], isA<List>());
      expect(map['fields'], hasLength(1));
      expect(map['fields'][0], isA<Map<String, dynamic>>());
    });

    test('toMap with multiple fields', () {
      const fields = [
        FieldInfo(
          name: 'id',
          type: 'String',
          cypherName: 'id',
          isIgnored: false,
        ),
        FieldInfo(
          name: 'email',
          type: 'String',
          cypherName: 'emailAddress',
          isIgnored: false,
        ),
        FieldInfo(
          name: 'password',
          type: 'String',
          cypherName: 'password',
          isIgnored: true,
        ),
      ];

      const classInfo = ClassInfo(
        className: 'User',
        label: 'Person',
        fields: fields,
      );

      final map = classInfo.toMap();

      expect(map['fields'], hasLength(3));
      expect(map['fields'][0]['name'], equals('id'));
      expect(map['fields'][1]['cypherName'], equals('emailAddress'));
      expect(map['fields'][2]['isIgnored'], isTrue);
    });
  });
}
