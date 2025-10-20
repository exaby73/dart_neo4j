/// Cypher code generator for Neo4j OGM annotations.
library;

import 'package:analyzer/dart/element/element2.dart';
import 'package:arcade_views/arcade_views.dart';
import 'package:build/build.dart';
import 'package:dart_neo4j_ogm/dart_neo4j_ogm.dart';
import 'package:source_gen/source_gen.dart';

import '../models/class_info.dart';
import '../models/field_info.dart';
import '../utils/annotation_reader.dart';

/// Generator for creating Cypher extension methods from @cypherNode annotations.
class CypherGenerator extends GeneratorForAnnotation<CypherNode> {
  @override
  Future<String> generateForAnnotatedElement(
    Element2 element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    // Validate that the annotation is applied to a class
    if (element is! ClassElement2) {
      throw InvalidGenerationSourceError(
        '@cypherNode can only be applied to classes',
        element: element,
      );
    }

    // Validate that the class has a required CypherId id field
    _validateIdField(element);

    // Extract class metadata
    final classInfo = _extractClassInfo(element, annotation);

    // Get the source file name for the part of directive
    final sourceAsset = buildStep.inputId;
    final fileName = sourceAsset.path.split('/').last;

    // Prepare template data
    final templateData = classInfo.toMap();
    templateData['fileName'] = fileName;
    templateData['hasIgnoredFields'] = classInfo.fields.any(
      (field) => field.isIgnored,
    );

    // Render template using arcade_views
    return view('cypher_extension', templateData, (
      packagePath: 'package:dart_neo4j_ogm_generator/',
      viewsPath: 'views',
    ));
  }

  /// Extracts class information from the annotated element.
  ClassInfo _extractClassInfo(
    ClassElement2 element,
    ConstantReader annotation,
  ) {
    final className = element.name3 ?? 'UnknownClass';
    final label = AnnotationReader.extractLabel(element, annotation);
    final includeFromNode = AnnotationReader.extractIncludeFromNode(annotation);
    final fields = _extractFieldInfo(element);

    // Validate factory constructor if includeFromNode is true
    if (includeFromNode) {
      _validateFromNodeFactory(element, className);
    }

    return ClassInfo(
      className: className,
      label: label,
      fields: fields,
      includeFromNode: includeFromNode,
    );
  }

  /// Validates that the class has a fromNode factory constructor.
  void _validateFromNodeFactory(ClassElement2 element, String className) {
    final constructors = element.constructors2;
    final hasFromNodeFactory = constructors.any(
      (constructor) => constructor.isFactory && constructor.name3 == 'fromNode',
    );

    if (!hasFromNodeFactory) {
      final sampleCode = '''
factory $className.fromNode(Node node) => _\$${className}FromNode(node);''';

      throw InvalidGenerationSourceError(
        'Class $className is missing the required fromNode factory constructor.\n'
        'Add this factory constructor to your class:\n\n'
        '$sampleCode\n\n'
        'Or set includeFromNode: false in the @CypherNode annotation if you don\'t need this functionality.',
        element: element,
      );
    }
  }

  /// Validates that the class has a required CypherId id field.
  void _validateIdField(ClassElement2 element) {
    final processableFields = AnnotationReader.getProcessableFields(element);

    // Check if we have fields available (normal case or after Freezed has run)
    if (processableFields.isNotEmpty) {
      final idField = processableFields
          .where((field) => field.name3 == 'id')
          .firstOrNull;

      if (idField == null) {
        throw InvalidGenerationSourceError(
          'Classes annotated with @cypherNode must have a CypherId id field',
          element: element,
        );
      }

      final idFieldType = idField.type.getDisplayString();
      if (idFieldType != 'CypherId') {
        throw InvalidGenerationSourceError(
          'The id field must be of type CypherId, found: $idFieldType',
          element: element,
        );
      }
    } else {
      // Fallback for Freezed classes - check constructor parameters
      final constructorFieldInfo = AnnotationReader.getFieldInfoFromConstructor(
        element,
      );
      final idFieldData = constructorFieldInfo
          .where((fieldData) => fieldData['name'] == 'id')
          .firstOrNull;

      if (idFieldData == null) {
        throw InvalidGenerationSourceError(
          'Classes annotated with @cypherNode must have a CypherId id field',
          element: element,
        );
      }

      final idFieldType = idFieldData['type'] as String;
      if (idFieldType != 'CypherId') {
        throw InvalidGenerationSourceError(
          'The id field must be of type CypherId, found: $idFieldType',
          element: element,
        );
      }
    }
  }

  /// Extracts field information from the class element.
  List<FieldInfo> _extractFieldInfo(ClassElement2 element) {
    final processableFields = AnnotationReader.getProcessableFields(element);

    // If we have fields on the class (normal case or after Freezed has run)
    if (processableFields.isNotEmpty) {
      return processableFields.map((field) {
        final fieldName = field.name3 ?? 'unknownField';
        final fieldType = field.type.getDisplayString();
        final cypherName = AnnotationReader.getCypherPropertyName(field);
        final isIdField = fieldName == 'id';
        // Id fields are always ignored for Cypher properties, regardless of @CypherProperty annotation
        final isIgnored = isIdField || AnnotationReader.isFieldIgnored(field);

        return FieldInfo(
          name: fieldName,
          type: fieldType,
          cypherName: cypherName,
          isIgnored: isIgnored,
          isIdField: isIdField,
        );
      }).toList();
    }

    // Fallback for Freezed classes where fields might not be available yet
    // Extract field info from constructor parameters
    final constructorFieldInfo = AnnotationReader.getFieldInfoFromConstructor(
      element,
    );

    return constructorFieldInfo.map((fieldData) {
      final fieldName = fieldData['name'] as String;
      final isIdField = fieldName == 'id';
      // Id fields are always ignored for Cypher properties, regardless of @CypherProperty annotation
      final isIgnored = isIdField || (fieldData['isIgnored'] as bool);

      return FieldInfo(
        name: fieldName,
        type: fieldData['type'] as String,
        cypherName: fieldData['cypherName'] as String,
        isIgnored: isIgnored,
        isIdField: isIdField,
      );
    }).toList();
  }
}
