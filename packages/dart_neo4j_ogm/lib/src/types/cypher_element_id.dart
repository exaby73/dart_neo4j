/// A type-safe representation of a Cypher node element ID that can be either set or unset.
///
/// This sealed class allows creating nodes without an element ID (before CREATE operations)
/// and accessing the element ID safely after the node has been persisted to Neo4j.
///
/// This is the recommended type for Neo4j 5.0+ which uses string-based element IDs.
/// For legacy integer IDs, see [CypherId].
///
/// ## Usage with json_serializable
///
/// ```dart
/// @freezed
/// @CypherNode()
/// class User with _$User {
///   const factory User({
///     @JsonKey(toJson: cypherElementIdToJson, fromJson: cypherElementIdFromJson) required CypherElementId elementId,
///     required String name,
///     required String email,
///   }) = _User;
///
///   factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
/// }
/// ```
sealed class CypherElementId {
  const CypherElementId._();

  /// Creates a CypherElementId with no value (for new nodes before CREATE).
  const factory CypherElementId.none() = _CypherNoElementId;

  /// Creates a CypherElementId with a specific value (for existing nodes from Neo4j).
  const factory CypherElementId.value(String elementId) = _CypherElementIdValue;

  /// Gets the element ID value or throws if no element ID is set.
  ///
  /// Throws [StateError] if called on a node that hasn't been persisted to Neo4j yet.
  String get elementIdOrThrow => switch (this) {
    _CypherElementIdValue(:final elementId) => elementId,
    _CypherNoElementId() => throw StateError(
      'Cannot access element ID on a node that has not been persisted to Neo4j yet. '
      'Create the node first using a CREATE query.',
    ),
  };

  /// Gets the element ID value or returns null if no element ID is set.
  String? get elementIdOrNull => switch (this) {
    _CypherElementIdValue(:final elementId) => elementId,
    _CypherNoElementId() => null,
  };

  /// Returns true if this CypherElementId has a value.
  bool get hasElementId => switch (this) {
    _CypherElementIdValue() => true,
    _CypherNoElementId() => false,
  };

  /// Returns true if this CypherElementId has no value.
  bool get hasNoElementId => !hasElementId;

  /// Converts this CypherElementId to JSON representation.
  /// Returns the element ID value or null if no element ID is set.
  String? toJson() => elementIdOrNull;

  /// Creates a CypherElementId from JSON representation.
  /// Returns CypherElementId.none() if json is null, otherwise CypherElementId.value(json).
  factory CypherElementId.fromJson(String? json) =>
      json == null ? CypherElementId.none() : CypherElementId.value(json);
}

/// Internal implementation for CypherElementId with a value.
final class _CypherElementIdValue extends CypherElementId {
  const _CypherElementIdValue(this.elementId) : super._();

  final String elementId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CypherElementIdValue &&
          runtimeType == other.runtimeType &&
          elementId == other.elementId;

  @override
  int get hashCode => elementId.hashCode;

  @override
  String toString() => 'CypherElementId.value($elementId)';
}

/// Internal implementation for CypherElementId with no value.
final class _CypherNoElementId extends CypherElementId {
  const _CypherNoElementId() : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CypherNoElementId && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'CypherElementId.none()';
}

/// Top-level helper function for json_serializable toJson conversion.
/// Use with @JsonKey(toJson: cypherElementIdToJson)
String? cypherElementIdToJson(CypherElementId elementId) => elementId.toJson();

/// Top-level helper function for json_serializable fromJson conversion.
/// Use with @JsonKey(fromJson: cypherElementIdFromJson)
CypherElementId cypherElementIdFromJson(String? json) =>
    CypherElementId.fromJson(json);
