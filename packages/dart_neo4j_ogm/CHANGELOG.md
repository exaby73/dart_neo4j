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
