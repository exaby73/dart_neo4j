/// Data model for holding class metadata during code generation.
library;

import 'field_info.dart';

/// Holds metadata about a class annotated with @cypherNode.
class ClassInfo {
  const ClassInfo({
    required this.className,
    required this.label,
    required this.fields,
    this.includeFromCypherMap = true,
  });

  /// The name of the annotated class.
  final String className;

  /// The Neo4j node label (from annotation or class name).
  final String label;

  /// List of field information for the class.
  final List<FieldInfo> fields;

  /// Whether to generate the fromCypherMap helper function.
  final bool includeFromCypherMap;

  /// Converts the class info to a map for template rendering.
  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'label': label,
      'fields': fields.map((field) => field.toMap()).toList(),
      'includeFromCypherMap': includeFromCypherMap,
    };
  }
}
