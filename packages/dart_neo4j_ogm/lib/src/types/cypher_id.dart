/// A type-safe representation of a Cypher node ID that can be either set or unset.
///
/// This sealed class allows creating nodes without an ID (before CREATE operations)
/// and accessing the ID safely after the node has been persisted to Neo4j.
///
/// ## Usage with json_serializable
///
/// ```dart
/// @freezed
/// @CypherNode()
/// class User with _$User {
///   const factory User({
///     @JsonKey(toJson: cypherIdToJson, fromJson: cypherIdFromJson) required CypherId id,
///     required String name,
///     required String email,
///   }) = _User;
///
///   factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
/// }
/// ```
sealed class CypherId {
  const CypherId._();

  /// Creates a CypherId with no value (for new nodes before CREATE).
  factory CypherId.none() => const _CypherNoId();

  /// Creates a CypherId with a specific value (for existing nodes from Neo4j).
  factory CypherId.value(int id) => _CypherIdValue(id);

  /// Gets the ID value or throws if no ID is set.
  ///
  /// Throws [StateError] if called on a node that hasn't been persisted to Neo4j yet.
  int get idOrThrow => switch (this) {
    _CypherIdValue(:final id) => id,
    _CypherNoId() => throw StateError(
      'Cannot access ID on a node that has not been persisted to Neo4j yet. '
      'Create the node first using a CREATE query.',
    ),
  };

  /// Gets the ID value or returns null if no ID is set.
  int? get idOrNull => switch (this) {
    _CypherIdValue(:final id) => id,
    _CypherNoId() => null,
  };

  /// Returns true if this CypherId has a value.
  bool get hasId => switch (this) {
    _CypherIdValue() => true,
    _CypherNoId() => false,
  };

  /// Returns true if this CypherId has no value.
  bool get hasNoId => !hasId;

  /// Converts this CypherId to JSON representation.
  /// Returns the ID value or null if no ID is set.
  int? toJson() => idOrNull;

  /// Creates a CypherId from JSON representation.
  /// Returns CypherId.none() if json is null, otherwise CypherId.value(json).
  factory CypherId.fromJson(int? json) =>
      json == null ? CypherId.none() : CypherId.value(json);
}

/// Internal implementation for CypherId with a value.
final class _CypherIdValue extends CypherId {
  const _CypherIdValue(this.id) : super._();

  final int id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CypherIdValue &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CypherId.value($id)';
}

/// Internal implementation for CypherId with no value.
final class _CypherNoId extends CypherId {
  const _CypherNoId() : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CypherNoId && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'CypherId.none()';
}

/// Top-level helper function for json_serializable toJson conversion.
/// Use with @JsonKey(toJson: cypherIdToJson)
int? cypherIdToJson(CypherId id) => id.toJson();

/// Top-level helper function for json_serializable fromJson conversion.
/// Use with @JsonKey(fromJson: cypherIdFromJson)
CypherId cypherIdFromJson(int? json) => CypherId.fromJson(json);
