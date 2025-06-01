import 'package:dart_bolt/dart_bolt.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    registerBoltStructures();
  });

  tearDown(() {
    PsStructureRegistry.clear();
    registerBoltStructures();
  });

  group('BoltLegacyDateTime', () {
    test('creates legacy datetime structure', () {
      final legacyDateTime = BoltLegacyDateTime(
        PsInt.compact(
          1609462800,
        ), // 2021-01-01T01:00:00+01:00 (with offset added)
        PsInt.compact(123456789),
        PsInt.compact(3600), // +1 hour offset
      );

      expect(legacyDateTime.numberOfFields, equals(3));
      expect(legacyDateTime.tagByte, equals(0x46));
      expect(legacyDateTime.seconds.dartValue, equals(1609462800));
      expect(legacyDateTime.nanoseconds.dartValue, equals(123456789));
      expect(legacyDateTime.tzOffsetSeconds.dartValue, equals(3600));
    });

    test('serializes and deserializes correctly', () {
      final original = BoltLegacyDateTime(
        PsInt.compact(0), // Unix epoch with offset
        PsInt.compact(0),
        PsInt.compact(0), // UTC
      );

      final bytes = original.toByteData();
      expect(bytes.getUint8(0), equals(0xB3)); // 3 fields
      expect(bytes.getUint8(1), equals(0x46)); // Legacy DateTime tag

      final parsed =
          PsDataType.fromPackStreamBytes(bytes) as BoltLegacyDateTime;
      expect(parsed.seconds.dartValue, equals(0));
      expect(parsed.nanoseconds.dartValue, equals(0));
      expect(parsed.tzOffsetSeconds.dartValue, equals(0));
    });

    test('creates from parsed values', () {
      final values = <PsDataType>[
        PsInt.compact(946684800), // 2000-01-01
        PsInt.compact(999999999),
        PsInt.compact(-18000), // -5 hours (EST)
      ];

      final legacyDateTime = BoltLegacyDateTime.fromValues(values);
      expect(legacyDateTime.seconds.dartValue, equals(946684800));
      expect(legacyDateTime.nanoseconds.dartValue, equals(999999999));
      expect(legacyDateTime.tzOffsetSeconds.dartValue, equals(-18000));
    });

    test('throws error for invalid field count', () {
      expect(
        () => BoltLegacyDateTime.fromValues(<PsDataType>[
          PsInt.compact(1),
          PsInt.compact(2),
        ]),
        throwsArgumentError,
      );
    });
  });

  group('BoltLegacyDateTimeZoneId', () {
    test('creates legacy datetime with zone id structure', () {
      final legacyDateTimeZoneId = BoltLegacyDateTimeZoneId(
        PsInt.compact(1609462800), // With offset included
        PsInt.compact(987654321),
        PsString('America/New_York'),
      );

      expect(legacyDateTimeZoneId.numberOfFields, equals(3));
      expect(legacyDateTimeZoneId.tagByte, equals(0x66));
      expect(legacyDateTimeZoneId.seconds.dartValue, equals(1609462800));
      expect(legacyDateTimeZoneId.nanoseconds.dartValue, equals(987654321));
      expect(legacyDateTimeZoneId.tzId.dartValue, equals('America/New_York'));
    });

    test('serializes and deserializes correctly', () {
      final original = BoltLegacyDateTimeZoneId(
        PsInt.compact(0),
        PsInt.compact(0),
        PsString('UTC'),
      );

      final bytes = original.toByteData();
      expect(bytes.getUint8(0), equals(0xB3)); // 3 fields
      expect(bytes.getUint8(1), equals(0x66)); // Legacy DateTimeZoneId tag

      final parsed =
          PsDataType.fromPackStreamBytes(bytes) as BoltLegacyDateTimeZoneId;
      expect(parsed.seconds.dartValue, equals(0));
      expect(parsed.tzId.dartValue, equals('UTC'));
    });

    test('creates from parsed values', () {
      final values = <PsDataType>[
        PsInt.compact(1577836800), // 2020-01-01
        PsInt.compact(500000000),
        PsString('Europe/London'),
      ];

      final legacyDateTimeZoneId = BoltLegacyDateTimeZoneId.fromValues(values);
      expect(legacyDateTimeZoneId.seconds.dartValue, equals(1577836800));
      expect(legacyDateTimeZoneId.nanoseconds.dartValue, equals(500000000));
      expect(legacyDateTimeZoneId.tzId.dartValue, equals('Europe/London'));
    });

    test('throws error for invalid field count', () {
      expect(
        () =>
            BoltLegacyDateTimeZoneId.fromValues(<PsDataType>[PsInt.compact(1)]),
        throwsArgumentError,
      );
    });
  });
}
