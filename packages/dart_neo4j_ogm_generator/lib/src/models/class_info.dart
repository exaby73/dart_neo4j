/// Data model for holding class metadata during code generation.
library;

import 'field_info.dart';

/// Holds metadata about a class annotated with @cypherNode.
class ClassInfo {
  const ClassInfo({
    required this.className,
    required this.label,
    required this.fields,
    this.includeFromNode = true,
    this.hasCypherId = false,
    this.hasCypherElementId = false,
  });

  /// The name of the annotated class.
  final String className;

  /// The Neo4j node label (from annotation or class name).
  final String label;

  /// List of field information for the class.
  final List<FieldInfo> fields;

  /// Whether to generate the fromNode helper function.
  final bool includeFromNode;

  /// Whether the class has a CypherId field.
  final bool hasCypherId;

  /// Whether the class has a CypherElementId field.
  final bool hasCypherElementId;

  /// Converts the class info to a map for template rendering.
  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'label': label,
      'fields': fields.map((field) => field.toMap()).toList(),
      'includeFromNode': includeFromNode,
      'hasCypherId': hasCypherId,
      'hasCypherElementId': hasCypherElementId,
    };
  }
}
