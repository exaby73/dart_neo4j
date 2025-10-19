/// Builder configuration for the Neo4j OGM code generator.
library;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generators/cypher_generator.dart';

/// Creates a builder for generating Cypher extensions from annotated classes.
Builder cypherGeneratorBuilder(BuilderOptions options) {
  return LibraryBuilder(CypherGenerator(), generatedExtension: '.cypher.dart');
}
