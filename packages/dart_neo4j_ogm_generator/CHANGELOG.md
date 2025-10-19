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
