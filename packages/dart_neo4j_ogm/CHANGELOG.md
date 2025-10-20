## 1.1.0+1

- Refactored `CypherElementId` and `CypherId` to use const factories

## 1.1.0

### Notes

- Version bump for compatibility with dart_neo4j_ogm_generator 1.1.0
- No changes to annotations or API
- Generated code from dart_neo4j_ogm_generator 1.1.0 includes breaking changes:
  - `nodeLabel` is now static const (access via `ClassNameCypher.nodeLabel`)
  - `cypherPropertyNames` is now a static const Record type

## 1.0.0

### BREAKING CHANGES

- **Deprecated `CypherId`**: The `CypherId` type is now deprecated in favor of `CypherElementId` for Neo4j 5.0+ compatibility
  - Use `CypherElementId` for new code targeting Neo4j 5.0+
  - Existing code using `CypherId` will continue to work but will emit deprecation warnings
  - Both types can coexist in the same class during migration

### New Features

- **CypherElementId Type**: Added type-safe `CypherElementId` sealed class for Neo4j 5.0+ string-based element IDs
  - `CypherElementId.none()` for new nodes without element IDs
  - `CypherElementId.value(String)` for existing nodes with Neo4j-generated element IDs
  - Built-in JSON serialization support with `cypherElementIdToJson` and `cypherElementIdFromJson` helpers
  - Same API surface as `CypherId` for easy migration
  - Supports nullable element IDs with `elementIdOrNull` and `hasNoElementId` properties
- **Dual ID Support**: Classes can now have both `CypherId` and `CypherElementId` fields for gradual migration
- **Enhanced Type Safety**: String-based element IDs provide better type checking and Neo4j 5.0+ compatibility

### Improvements

- **Smooth Migration Path**: Deprecation warnings guide users to migrate at their own pace
- **Backward Compatibility**: Existing `CypherId` code continues to work without changes

### Deprecations

- `CypherId` class - Use `CypherElementId` instead
- `cypherIdToJson()` helper - Use `cypherElementIdToJson()` instead
- `cypherIdFromJson()` helper - Use `cypherElementIdFromJson()` instead

## 0.2.0

### BREAKING CHANGES

- **Mandatory CypherId ID Fields**: All `@cypherNode` classes now require a `CypherId id` field instead of `int` or `String`
- **Removed fromCypherMap**: Replaced `fromCypherMap` factory with `fromNode` factory for Neo4j Node integration
- **Automatic ID Exclusion**: ID fields are now automatically excluded from Cypher properties regardless of annotations

### New Features

- **CypherId Type**: Added type-safe `CypherId` sealed class for handling Neo4j node identities
  - `CypherId.none()` for new nodes without IDs
  - `CypherId.value(int)` for existing nodes with Neo4j-generated IDs
  - Built-in JSON serialization support with `cypherIdToJson` and `cypherIdFromJson` helpers
- **fromNode Factory**: New factory method for creating instances from Neo4j `Node` objects
  - Extracts ID from `node.id` and properties from `node.properties`
  - Handles property mapping and type conversion automatically
  - Validates required fields and handles nullable properties
- **Enhanced JSON Support**: Full integration with json_serializable for dual JSON/Cypher serialization

### Improvements

- **Better Documentation**: Comprehensive README with examples, API reference, and integration guides
- **Freezed + JSON Integration**: Complete examples for using Freezed with json_serializable
- **Error Handling**: Improved error messages and validation for missing required fields
- **Type Safety**: Enhanced compile-time type checking with CypherId system

### Documentation

- Added mandatory ID field requirements section
- Added complete Neo4j integration examples
- Added JSON serialization examples with Freezed
- Updated all code examples to use CypherId
- Added fromNode factory usage documentation
- Corrected license information (GPL v3.0)

## 0.1.0

- Initial release of dart_neo4j_ogm package
- Added @cypherNode annotation for marking classes for OGM code generation
- Added @CypherProperty annotation for controlling field-level Cypher generation behavior
