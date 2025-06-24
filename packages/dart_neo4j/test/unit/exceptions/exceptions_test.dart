import 'package:dart_neo4j/src/exceptions/connection_exception.dart';
import 'package:dart_neo4j/src/exceptions/neo4j_exception.dart';
import 'package:dart_neo4j/src/exceptions/type_exception.dart';
import 'package:test/test.dart';

void main() {
  group('Neo4jException', () {
    test('creates exception with message only', () {
      const exception = _TestNeo4jException('Test message');
      expect(exception.message, equals('Test message'));
      expect(exception.cause, isNull);
      expect(exception.toString(), equals('Neo4jException: Test message'));
    });

    test('creates exception with message and cause', () {
      final cause = Exception('Root cause');
      final exception = _TestNeo4jException('Test message', cause);
      expect(exception.message, equals('Test message'));
      expect(exception.cause, equals(cause));
      expect(exception.toString(), contains('Neo4jException: Test message'));
      expect(
        exception.toString(),
        contains('Caused by: Exception: Root cause'),
      );
    });
  });

  group('DatabaseException', () {
    test('creates exception with message only', () {
      const exception = DatabaseException('Database error');
      expect(exception.message, equals('Database error'));
      expect(exception.code, isNull);
      expect(exception.cause, isNull);
      expect(exception.toString(), equals('DatabaseException: Database error'));
    });

    test('creates exception with message and code', () {
      const exception = DatabaseException(
        'Database error',
        'Neo.ClientError.Schema.ConstraintValidationFailed',
      );
      expect(exception.message, equals('Database error'));
      expect(
        exception.code,
        equals('Neo.ClientError.Schema.ConstraintValidationFailed'),
      );
      expect(
        exception.toString(),
        contains('DatabaseException: Database error'),
      );
      expect(
        exception.toString(),
        contains('(Code: Neo.ClientError.Schema.ConstraintValidationFailed)'),
      );
    });

    test('creates exception with message, code, and cause', () {
      final cause = Exception('Root cause');
      final exception = DatabaseException(
        'Database error',
        'Neo.ClientError.Schema.ConstraintValidationFailed',
        cause,
      );
      expect(exception.message, equals('Database error'));
      expect(
        exception.code,
        equals('Neo.ClientError.Schema.ConstraintValidationFailed'),
      );
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains('DatabaseException: Database error'),
      );
      expect(
        exception.toString(),
        contains('(Code: Neo.ClientError.Schema.ConstraintValidationFailed)'),
      );
      expect(
        exception.toString(),
        contains('Caused by: Exception: Root cause'),
      );
    });
  });

  group('ClientException', () {
    test('creates exception with message only', () {
      const exception = ClientException('Client error');
      expect(exception.message, equals('Client error'));
      expect(exception.cause, isNull);
      expect(exception.toString(), equals('ClientException: Client error'));
    });

    test('creates exception with message and cause', () {
      final cause = Exception('Root cause');
      final exception = ClientException('Client error', cause);
      expect(exception.message, equals('Client error'));
      expect(exception.cause, equals(cause));
      expect(exception.toString(), contains('ClientException: Client error'));
      expect(
        exception.toString(),
        contains('Caused by: Exception: Root cause'),
      );
    });
  });

  group('TransientException', () {
    test('creates exception with message only', () {
      const exception = TransientException('Transient error');
      expect(exception.message, equals('Transient error'));
      expect(exception.code, isNull);
      expect(exception.cause, isNull);
      expect(
        exception.toString(),
        equals('TransientException: Transient error'),
      );
    });

    test('creates exception with message and code', () {
      const exception = TransientException(
        'Transient error',
        'Neo.TransientError.Network.ConnectionPoolFull',
      );
      expect(exception.message, equals('Transient error'));
      expect(
        exception.code,
        equals('Neo.TransientError.Network.ConnectionPoolFull'),
      );
      expect(
        exception.toString(),
        contains('TransientException: Transient error'),
      );
      expect(
        exception.toString(),
        contains('(Code: Neo.TransientError.Network.ConnectionPoolFull)'),
      );
    });

    test('creates exception with message, code, and cause', () {
      final cause = Exception('Root cause');
      final exception = TransientException(
        'Transient error',
        'Neo.TransientError.Network.ConnectionPoolFull',
        cause,
      );
      expect(exception.message, equals('Transient error'));
      expect(
        exception.code,
        equals('Neo.TransientError.Network.ConnectionPoolFull'),
      );
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains('TransientException: Transient error'),
      );
      expect(
        exception.toString(),
        contains('(Code: Neo.TransientError.Network.ConnectionPoolFull)'),
      );
      expect(
        exception.toString(),
        contains('Caused by: Exception: Root cause'),
      );
    });
  });

  group('AuthenticationException', () {
    test('creates exception with message only', () {
      const exception = AuthenticationException('Authentication failed');
      expect(exception.message, equals('Authentication failed'));
      expect(exception.cause, isNull);
      expect(
        exception.toString(),
        equals('AuthenticationException: Authentication failed'),
      );
    });

    test('creates exception with message and cause', () {
      final cause = Exception('Invalid credentials');
      final exception = AuthenticationException('Authentication failed', cause);
      expect(exception.message, equals('Authentication failed'));
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains('AuthenticationException: Authentication failed'),
      );
      expect(
        exception.toString(),
        contains('Caused by: Exception: Invalid credentials'),
      );
    });
  });

  group('AuthorizationException', () {
    test('creates exception with message only', () {
      const exception = AuthorizationException('Access denied');
      expect(exception.message, equals('Access denied'));
      expect(exception.cause, isNull);
      expect(
        exception.toString(),
        equals('AuthorizationException: Access denied'),
      );
    });

    test('creates exception with message and cause', () {
      final cause = Exception('Insufficient permissions');
      final exception = AuthorizationException('Access denied', cause);
      expect(exception.message, equals('Access denied'));
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains('AuthorizationException: Access denied'),
      );
      expect(
        exception.toString(),
        contains('Caused by: Exception: Insufficient permissions'),
      );
    });
  });

  group('SessionExpiredException', () {
    test('creates exception with message only', () {
      const exception = SessionExpiredException('Session expired');
      expect(exception.message, equals('Session expired'));
      expect(exception.cause, isNull);
      expect(
        exception.toString(),
        equals('SessionExpiredException: Session expired'),
      );
    });

    test('creates exception with message and cause', () {
      final cause = Exception('Session timeout');
      final exception = SessionExpiredException('Session expired', cause);
      expect(exception.message, equals('Session expired'));
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains('SessionExpiredException: Session expired'),
      );
      expect(
        exception.toString(),
        contains('Caused by: Exception: Session timeout'),
      );
    });
  });

  group('TransactionClosedException', () {
    test('creates exception with message only', () {
      const exception = TransactionClosedException('Transaction closed');
      expect(exception.message, equals('Transaction closed'));
      expect(exception.cause, isNull);
      expect(
        exception.toString(),
        equals('TransactionClosedException: Transaction closed'),
      );
    });

    test('creates exception with message and cause', () {
      final cause = Exception('Transaction rollback');
      final exception = TransactionClosedException('Transaction closed', cause);
      expect(exception.message, equals('Transaction closed'));
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains('TransactionClosedException: Transaction closed'),
      );
      expect(
        exception.toString(),
        contains('Caused by: Exception: Transaction rollback'),
      );
    });
  });

  group('ConnectionException', () {
    test('creates exception with message only', () {
      const exception = ConnectionException('Connection failed');
      expect(exception.message, equals('Connection failed'));
      expect(exception.cause, isNull);
      expect(
        exception.toString(),
        equals('ConnectionException: Connection failed'),
      );
    });

    test('creates exception with message and cause', () {
      final cause = Exception('Network error');
      final exception = ConnectionException('Connection failed', cause);
      expect(exception.message, equals('Connection failed'));
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains('ConnectionException: Connection failed'),
      );
      expect(
        exception.toString(),
        contains('Caused by: Exception: Network error'),
      );
    });
  });

  group('ServiceUnavailableException', () {
    test('creates exception with message only', () {
      const exception = ServiceUnavailableException('Service unavailable');
      expect(exception.message, equals('Service unavailable'));
      expect(exception.cause, isNull);
      expect(
        exception.toString(),
        equals('ServiceUnavailableException: Service unavailable'),
      );
    });

    test('creates exception with message and cause', () {
      final cause = Exception('Server down');
      final exception = ServiceUnavailableException(
        'Service unavailable',
        cause,
      );
      expect(exception.message, equals('Service unavailable'));
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains('ServiceUnavailableException: Service unavailable'),
      );
      expect(
        exception.toString(),
        contains('Caused by: Exception: Server down'),
      );
    });
  });

  group('ConnectionTimeoutException', () {
    test('creates exception with message only', () {
      const exception = ConnectionTimeoutException('Connection timeout');
      expect(exception.message, equals('Connection timeout'));
      expect(exception.timeout, isNull);
      expect(exception.cause, isNull);
      expect(
        exception.toString(),
        equals('ConnectionTimeoutException: Connection timeout'),
      );
    });

    test('creates exception with message and timeout', () {
      const timeout = Duration(seconds: 30);
      const exception = ConnectionTimeoutException(
        'Connection timeout',
        timeout,
      );
      expect(exception.message, equals('Connection timeout'));
      expect(exception.timeout, equals(timeout));
      expect(
        exception.toString(),
        contains('ConnectionTimeoutException: Connection timeout'),
      );
      expect(exception.toString(), contains('(Timeout: 30000ms)'));
    });

    test('creates exception with message, timeout, and cause', () {
      const timeout = Duration(seconds: 30);
      final cause = Exception('Network slow');
      final exception = ConnectionTimeoutException(
        'Connection timeout',
        timeout,
        cause,
      );
      expect(exception.message, equals('Connection timeout'));
      expect(exception.timeout, equals(timeout));
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains('ConnectionTimeoutException: Connection timeout'),
      );
      expect(exception.toString(), contains('(Timeout: 30000ms)'));
      expect(
        exception.toString(),
        contains('Caused by: Exception: Network slow'),
      );
    });
  });

  group('ConnectionLostException', () {
    test('creates exception with message only', () {
      const exception = ConnectionLostException('Connection lost');
      expect(exception.message, equals('Connection lost'));
      expect(exception.cause, isNull);
      expect(
        exception.toString(),
        equals('ConnectionLostException: Connection lost'),
      );
    });

    test('creates exception with message and cause', () {
      final cause = Exception('Network disconnect');
      final exception = ConnectionLostException('Connection lost', cause);
      expect(exception.message, equals('Connection lost'));
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains('ConnectionLostException: Connection lost'),
      );
      expect(
        exception.toString(),
        contains('Caused by: Exception: Network disconnect'),
      );
    });
  });

  group('SecurityException', () {
    test('creates exception with message only', () {
      const exception = SecurityException('Security error');
      expect(exception.message, equals('Security error'));
      expect(exception.cause, isNull);
      expect(exception.toString(), equals('SecurityException: Security error'));
    });

    test('creates exception with message and cause', () {
      final cause = Exception('TLS handshake failed');
      final exception = SecurityException('Security error', cause);
      expect(exception.message, equals('Security error'));
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains('SecurityException: Security error'),
      );
      expect(
        exception.toString(),
        contains('Caused by: Exception: TLS handshake failed'),
      );
    });
  });

  group('ProtocolException', () {
    test('creates exception with message only', () {
      const exception = ProtocolException('Protocol error');
      expect(exception.message, equals('Protocol error'));
      expect(exception.version, isNull);
      expect(exception.cause, isNull);
      expect(exception.toString(), equals('ProtocolException: Protocol error'));
    });

    test('creates exception with message and version', () {
      const exception = ProtocolException('Protocol error', 4);
      expect(exception.message, equals('Protocol error'));
      expect(exception.version, equals(4));
      expect(
        exception.toString(),
        contains('ProtocolException: Protocol error'),
      );
      expect(exception.toString(), contains('(Version: 4)'));
    });

    test('creates exception with message, version, and cause', () {
      final cause = Exception('Unsupported version');
      final exception = ProtocolException('Protocol error', 4, cause);
      expect(exception.message, equals('Protocol error'));
      expect(exception.version, equals(4));
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains('ProtocolException: Protocol error'),
      );
      expect(exception.toString(), contains('(Version: 4)'));
      expect(
        exception.toString(),
        contains('Caused by: Exception: Unsupported version'),
      );
    });
  });

  group('InvalidUriException', () {
    test('creates exception with message and uri', () {
      const exception = InvalidUriException('Invalid URI', 'invalid://uri');
      expect(exception.message, equals('Invalid URI'));
      expect(exception.uri, equals('invalid://uri'));
      expect(exception.cause, isNull);
      expect(
        exception.toString(),
        contains('InvalidUriException: Invalid URI'),
      );
      expect(exception.toString(), contains('(URI: invalid://uri)'));
    });

    test('creates exception with message, uri, and cause', () {
      final cause = Exception('Malformed URI');
      final exception = InvalidUriException(
        'Invalid URI',
        'invalid://uri',
        cause,
      );
      expect(exception.message, equals('Invalid URI'));
      expect(exception.uri, equals('invalid://uri'));
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains('InvalidUriException: Invalid URI'),
      );
      expect(exception.toString(), contains('(URI: invalid://uri)'));
      expect(
        exception.toString(),
        contains('Caused by: Exception: Malformed URI'),
      );
    });
  });

  group('TypeException', () {
    test('creates exception with message only', () {
      const exception = TypeException('Type error');
      expect(exception.message, equals('Type error'));
      expect(exception.cause, isNull);
      expect(exception.toString(), equals('TypeException: Type error'));
    });

    test('creates exception with message and cause', () {
      final cause = Exception('Type conversion failed');
      final exception = TypeException('Type error', cause);
      expect(exception.message, equals('Type error'));
      expect(exception.cause, equals(cause));
      expect(exception.toString(), contains('TypeException: Type error'));
      expect(
        exception.toString(),
        contains('Caused by: Exception: Type conversion failed'),
      );
    });
  });

  group('FieldNotFoundException', () {
    test('creates exception with field name only', () {
      const exception = FieldNotFoundException('missingField');
      expect(exception.fieldName, equals('missingField'));
      expect(exception.availableFields, isNull);
      expect(
        exception.message,
        equals('Field "missingField" not found in record'),
      );
      expect(
        exception.toString(),
        contains(
          'FieldNotFoundException: Field "missingField" not found in record',
        ),
      );
    });

    test('creates exception with field name and available fields', () {
      const availableFields = {'name', 'age', 'email'};
      const exception = FieldNotFoundException('missingField', availableFields);
      expect(exception.fieldName, equals('missingField'));
      expect(exception.availableFields, equals(availableFields));
      expect(
        exception.toString(),
        contains(
          'FieldNotFoundException: Field "missingField" not found in record',
        ),
      );
      expect(
        exception.toString(),
        contains('Available fields: name, age, email'),
      );
    });

    test('creates exception with field name, available fields, and cause', () {
      const availableFields = {'name', 'age'};
      final cause = Exception('Field access error');
      final exception = FieldNotFoundException(
        'missingField',
        availableFields,
        cause,
      );
      expect(exception.fieldName, equals('missingField'));
      expect(exception.availableFields, equals(availableFields));
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains(
          'FieldNotFoundException: Field "missingField" not found in record',
        ),
      );
      expect(exception.toString(), contains('Available fields: name, age'));
      expect(
        exception.toString(),
        contains('Caused by: Exception: Field access error'),
      );
    });
  });

  group('TypeMismatchException', () {
    test('creates exception with field name and types', () {
      final exception = TypeMismatchException('age', int, String);
      expect(exception.fieldName, equals('age'));
      expect(exception.expectedType, equals(int));
      expect(exception.actualType, equals(String));
      expect(exception.actualValue, isNull);
      expect(
        exception.message,
        equals('Field "age" expected type int but got String'),
      );
      expect(
        exception.toString(),
        contains(
          'TypeMismatchException: Field "age" expected type int but got String',
        ),
      );
    });

    test('creates exception with field name, types, and value', () {
      final exception = TypeMismatchException('age', int, String, 'thirty');
      expect(exception.fieldName, equals('age'));
      expect(exception.expectedType, equals(int));
      expect(exception.actualType, equals(String));
      expect(exception.actualValue, equals('thirty'));
      expect(
        exception.toString(),
        contains(
          'TypeMismatchException: Field "age" expected type int but got String',
        ),
      );
      expect(exception.toString(), contains('(value: thirty)'));
    });

    test('creates exception with field name, types, value, and cause', () {
      final cause = Exception('Conversion error');
      final exception = TypeMismatchException(
        'age',
        int,
        String,
        'thirty',
        cause,
      );
      expect(exception.fieldName, equals('age'));
      expect(exception.expectedType, equals(int));
      expect(exception.actualType, equals(String));
      expect(exception.actualValue, equals('thirty'));
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains(
          'TypeMismatchException: Field "age" expected type int but got String',
        ),
      );
      expect(exception.toString(), contains('(value: thirty)'));
      expect(
        exception.toString(),
        contains('Caused by: Exception: Conversion error'),
      );
    });
  });

  group('UnexpectedNullException', () {
    test('creates exception with field name and type', () {
      final exception = UnexpectedNullException('name', String);
      expect(exception.fieldName, equals('name'));
      expect(exception.expectedType, equals(String));
      expect(
        exception.message,
        equals('Field "name" expected non-null String but got null'),
      );
      expect(
        exception.toString(),
        contains(
          'UnexpectedNullException: Field "name" expected non-null String but got null',
        ),
      );
    });

    test('creates exception with field name, type, and cause', () {
      final cause = Exception('Null validation failed');
      final exception = UnexpectedNullException('name', String, cause);
      expect(exception.fieldName, equals('name'));
      expect(exception.expectedType, equals(String));
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains(
          'UnexpectedNullException: Field "name" expected non-null String but got null',
        ),
      );
      expect(
        exception.toString(),
        contains('Caused by: Exception: Null validation failed'),
      );
    });
  });

  group('ConversionException', () {
    test('creates exception with value and target type', () {
      final exception = ConversionException('not a number', int);
      expect(exception.value, equals('not a number'));
      expect(exception.targetType, equals(int));
      expect(
        exception.message,
        equals('Cannot convert value not a number to type int'),
      );
      expect(
        exception.toString(),
        contains(
          'ConversionException: Cannot convert value not a number to type int',
        ),
      );
    });

    test('creates exception with value, target type, and cause', () {
      final cause = Exception('Parsing failed');
      final exception = ConversionException('not a number', int, cause);
      expect(exception.value, equals('not a number'));
      expect(exception.targetType, equals(int));
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains(
          'ConversionException: Cannot convert value not a number to type int',
        ),
      );
      expect(
        exception.toString(),
        contains('Caused by: Exception: Parsing failed'),
      );
    });

    test('handles null value', () {
      final exception = ConversionException(null, int);
      expect(exception.value, isNull);
      expect(exception.targetType, equals(int));
      expect(
        exception.toString(),
        contains('ConversionException: Cannot convert value null to type int'),
      );
    });
  });

  group('IndexOutOfRangeException', () {
    test('creates exception with index and max index', () {
      const exception = IndexOutOfRangeException(5, 3);
      expect(exception.index, equals(5));
      expect(exception.maxIndex, equals(3));
      expect(
        exception.message,
        equals('Index 5 is out of range. Valid range: 0 to 3'),
      );
      expect(
        exception.toString(),
        contains(
          'IndexOutOfRangeException: Index 5 is out of range. Valid range: 0 to 3',
        ),
      );
    });

    test('creates exception with index, max index, and cause', () {
      final cause = Exception('Array bounds check failed');
      final exception = IndexOutOfRangeException(5, 3, cause);
      expect(exception.index, equals(5));
      expect(exception.maxIndex, equals(3));
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains(
          'IndexOutOfRangeException: Index 5 is out of range. Valid range: 0 to 3',
        ),
      );
      expect(
        exception.toString(),
        contains('Caused by: Exception: Array bounds check failed'),
      );
    });
  });

  group('Exception Hierarchy', () {
    test('all exceptions extend appropriate base classes', () {
      expect(const DatabaseException('test'), isA<Neo4jException>());
      expect(const ClientException('test'), isA<Neo4jException>());
      expect(const TransientException('test'), isA<Neo4jException>());
      expect(const AuthenticationException('test'), isA<Neo4jException>());
      expect(const AuthorizationException('test'), isA<Neo4jException>());
      expect(const SessionExpiredException('test'), isA<Neo4jException>());
      expect(const TransactionClosedException('test'), isA<Neo4jException>());

      expect(const ConnectionException('test'), isA<Neo4jException>());
      expect(
        const ServiceUnavailableException('test'),
        isA<ConnectionException>(),
      );
      expect(
        const ConnectionTimeoutException('test'),
        isA<ConnectionException>(),
      );
      expect(const ConnectionLostException('test'), isA<ConnectionException>());
      expect(const SecurityException('test'), isA<ConnectionException>());
      expect(const ProtocolException('test'), isA<ConnectionException>());
      expect(
        const InvalidUriException('test', 'uri'),
        isA<ConnectionException>(),
      );

      expect(const TypeException('test'), isA<Neo4jException>());
      expect(const FieldNotFoundException('field'), isA<TypeException>());
      expect(TypeMismatchException('field', int, String), isA<TypeException>());
      expect(UnexpectedNullException('field', String), isA<TypeException>());
      expect(ConversionException('value', int), isA<TypeException>());
      expect(const IndexOutOfRangeException(1, 0), isA<TypeException>());
    });

    test('all exceptions implement Exception interface', () {
      expect(const DatabaseException('test'), isA<Exception>());
      expect(const ConnectionException('test'), isA<Exception>());
      expect(const TypeException('test'), isA<Exception>());
    });
  });
}

class _TestNeo4jException extends Neo4jException {
  const _TestNeo4jException(super.message, [super.cause]);
}
