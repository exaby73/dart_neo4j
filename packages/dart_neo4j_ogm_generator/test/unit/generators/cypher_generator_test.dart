import 'package:dart_neo4j_ogm_generator/src/generators/cypher_generator.dart';
import 'package:test/test.dart';

void main() {
  group('CypherGenerator', () {
    late CypherGenerator generator;

    setUp(() {
      generator = CypherGenerator();
    });

    test('can be instantiated', () {
      expect(generator, isA<CypherGenerator>());
    });

    // Note: Full integration testing of generateForAnnotatedElement
    // is better handled by build_test in the build tests
  });
}
