/// Utilities for reading and processing Neo4j OGM annotations.
library;

import 'package:analyzer/dart/element/element2.dart';
import 'package:source_gen/source_gen.dart';

/// Utility class for extracting annotation data from class elements.
class AnnotationReader {
  /// Extracts the label from a @cypherNode annotation.
  /// Returns the annotation label or the class name if no label is specified.
  static String extractLabel(ClassElement2 element, ConstantReader annotation) {
    final labelValue = annotation.peek('label')?.stringValue;
    return labelValue ?? element.name3 ?? 'UnknownClass';
  }

  /// Extracts the includeFromCypherMap flag from a @cypherNode annotation.
  /// Returns true by default if not specified.
  static bool extractIncludeFromCypherMap(ConstantReader annotation) {
    return annotation.peek('includeFromCypherMap')?.boolValue ?? true;
  }

  /// Checks if a field element has a @CypherProperty annotation.
  static bool hasCypherPropertyAnnotation(FieldElement2 field) {
    const cypherPropertyChecker = TypeChecker.fromUrl(
      'package:dart_neo4j_ogm/src/annotations/cypher_property.dart#CypherProperty',
    );
    return cypherPropertyChecker.hasAnnotationOfExact(field);
  }

  /// Extracts CypherProperty annotation data from a field.
  static Map<String, dynamic> extractCypherPropertyData(FieldElement2 field) {
    const cypherPropertyChecker = TypeChecker.fromUrl(
      'package:dart_neo4j_ogm/src/annotations/cypher_property.dart#CypherProperty',
    );
    final annotation = cypherPropertyChecker.firstAnnotationOfExact(field);

    if (annotation == null) {
      return {'ignore': false, 'name': null};
    }

    final reader = ConstantReader(annotation);
    final ignore = reader.peek('ignore')?.boolValue ?? false;
    final name = reader.peek('name')?.stringValue;

    return {'ignore': ignore, 'name': name};
  }

  /// Processes all fields in a class, handling both regular and Freezed classes.
  /// Returns a list of field elements that should be processed for Cypher generation.
  static List<FieldElement2> getProcessableFields(ClassElement2 element) {
    // Get fields directly from the class
    // This works for both regular classes and Freezed classes
    // as Freezed generates the fields on the class itself
    final fields = element.fields2;

    // Remove synthetic and static fields
    final processableFields =
        fields
            .where(
              (field) =>
                  !field.isSynthetic &&
                  !field.isStatic &&
                  !(field.name3?.startsWith('_') ?? false),
            )
            .toList();

    // For Freezed classes, we might also need to check constructor parameters
    // if fields are not yet generated. This handles the case where the generator
    // runs before Freezed has generated all the fields.
    if (processableFields.isEmpty) {
      // Look for factory constructors (typical in Freezed classes)
      final constructors = element.constructors2;
      for (final constructor in constructors) {
        if (constructor.isFactory) {
          // This is likely a Freezed factory constructor
          // The fields should be available on the class itself after Freezed runs
          break;
        }
      }
    }

    return processableFields;
  }

  /// Extracts the Cypher property name for a field.
  /// Uses custom name from @CypherProperty annotation or falls back to field name.
  static String getCypherPropertyName(FieldElement2 field) {
    final annotationData = extractCypherPropertyData(field);
    final customName = annotationData['name'] as String?;
    return customName ?? field.name3 ?? 'unknownField';
  }

  /// Checks if a field should be ignored in Cypher generation.
  static bool isFieldIgnored(FieldElement2 field) {
    final annotationData = extractCypherPropertyData(field);
    return annotationData['ignore'] as bool;
  }

  /// Extracts CypherProperty annotation data from a constructor parameter.
  /// This is useful for Freezed classes where annotations are on constructor parameters.
  static Map<String, dynamic> extractCypherPropertyDataFromParameter(
    FormalParameterElement parameter,
  ) {
    const cypherPropertyChecker = TypeChecker.fromUrl(
      'package:dart_neo4j_ogm/src/annotations/cypher_property.dart#CypherProperty',
    );
    final annotation = cypherPropertyChecker.firstAnnotationOfExact(parameter);

    if (annotation == null) {
      return {'ignore': false, 'name': null};
    }

    final reader = ConstantReader(annotation);
    final ignore = reader.peek('ignore')?.boolValue ?? false;
    final name = reader.peek('name')?.stringValue;

    return {'ignore': ignore, 'name': name};
  }

  /// Gets field information from constructor parameters for Freezed classes.
  /// This is a fallback when fields are not yet available on the class.
  static List<Map<String, dynamic>> getFieldInfoFromConstructor(
    ClassElement2 element,
  ) {
    final fieldInfo = <Map<String, dynamic>>[];

    // Look for factory constructors (typical in Freezed classes)
    final constructors = element.constructors2;
    for (final constructor in constructors) {
      if (constructor.isFactory) {
        for (final parameter in constructor.formalParameters) {
          final paramName = parameter.name3 ?? 'unknownParam';
          final paramType = parameter.type.getDisplayString();
          final annotationData = extractCypherPropertyDataFromParameter(
            parameter,
          );
          final cypherName = (annotationData['name'] as String?) ?? paramName;
          final isIgnored = annotationData['ignore'] as bool;

          fieldInfo.add({
            'name': paramName,
            'type': paramType,
            'cypherName': cypherName,
            'isIgnored': isIgnored,
          });
        }
        break; // Use the first factory constructor found
      }
    }

    return fieldInfo;
  }
}
