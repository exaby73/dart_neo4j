import 'package:dart_neo4j/src/auth/auth_token.dart';
import 'package:dart_neo4j/src/auth/basic_auth.dart';
import 'package:test/test.dart';

void main() {
  group('AuthToken', () {
    group('BasicAuth', () {
      test('should create BasicAuth with username and password', () {
        final auth = BasicAuth('neo4j', 'password');

        expect(auth.principal, equals('neo4j'));
        expect(auth.password, equals('password'));
        expect(auth.realm, isNull);
        expect(auth.scheme, equals('basic'));
      });

      test('should create BasicAuth with realm', () {
        final auth = BasicAuth('neo4j', 'password', 'myrealm');

        expect(auth.principal, equals('neo4j'));
        expect(auth.password, equals('password'));
        expect(auth.realm, equals('myrealm'));
        expect(auth.scheme, equals('basic'));
      });

      test('should create token map correctly', () {
        final auth = BasicAuth('neo4j', 'password');
        final tokenMap = auth.toAuthData();

        expect(tokenMap['scheme'], equals('basic'));
        expect(tokenMap['principal'], equals('neo4j'));
        expect(tokenMap['credentials'], equals('password'));
        expect(tokenMap.containsKey('realm'), isFalse);
      });

      test('should create token map with realm', () {
        final auth = BasicAuth('neo4j', 'password', 'myrealm');
        final tokenMap = auth.toAuthData();

        expect(tokenMap['scheme'], equals('basic'));
        expect(tokenMap['principal'], equals('neo4j'));
        expect(tokenMap['credentials'], equals('password'));
        expect(tokenMap['realm'], equals('myrealm'));
      });

      test('should have proper string representation', () {
        final auth = BasicAuth('neo4j', 'password');

        expect(auth.toString(), contains('BasicAuth'));
        expect(auth.toString(), contains('neo4j'));
        expect(
          auth.toString(),
          isNot(contains('password')),
        ); // Should not expose password
      });

      test('should be equal when same credentials', () {
        final auth1 = BasicAuth('neo4j', 'password');
        final auth2 = BasicAuth('neo4j', 'password');

        expect(auth1, equals(auth2));
        expect(auth1.hashCode, equals(auth2.hashCode));
      });

      test('should not be equal when different credentials', () {
        final auth1 = BasicAuth('neo4j', 'password1');
        final auth2 = BasicAuth('neo4j', 'password2');

        expect(auth1, isNot(equals(auth2)));
      });
    });

    group('BearerAuth', () {
      test('should create BearerAuth with token', () {
        final auth = BearerAuth('my-jwt-token');

        expect(auth.token, equals('my-jwt-token'));
        expect(auth.scheme, equals('bearer'));
      });

      test('should create token map correctly', () {
        final auth = BearerAuth('my-jwt-token');
        final tokenMap = auth.toAuthData();

        expect(tokenMap['scheme'], equals('bearer'));
        expect(tokenMap['credentials'], equals('my-jwt-token'));
      });

      test('should have proper string representation', () {
        final auth = BearerAuth('my-jwt-token');

        expect(auth.toString(), contains('BearerAuth'));
        expect(
          auth.toString(),
          isNot(contains('my-jwt-token')),
        ); // Should not expose token
      });

      test('should be equal when same token', () {
        final auth1 = BearerAuth('token');
        final auth2 = BearerAuth('token');

        expect(auth1, equals(auth2));
        expect(auth1.hashCode, equals(auth2.hashCode));
      });
    });

    group('KerberosAuth', () {
      test('should create KerberosAuth with ticket', () {
        final auth = KerberosAuth('user@REALM', 'kerberos-ticket');

        expect(auth.ticket, equals('kerberos-ticket'));
        expect(auth.scheme, equals('kerberos'));
      });

      test('should create token map correctly', () {
        final auth = KerberosAuth('user@REALM', 'kerberos-ticket');
        final tokenMap = auth.toAuthData();

        expect(tokenMap['scheme'], equals('kerberos'));
        expect(tokenMap['credentials'], equals('kerberos-ticket'));
      });

      test('should have proper string representation', () {
        final auth = KerberosAuth('user@REALM', 'kerberos-ticket');

        expect(auth.toString(), contains('KerberosAuth'));
        expect(
          auth.toString(),
          isNot(contains('kerberos-ticket')),
        ); // Should not expose ticket
      });

      test('should be equal when same ticket', () {
        final auth1 = KerberosAuth('user', 'ticket');
        final auth2 = KerberosAuth('user', 'ticket');

        expect(auth1, equals(auth2));
        expect(auth1.hashCode, equals(auth2.hashCode));
      });
    });

    group('NoAuth', () {
      test('should create NoAuth token', () {
        final auth = NoAuth();

        expect(auth.scheme, equals('none'));
      });

      test('should create empty token map', () {
        final auth = NoAuth();
        final tokenMap = auth.toAuthData();

        expect(tokenMap['scheme'], equals('none'));
        expect(tokenMap.length, equals(1));
      });

      test('should have proper string representation', () {
        final auth = NoAuth();

        expect(auth.toString(), contains('NoAuth'));
      });

      test('should be equal to other NoAuth instances', () {
        final auth1 = NoAuth();
        final auth2 = NoAuth();

        expect(auth1, equals(auth2));
        expect(auth1.hashCode, equals(auth2.hashCode));
      });
    });

    group('CustomAuth', () {
      test('should create CustomAuth with scheme and credentials', () {
        final auth = CustomAuthToken.withProperties('custom', {'key': 'value'});

        expect(auth.scheme, equals('custom'));
        expect(auth.properties, equals({'key': 'value'}));
      });

      test('should create token map correctly', () {
        final auth = CustomAuthToken.withProperties('custom', {
          'key': 'value',
          'another': 'data',
        });
        final tokenMap = auth.toAuthData();

        expect(tokenMap['scheme'], equals('custom'));
        expect(tokenMap['key'], equals('value'));
        expect(tokenMap['another'], equals('data'));
      });

      test('should have proper string representation', () {
        final auth = CustomAuthToken.withProperties('custom', {'key': 'value'});

        expect(auth.toString(), contains('CustomAuthToken'));
        expect(auth.toString(), contains('custom'));
      });

      test('should be equal when same scheme and credentials', () {
        final auth1 = CustomAuthToken.withProperties('custom', {
          'key': 'value',
        });
        final auth2 = CustomAuthToken.withProperties('custom', {
          'key': 'value',
        });

        expect(auth1, equals(auth2));
        expect(auth1.hashCode, equals(auth2.hashCode));
      });

      test('should not be equal when different credentials', () {
        final auth1 = CustomAuthToken.withProperties('custom', {
          'key': 'value1',
        });
        final auth2 = CustomAuthToken.withProperties('custom', {
          'key': 'value2',
        });

        expect(auth1, isNot(equals(auth2)));
      });
    });

    group('factory methods', () {
      test('should create basic auth from factory', () {
        final auth = BasicAuth('user', 'pass');

        expect(auth, isA<BasicAuth>());
        expect(auth.scheme, equals('basic'));
      });

      test('should create bearer auth from factory', () {
        final auth = BearerAuth('token');

        expect(auth, isA<BearerAuth>());
        expect(auth.scheme, equals('bearer'));
      });

      test('should create kerberos auth from factory', () {
        final auth = KerberosAuth('user', 'ticket');

        expect(auth, isA<KerberosAuth>());
        expect(auth.scheme, equals('kerberos'));
      });

      test('should create no auth from factory', () {
        final auth = NoAuth();

        expect(auth, isA<NoAuth>());
        expect(auth.scheme, equals('none'));
      });

      test('should create custom auth from factory', () {
        final auth = CustomAuthToken.withProperties('myscheme', {
          'data': 'value',
        });

        expect(auth, isA<CustomAuthToken>());
        expect(auth.scheme, equals('myscheme'));
      });
    });
  });
}
