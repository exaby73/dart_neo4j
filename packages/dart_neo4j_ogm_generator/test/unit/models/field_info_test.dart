import 'package:dart_neo4j_ogm_generator/src/models/field_info.dart';
import 'package:test/test.dart';

void main() {
  group('FieldInfo', () {
    test('creates instance with required parameters', () {
      const fieldInfo = FieldInfo(
        name: 'id',
        type: 'String',
        cypherName: 'id',
        isIgnored: false,
      );

      expect(fieldInfo.name, equals('id'));
      expect(fieldInfo.type, equals('String'));
      expect(fieldInfo.cypherName, equals('id'));
      expect(fieldInfo.isIgnored, isFalse);
    });

    test('toMap returns correct structure', () {
      const fieldInfo = FieldInfo(
        name: 'email',
        type: 'String',
        cypherName: 'emailAddress',
        isIgnored: false,
      );

      final map = fieldInfo.toMap();

      expect(map['name'], equals('email'));
      expect(map['type'], equals('String'));
      expect(map['cypherName'], equals('emailAddress'));
      expect(map['isIgnored'], isFalse);
    });

    test('toMap with ignored field', () {
      const fieldInfo = FieldInfo(
        name: 'password',
        type: 'String',
        cypherName: 'password',
        isIgnored: true,
      );

      final map = fieldInfo.toMap();

      expect(map['name'], equals('password'));
      expect(map['type'], equals('String'));
      expect(map['cypherName'], equals('password'));
      expect(map['isIgnored'], isTrue);
    });

    test('toMap with nullable type', () {
      const fieldInfo = FieldInfo(
        name: 'name',
        type: 'String?',
        cypherName: 'name',
        isIgnored: false,
      );

      final map = fieldInfo.toMap();

      expect(map['name'], equals('name'));
      expect(map['type'], equals('String?'));
      expect(map['cypherName'], equals('name'));
      expect(map['isIgnored'], isFalse);
    });
  });
}
