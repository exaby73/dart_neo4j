## 1.1.0

### BREAKING CHANGES

- **Static nodeLabel**: `nodeLabel` is now a static const field instead of an instance getter
  - Access via `UserCypher.nodeLabel` instead of `user.nodeLabel`
  - Can be accessed without creating an instance
  - String interpolation in generated methods uses `${nodeLabel}` to reference the static member
- **Record-based cypherPropertyNames**: `cypherPropertyNames` is now a static const Record instead of a getter returning `List<String>`
  - Access via `UserCypher.cypherPropertyNames.fieldName` instead of iterating a list
  - Field names in the record correspond to Dart property names
  - Field values are the Cypher property names
  - Provides type-safe access to property name mappings
  - Example: For a `User` class with `name` and `email` fields:
    ```dart
    // Old: List<String> get cypherPropertyNames => ['name', 'email'];
    // New: static const ({String name, String email}) cypherPropertyNames = (name: 'name', email: 'email');
    ```

### Improvements

- **Better Type Safety**: Record-based property names provide compile-time checking
- **Static Access**: Both `nodeLabel` and `cypherPropertyNames` can now be accessed without instances
- **Improved Performance**: Static const values are more efficient than getters

### Migration Guide

Update code that accesses `nodeLabel` or `cypherPropertyNames`:

```dart
// Before
final user = User(id: CypherId.value(1), name: 'John', email: 'john@example.com');
print(user.nodeLabel);  // 'User'
print(user.cypherPropertyNames);  // ['name', 'email']

// After
print(UserCypher.nodeLabel);  // 'User'
print(UserCypher.cypherPropertyNames.name);  // 'name'
print(UserCypher.cypherPropertyNames.email);  // 'email'
```

## 1.0.0

### BREAKING CHANGES

- **ID Field Validation**: Generator now accepts any field name for ID fields (not just `id`)
  - Fields are identified by type (`CypherId` or `CypherElementId`) rather than name
  - At least one ID field (either type) is required per `@cypherNode` class
  - Only one occurrence of each ID type is allowed per class

### New Features

- **CypherElementId Support**: Full code generation support for `CypherElementId` type
  - Generates `CypherElementId.value(node.elementIdOrThrow)` in `fromNode` factories
  - Supports classes with only `CypherElementId` fields
  - Supports classes with both `CypherId` and `CypherElementId` fields for gradual migration
- **Flexible ID Field Naming**: ID fields can have any name (e.g., `elementId`, `nodeId`, `uid`)
  - Generator identifies ID fields by type, not by field name
  - Enables better semantic naming based on domain requirements
- **Enhanced Validation**: Improved build-time error messages
  - Clear errors if no ID field is present
  - Clear errors if multiple fields of the same ID type exist
  - Helpful suggestions for fixing validation errors

### Improvements

- **Code Quality**: Refactored `isIdField` to be a computed getter, eliminating desync risks
- **Better Field Detection**: Enhanced field analysis for both regular and Freezed classes
- **Comprehensive Tests**: Added test fixtures and tests for all ID type combinations
  - Tests for `CypherId` only (backward compatibility)
  - Tests for `CypherElementId` only (Neo4j 5.0+)
  - Tests for both ID types (migration scenarios)

### Technical Changes

- Updated `FieldInfo` model with `isCypherIdField` and `isCypherElementIdField` properties
- Updated `ClassInfo` model with `hasCypherId` and `hasCypherElementId` properties
- Enhanced `_validateIdField()` to support both ID types with flexible naming
- Updated Jinja template to conditionally generate appropriate ID field assignments
- Refactored `isIdField` from stored field to computed getter for better consistency

### Migration Guide

Classes can now use `CypherElementId` for Neo4j 5.0+ compatibility:

```dart
// Neo4j 5.0+ style (recommended)
@cypherNode
class User {
  final CypherElementId elementId;
  final String name;

  const User({required this.elementId, required this.name});
  factory User.fromNode(Node node) => _$UserFromNode(node);
}

// Hybrid approach (for gradual migration)
@cypherNode
class User {
  final CypherId legacyId;
  final CypherElementId elementId;
  final String name;

  const User({
    required this.legacyId,
    required this.elementId,
    required this.name,
  });
  factory User.fromNode(Node node) => _$UserFromNode(node);
}
```

## 0.2.0

### BREAKING CHANGES

- **CypherId Requirement**: Generator now requires all `@cypherNode` classes to have a `CypherId id` field
- **Build-time Validation**: Added strict validation that fails build if `CypherId id` field is missing
- **fromNode Generation**: Replaced `fromCypherMap` generation with `fromNode` factory generation
- **ID Field Exclusion**: ID fields are automatically excluded from all generated Cypher properties

### New Features

- **fromNode Factory Generation**: Generates static factory methods for creating instances from Neo4j Node objects
  - Extracts ID from `node.id` and maps properties from `node.properties`
  - Handles custom property names via `@CypherProperty(name: 'customName')`
  - Validates required fields and handles nullable properties
  - Generates appropriate error handling for missing properties
- **Enhanced Field Processing**: Improved field analysis and validation
  - Automatic detection and exclusion of ID fields
  - Better handling of ignored fields with `@CypherProperty(ignore: true)`
  - Improved nullable field handling
- **Template Updates**: Updated Jinja templates for new generation patterns
  - New fromNode factory template
  - Updated property generation to exclude ID fields
  - Enhanced error handling in generated code

### Improvements

- **Better Error Messages**: Clear build-time errors for missing CypherId fields
- **Code Quality**: Enhanced generated code with proper type safety
- **Test Coverage**: Updated all test fixtures to use CypherId pattern
- **Documentation**: Added license section to README

### Technical Changes

- Updated `ClassInfo` and `FieldInfo` models for CypherId handling
- Enhanced `AnnotationReader` for better field validation
- Updated all test fixtures to use new CypherId pattern
- Improved integration tests for Node-based workflow

## 0.1.0

- Initial release of dart_neo4j_ogm_generator package
- Added code generator for @cypherNode annotated classes
- Generates Cypher query construction methods using Jinja templates
- Supports field mapping and property customization via @CypherProperty
- Includes integration with build_runner for automatic code generation
