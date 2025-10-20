## 1.1.0

- Version bump for consistency with dart_neo4j ecosystem

## 1.0.0

### BREAKING CHANGES

- **Deprecated `id` Property**: The numeric `id` property on `Node`, `Relationship`, and `UnboundRelationship` is now deprecated in favor of `elementId`
  - Use `elementId` (nullable) or `elementIdOrThrow` (non-nullable) for Neo4j 5.0+ compatibility
  - The old `id` property will continue to work but will emit deprecation warnings
  - See [Neo4j documentation](https://neo4j.com/docs/cypher-manual/5/functions/scalar/#functions-id) for migration guidance

### New Features

- **Neo4j 5.0+ Element ID Support**: Added full support for string-based element IDs
  - `Node.elementId`: Returns the element ID as a nullable String
  - `Node.elementIdOrThrow`: Returns the element ID or throws if not available
  - `Relationship.elementId`: Returns the relationship element ID as a nullable String
  - `Relationship.elementIdOrThrow`: Returns the relationship element ID or throws if not available
  - `UnboundRelationship.elementId`: Returns the relationship element ID as a nullable String
  - `UnboundRelationship.elementIdOrThrow`: Returns the relationship element ID or throws if not available
- **Improved Equality Comparisons**: Node and Relationship equality now prefers `elementId` when available, falling back to numeric `id` for backward compatibility
- **Enhanced toString**: Node, Relationship, and UnboundRelationship now include `elementId` in their string representations when available

### Improvements

- **Future-Proof Design**: Smooth migration path from numeric IDs to element IDs
- **Backward Compatibility**: Existing code using numeric IDs continues to work with deprecation warnings
- **Comprehensive Test Coverage**: Added extensive tests for element ID functionality

## 0.2.0

- Updated Dart SDK requirement to ^3.8.0
- Version bump for consistency with dart_neo4j ecosystem

## 0.1.0

- Fixed handling of multiple node returns in Cypher queries (RETURN a, b syntax)
- Improved Record.fromBolt to properly handle BoltNode, BoltRelationship, and BoltUnboundRelationship structures
- Enhanced BoltConnection to preserve Bolt structures in record data

## 0.0.2

- Updated license section in README to correctly reflect GPL-3.0 license

## 0.0.1

- Initial release of dart_neo4j package.
