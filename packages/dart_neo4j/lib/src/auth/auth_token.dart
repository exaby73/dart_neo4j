/// Base class for authentication tokens used to connect to Neo4j.
abstract class AuthToken {
  /// The authentication scheme.
  String get scheme;

  /// The principal (username) for authentication.
  String? get principal;

  /// Additional properties for the authentication token.
  Map<String, Object> get properties;

  /// Creates authentication data for the Bolt HELLO message.
  Map<String, Object> toAuthData() {
    final data = <String, Object>{'scheme': scheme};

    if (principal != null) {
      data['principal'] = principal!;
    }

    data.addAll(properties);
    return data;
  }

  @override
  String toString() {
    return '$runtimeType{scheme: $scheme, principal: $principal}';
  }
}

/// No authentication token - for servers that don't require authentication.
class NoAuth extends AuthToken {
  /// Creates a no authentication token.
  NoAuth();

  @override
  String get scheme => 'none';

  @override
  String? get principal => null;

  @override
  Map<String, Object> get properties => const {};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoAuth;
  }

  @override
  int get hashCode => scheme.hashCode;
}

/// Custom authentication token for advanced authentication schemes.
class CustomAuthToken extends AuthToken {
  final String _scheme;
  final String? _principal;
  final Map<String, Object> _properties;

  /// Creates a custom authentication token.
  ///
  /// [scheme] - the authentication scheme
  /// [principal] - the principal (username) for authentication
  /// [properties] - additional properties for the authentication token
  CustomAuthToken(this._scheme, [this._principal, this._properties = const {}]);

  @override
  String get scheme => _scheme;

  @override
  String? get principal => _principal;

  @override
  Map<String, Object> get properties => Map.unmodifiable(_properties);

  /// Creates a custom authentication token with properties.
  factory CustomAuthToken.withProperties(
    String scheme,
    Map<String, Object> properties, [
    String? principal,
  ]) {
    return CustomAuthToken(scheme, principal, properties);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomAuthToken &&
        other.scheme == scheme &&
        other.principal == principal &&
        _propertiesEqual(other._properties);
  }

  bool _propertiesEqual(Map<String, Object> otherProperties) {
    if (_properties.length != otherProperties.length) return false;
    for (final entry in _properties.entries) {
      if (otherProperties[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(scheme, principal, _properties.length);
  }
}
