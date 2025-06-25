import 'package:dart_neo4j/src/auth/auth_token.dart';

/// Basic authentication token using username and password.
class BasicAuth extends AuthToken {
  final String _username;
  final String _password;
  final String? _realm;

  /// Creates a basic authentication token.
  ///
  /// [username] - the username
  /// [password] - the password
  /// [realm] - optional realm for the authentication (defaults to empty string)
  BasicAuth(this._username, this._password, [this._realm]);

  @override
  String get scheme => 'basic';

  @override
  String get principal => _username;

  @override
  Map<String, Object> get properties {
    final props = <String, Object>{'credentials': _password};

    if (_realm != null) {
      props['realm'] = _realm;
    }

    return props;
  }

  /// The username for authentication.
  String get username => _username;

  /// The password for authentication.
  String get password => _password;

  /// The realm for authentication.
  String? get realm => _realm;

  @override
  String toString() {
    return 'BasicAuth{username: $username, realm: $realm}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BasicAuth &&
        other.username == username &&
        other.password == password &&
        other.realm == realm;
  }

  @override
  int get hashCode {
    return Object.hash(username, password, realm);
  }
}

/// Bearer token authentication for OAuth or similar token-based authentication.
class BearerAuth extends AuthToken {
  final String _token;
  final String? _realm;

  /// Creates a bearer authentication token.
  ///
  /// [token] - the bearer token
  /// [realm] - optional realm for the authentication
  BearerAuth(this._token, [this._realm]);

  @override
  String get scheme => 'bearer';

  @override
  String? get principal => null;

  @override
  Map<String, Object> get properties {
    final props = <String, Object>{'credentials': _token};

    if (_realm != null) {
      props['realm'] = _realm;
    }

    return props;
  }

  /// The bearer token.
  String get token => _token;

  /// The realm for authentication.
  String? get realm => _realm;

  @override
  String toString() {
    return 'BearerAuth{realm: $realm}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BearerAuth && other.token == token && other.realm == realm;
  }

  @override
  int get hashCode {
    return Object.hash(token, realm);
  }
}

/// Kerberos authentication token.
class KerberosAuth extends AuthToken {
  final String _principal;
  final String _ticket;
  final String? _realm;

  /// Creates a Kerberos authentication token.
  ///
  /// [principal] - the Kerberos principal
  /// [ticket] - the Kerberos ticket
  /// [realm] - optional realm for the authentication
  KerberosAuth(this._principal, this._ticket, [this._realm]);

  @override
  String get scheme => 'kerberos';

  @override
  String get principal => _principal;

  @override
  Map<String, Object> get properties {
    final props = <String, Object>{'credentials': _ticket};

    if (_realm != null) {
      props['realm'] = _realm;
    }

    return props;
  }

  /// The Kerberos principal.
  String get kerberosPrincipal => _principal;

  /// The Kerberos ticket.
  String get ticket => _ticket;

  /// The realm for authentication.
  String? get realm => _realm;

  @override
  String toString() {
    return 'KerberosAuth{principal: $principal, realm: $realm}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KerberosAuth &&
        other.kerberosPrincipal == kerberosPrincipal &&
        other.ticket == ticket &&
        other.realm == realm;
  }

  @override
  int get hashCode {
    return Object.hash(kerberosPrincipal, ticket, realm);
  }
}
