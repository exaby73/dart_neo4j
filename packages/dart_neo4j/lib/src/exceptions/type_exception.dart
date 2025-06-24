import 'package:dart_neo4j/src/exceptions/neo4j_exception.dart';

/// Exception thrown when type-related errors occur during result processing.
class TypeException extends Neo4jException {
  /// Creates a new type exception.
  const TypeException(super.message, [super.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'TypeException: $message\nCaused by: $cause';
    }
    return 'TypeException: $message';
  }
}

/// Exception thrown when a required field is not found in a record.
class FieldNotFoundException extends TypeException {
  /// The name of the field that was not found.
  final String fieldName;

  /// The available field names in the record.
  final Set<String>? availableFields;

  /// Creates a new field not found exception.
  const FieldNotFoundException(
    this.fieldName, [
    this.availableFields,
    Object? cause,
  ]) : super(
          'Field "$fieldName" not found in record',
          cause,
        );

  @override
  String toString() {
    final buffer = StringBuffer('FieldNotFoundException: Field "$fieldName" not found in record');
    if (availableFields != null && availableFields!.isNotEmpty) {
      buffer.write('\nAvailable fields: ${availableFields!.join(', ')}');
    }
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a field exists but has the wrong type.
class TypeMismatchException extends TypeException {
  /// The name of the field that has the wrong type.
  final String fieldName;

  /// The expected type.
  final Type expectedType;

  /// The actual type.
  final Type actualType;

  /// The actual value that caused the type mismatch.
  final Object? actualValue;

  /// Creates a new type mismatch exception.
  const TypeMismatchException(
    this.fieldName,
    this.expectedType,
    this.actualType, [
    this.actualValue,
    Object? cause,
  ]) : super(
          'Field "$fieldName" expected type $expectedType but got $actualType',
          cause,
        );

  @override
  String toString() {
    final buffer = StringBuffer(
      'TypeMismatchException: Field "$fieldName" expected type $expectedType but got $actualType',
    );
    if (actualValue != null) {
      buffer.write(' (value: $actualValue)');
    }
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a field value is null but a non-null value was expected.
class UnexpectedNullException extends TypeException {
  /// The name of the field that was unexpectedly null.
  final String fieldName;

  /// The expected type.
  final Type expectedType;

  /// Creates a new unexpected null exception.
  const UnexpectedNullException(
    this.fieldName,
    this.expectedType, [
    Object? cause,
  ]) : super(
          'Field "$fieldName" expected non-null $expectedType but got null',
          cause,
        );

  @override
  String toString() {
    final buffer = StringBuffer(
      'UnexpectedNullException: Field "$fieldName" expected non-null $expectedType but got null',
    );
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a value cannot be converted to the requested type.
class ConversionException extends TypeException {
  /// The value that could not be converted.
  final Object? value;

  /// The type that was requested.
  final Type targetType;

  /// Creates a new conversion exception.
  const ConversionException(
    this.value,
    this.targetType, [
    Object? cause,
  ]) : super(
          'Cannot convert value $value to type $targetType',
          cause,
        );

  @override
  String toString() {
    final buffer = StringBuffer('ConversionException: Cannot convert value $value to type $targetType');
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}

/// Exception thrown when attempting to access a field with an invalid index.
class IndexOutOfRangeException extends TypeException {
  /// The index that was out of range.
  final int index;

  /// The valid range.
  final int maxIndex;

  /// Creates a new index out of range exception.
  const IndexOutOfRangeException(
    this.index,
    this.maxIndex, [
    Object? cause,
  ]) : super(
          'Index $index is out of range. Valid range: 0 to $maxIndex',
          cause,
        );

  @override
  String toString() {
    final buffer = StringBuffer('IndexOutOfRangeException: Index $index is out of range. Valid range: 0 to $maxIndex');
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}