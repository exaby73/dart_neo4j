import 'package:dart_neo4j/src/driver/uri_parser.dart';
import 'package:dart_neo4j/src/exceptions/connection_exception.dart';
import 'package:test/test.dart';

void main() {
  group('UriParser', () {
    group('valid URIs', () {
      test('should parse bolt:// URI', () {
        final uri = UriParser.parse('bolt://localhost:7687');

        expect(uri.connectionType, equals(ConnectionType.direct));
        expect(uri.host, equals('localhost'));
        expect(uri.port, equals(7687));
        expect(uri.encrypted, isFalse);
        expect(uri.database, isNull);
      });

      test('should parse bolt:// URI with database', () {
        final uri = UriParser.parse('bolt://localhost:7687/mydb');

        expect(uri.connectionType, equals(ConnectionType.direct));
        expect(uri.host, equals('localhost'));
        expect(uri.port, equals(7687));
        expect(uri.database, equals('mydb'));
      });

      test('should parse bolt+s:// URI (encrypted)', () {
        final uri = UriParser.parse('bolt+s://localhost:7687');

        expect(uri.connectionType, equals(ConnectionType.direct));
        expect(uri.encrypted, isTrue);
      });

      test('should parse bolt+ssc:// URI (self-signed certificates)', () {
        final uri = UriParser.parse('bolt+ssc://localhost:7687');

        expect(uri.connectionType, equals(ConnectionType.direct));
        expect(uri.encrypted, isTrue);
        expect(uri.allowsSelfSignedCertificates, isTrue);
      });

      test('should parse neo4j:// URI', () {
        final uri = UriParser.parse('neo4j://localhost:7687');

        expect(uri.connectionType, equals(ConnectionType.routing));
        expect(uri.host, equals('localhost'));
        expect(uri.port, equals(7687));
        expect(uri.encrypted, isFalse);
      });

      test('should parse neo4j+s:// URI (encrypted)', () {
        final uri = UriParser.parse('neo4j+s://localhost:7687');

        expect(uri.connectionType, equals(ConnectionType.routing));
        expect(uri.encrypted, isTrue);
      });

      test('should parse neo4j+ssc:// URI (self-signed certificates)', () {
        final uri = UriParser.parse('neo4j+ssc://localhost:7687');

        expect(uri.connectionType, equals(ConnectionType.routing));
        expect(uri.encrypted, isTrue);
        expect(uri.allowsSelfSignedCertificates, isTrue);
      });

      test('should use default port 7687 when not specified', () {
        final uri = UriParser.parse('bolt://localhost');

        expect(uri.port, equals(7687));
      });

      test('should parse URI with IPv6 address', () {
        final uri = UriParser.parse('bolt://[::1]:7687');

        expect(uri.host, equals('::1'));
        expect(uri.port, equals(7687));
      });

      test('should parse URI with query parameters', () {
        final uri = UriParser.parse(
          'bolt://localhost:7687?routing=false&policy=round_robin',
        );

        expect(uri.parameters['routing'], equals('false'));
        expect(uri.parameters['policy'], equals('round_robin'));
      });
    });

    group('invalid URIs', () {
      test('should throw InvalidUriException for unsupported scheme', () {
        expect(
          () => UriParser.parse('http://localhost:7687'),
          throwsA(isA<InvalidUriException>()),
        );
      });

      test('should throw InvalidUriException for missing host', () {
        expect(
          () => UriParser.parse('bolt://:7687'),
          throwsA(isA<InvalidUriException>()),
        );
      });

      test('should throw InvalidUriException for invalid port', () {
        expect(
          () => UriParser.parse('bolt://localhost:abc'),
          throwsA(isA<InvalidUriException>()),
        );
      });

      test('should throw InvalidUriException for port out of range', () {
        expect(
          () => UriParser.parse('bolt://localhost:70000'),
          throwsA(isA<InvalidUriException>()),
        );
      });

      test('should throw InvalidUriException for invalid database name', () {
        expect(
          () => UriParser.parse('bolt://localhost:7687/my@db'),
          throwsA(isA<InvalidUriException>()),
        );
      });

      test(
        'should throw InvalidUriException for database name starting with number',
        () {
          expect(
            () => UriParser.parse('bolt://localhost:7687/123db'),
            throwsA(isA<InvalidUriException>()),
          );
        },
      );

      test('should throw InvalidUriException for empty URI', () {
        expect(() => UriParser.parse(''), throwsA(isA<InvalidUriException>()));
      });

      test('should throw InvalidUriException for malformed URI', () {
        expect(
          () => UriParser.parse('not-a-uri'),
          throwsA(isA<InvalidUriException>()),
        );
      });
    });

    group('database name validation', () {
      test('should accept valid database names', () {
        final validNames = [
          'mydb',
          'my_db',
          'my.db',
          'my-db',
          'database123',
          'db_with_underscores',
          'db.with.dots',
          'CamelCaseDb',
        ];

        for (final name in validNames) {
          expect(
            () => UriParser.parse('bolt://localhost:7687/$name'),
            returnsNormally,
            reason: 'Database name "$name" should be valid',
          );
        }
      });

      test('should reject invalid database names', () {
        final invalidNames = [
          '123db', // starts with number
          'my db', // contains space
          'my@db', // contains special character
          'a' * 64, // too long
          'my-', // ends with hyphen
          'my.', // ends with dot
          'my..db', // consecutive dots
          'ab', // too short
        ];

        for (final name in invalidNames) {
          expect(
            () => UriParser.parse('bolt://localhost:7687/$name'),
            throwsA(isA<InvalidUriException>()),
            reason: 'Database name "$name" should be invalid',
          );
        }
      });
    });

    group('display string creation', () {
      test('should create display string without database', () {
        final uri = ParsedUri(
          connectionType: ConnectionType.direct,
          encryptionLevel: EncryptionLevel.none,
          host: 'localhost',
          port: 7687,
          database: null,
          parameters: {},
          originalUri: 'bolt://localhost:7687',
        );

        expect(
          UriParser.createDisplayString(uri),
          equals('bolt://localhost:7687'),
        );
      });

      test('should create display string with database', () {
        final uri = ParsedUri(
          connectionType: ConnectionType.direct,
          encryptionLevel: EncryptionLevel.none,
          host: 'localhost',
          port: 7687,
          database: 'mydb',
          parameters: {},
          originalUri: 'bolt://localhost:7687/mydb',
        );

        expect(
          UriParser.createDisplayString(uri),
          equals('bolt://localhost:7687/mydb'),
        );
      });

      test('should create display string with encryption', () {
        final uri = ParsedUri(
          connectionType: ConnectionType.direct,
          encryptionLevel: EncryptionLevel.encrypted,
          host: 'localhost',
          port: 7687,
          database: null,
          parameters: {},
          originalUri: 'bolt+s://localhost:7687',
        );

        expect(
          UriParser.createDisplayString(uri),
          equals('bolt+s://localhost:7687'),
        );
      });

      test('should create display string with self-signed certificates', () {
        final uri = ParsedUri(
          connectionType: ConnectionType.direct,
          encryptionLevel: EncryptionLevel.encryptedSelfSigned,
          host: 'localhost',
          port: 7687,
          database: null,
          parameters: {},
          originalUri: 'bolt+ssc://localhost:7687',
        );

        expect(
          UriParser.createDisplayString(uri),
          equals('bolt+ssc://localhost:7687'),
        );
      });
    });
  });
}
