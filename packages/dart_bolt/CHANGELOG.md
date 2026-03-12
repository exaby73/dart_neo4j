## 1.2.2

- Fix byte-ordering in protocol version numbers. Wrap the raw version number using an extension type to provide easier handling of version numbers.
- Added optional `forcedVersions` arguments to enable forcing a connection into using a specific version (vs. the built-in versions officially supported by the driver). This enables integration testing, e.g. forcing a connection to use version 4.4 with a Neo4j 2025 instance.

## 1.2.1

- Version bump for consistency with dart_neo4j ecosystem

## 1.2.0

- Version bump for consistency with dart_neo4j ecosystem

## 1.1.0

- Version bump for consistency with dart_neo4j ecosystem

## 1.0.0

### Stable Release

- First stable release of dart_bolt

## 0.2.0

- Updated Dart SDK requirement to ^3.8.0
- Version bump for consistency with dart_neo4j ecosystem

## 0.1.0

- Updated dart_packstream dependency to ^0.1.0
- Version bump for consistency with dart_neo4j ecosystem

## 0.0.2

- Updated license section in README to correctly reflect GPL-3.0 license

## 0.0.1

- Initial release of dart_bolt package.
