import 'package:dart_bolt/dart_bolt.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    registerBolt();
  });

  tearDown(() {
    PsStructureRegistry.clear();
    registerBolt();
  });

  group('Bolt Messages', () {
    group('Request Messages', () {
      test('HELLO message serializes and deserializes correctly', () {
        final hello = BoltMessageFactory.hello(
          userAgent: 'TestApp/1.0.0',
          boltAgent: {'product': 'TestDriver/1.0.0', 'platform': 'Dart'},
        );

        expect(hello.signature, equals(0x01));
        expect(hello.isRequest, isTrue);
        expect(hello.isSummary, isFalse);

        final bytes = hello.toByteData();
        final parsed =
            PsDataType.fromPackStreamBytes(bytes) as BoltHelloMessage;

        expect(parsed.signature, equals(0x01));
        expect(parsed.extra.dartValue, isA<Map<String, dynamic>>());
      });

      test('RUN message serializes and deserializes correctly', () {
        final run = BoltMessageFactory.run(
          'MATCH (n:Person) WHERE n.age > \$age RETURN n.name',
          parameters: {'age': 25},
          extra: {'mode': 'r', 'db': 'neo4j'},
        );

        expect(run.signature, equals(0x10));
        expect(
          run.query.dartValue,
          equals('MATCH (n:Person) WHERE n.age > \$age RETURN n.name'),
        );
        expect(run.parameters.dartValue, equals({'age': 25}));

        final bytes = run.toByteData();
        final parsed = PsDataType.fromPackStreamBytes(bytes) as BoltRunMessage;

        expect(parsed.signature, equals(0x10));
        expect(
          parsed.query.dartValue,
          equals('MATCH (n:Person) WHERE n.age > \$age RETURN n.name'),
        );
        expect(parsed.parameters.dartValue, equals({'age': 25}));
      });

      test('PULL message serializes and deserializes correctly', () {
        final pull = BoltMessageFactory.pull(n: 100, qid: 1);

        expect(pull.signature, equals(0x3F));
        expect(pull.extra?.dartValue, equals({'n': 100, 'qid': 1}));

        final bytes = pull.toByteData();
        final parsed = PsDataType.fromPackStreamBytes(bytes) as BoltPullMessage;

        expect(parsed.signature, equals(0x3F));
        expect(parsed.extra?.dartValue, equals({'n': 100, 'qid': 1}));
      });

      test('PULL_ALL message (no parameters) serializes correctly', () {
        final pullAll = BoltMessageFactory.pullAll();

        expect(pullAll.signature, equals(0x3F));
        expect(pullAll.extra, isNull);

        final bytes = pullAll.toByteData();
        final parsed = PsDataType.fromPackStreamBytes(bytes) as BoltPullMessage;

        expect(parsed.signature, equals(0x3F));
        expect(parsed.extra, isNull);
      });

      test('BEGIN message serializes and deserializes correctly', () {
        final begin = BoltMessageFactory.begin(
          bookmarks: ['bookmark1', 'bookmark2'],
          txTimeout: 5000,
          mode: 'w',
          db: 'mydb',
        );

        expect(begin.signature, equals(0x11));

        final bytes = begin.toByteData();
        final parsed =
            PsDataType.fromPackStreamBytes(bytes) as BoltBeginMessage;

        expect(parsed.signature, equals(0x11));
        expect(parsed.extra?.dartValue, isA<Map<String, dynamic>>());
      });

      test('COMMIT message serializes and deserializes correctly', () {
        final commit = BoltMessageFactory.commit();

        expect(commit.signature, equals(0x12));
        expect(commit.numberOfFields, equals(0));

        final bytes = commit.toByteData();
        final parsed =
            PsDataType.fromPackStreamBytes(bytes) as BoltCommitMessage;

        expect(parsed.signature, equals(0x12));
      });

      test('GOODBYE message serializes correctly', () {
        final goodbye = BoltMessageFactory.goodbye();

        expect(goodbye.signature, equals(0x02));
        expect(goodbye.numberOfFields, equals(0));

        final bytes = goodbye.toByteData();
        expect(bytes.lengthInBytes, equals(2)); // marker + signature only
      });

      test('LOGON message serializes and deserializes correctly', () {
        final logon = BoltMessageFactory.logon(
          scheme: 'basic',
          principal: 'neo4j',
          credentials: 'password',
        );

        expect(logon.signature, equals(0x6A));
        expect(logon.isRequest, isTrue);
        expect(logon.isSummary, isFalse);

        final bytes = logon.toByteData();
        final parsed =
            PsDataType.fromPackStreamBytes(bytes) as BoltLogonMessage;

        expect(parsed.signature, equals(0x6A));
        expect(
          parsed.auth.dartValue,
          equals({
            'scheme': 'basic',
            'principal': 'neo4j',
            'credentials': 'password',
          }),
        );
      });

      test('LOGON message with bearer token serializes correctly', () {
        final logon = BoltMessageFactory.logon(
          scheme: 'bearer',
          credentials: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        );

        expect(logon.signature, equals(0x6A));
        expect(
          logon.auth.dartValue,
          equals({
            'scheme': 'bearer',
            'credentials': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
          }),
        );

        final bytes = logon.toByteData();
        final parsed =
            PsDataType.fromPackStreamBytes(bytes) as BoltLogonMessage;

        expect(parsed.signature, equals(0x6A));
        expect(parsed.auth.dartValue['scheme'], equals('bearer'));
        expect(
          parsed.auth.dartValue['credentials'],
          equals('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'),
        );
      });
    });

    group('Response Messages', () {
      test('SUCCESS message serializes and deserializes correctly', () {
        final success = BoltMessageFactory.success({
          'fields': ['name', 'age'],
          't_first': 123,
        });

        expect(success.signature, equals(0x70));
        expect(success.isSummary, isTrue);

        final bytes = success.toByteData();
        final parsed =
            PsDataType.fromPackStreamBytes(bytes) as BoltSuccessMessage;

        expect(parsed.signature, equals(0x70));
        expect(
          parsed.metadata?.dartValue,
          equals({
            'fields': ['name', 'age'],
            't_first': 123,
          }),
        );
      });

      test('FAILURE message serializes and deserializes correctly', () {
        final failure = BoltMessageFactory.failure(
          'Neo.ClientError.Statement.SyntaxError',
          'Invalid syntax',
        );

        expect(failure.signature, equals(0x7F));
        expect(failure.isSummary, isTrue);

        final bytes = failure.toByteData();
        final parsed =
            PsDataType.fromPackStreamBytes(bytes) as BoltFailureMessage;

        expect(parsed.signature, equals(0x7F));
        expect(
          parsed.metadata.dartValue,
          equals({
            'code': 'Neo.ClientError.Statement.SyntaxError',
            'message': 'Invalid syntax',
          }),
        );
      });

      test('RECORD message serializes and deserializes correctly', () {
        final record = BoltMessageFactory.record(['Alice', 30, true]);

        expect(record.signature, equals(0x71));
        expect(record.isDetail, isTrue);

        final bytes = record.toByteData();
        final parsed =
            PsDataType.fromPackStreamBytes(bytes) as BoltRecordMessage;

        expect(parsed.signature, equals(0x71));
        expect(parsed.data.dartValue, equals(['Alice', 30, true]));
      });
    });

    group('Byte Format Validation', () {
      test('messages have correct PackStream structure format', () {
        final hello = BoltMessageFactory.hello(userAgent: 'Test/1.0.0');
        final bytes = hello.toByteData();

        // Should start with structure marker (0xB1 for 1 field)
        expect(bytes.getUint8(0), equals(0xB1));
        // Followed by signature byte (0x01 for HELLO)
        expect(bytes.getUint8(1), equals(0x01));
        // Followed by the serialized extra dictionary
      });

      test('empty messages have minimal byte representation', () {
        final commit = BoltMessageFactory.commit();
        final bytes = commit.toByteData();

        // Should be exactly 2 bytes: marker (0xB0) + signature (0x12)
        expect(bytes.lengthInBytes, equals(2));
        expect(bytes.getUint8(0), equals(0xB0)); // 0 fields
        expect(bytes.getUint8(1), equals(0x12)); // COMMIT signature
      });
    });
  });
}
