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

  group('BoltDate', () {
    test('creates date structure', () {
      final date = BoltDate(PsInt.compact(18628)); // 2021-01-01

      expect(date.numberOfFields, equals(1));
      expect(date.tagByte, equals(0x44));
      expect(date.days.dartValue, equals(18628));
    });

    test('serializes and deserializes correctly', () {
      final original = BoltDate(PsInt.compact(0)); // 1970-01-01

      final bytes = original.toByteData();
      expect(bytes.getUint8(0), equals(0xB1)); // 1 field
      expect(bytes.getUint8(1), equals(0x44)); // Date tag

      final parsed = PsDataType.fromPackStreamBytes(bytes) as BoltDate;
      expect(parsed.days.dartValue, equals(0));
    });
  });

  group('BoltTime', () {
    test('creates time structure', () {
      final time = BoltTime(
        PsInt.compact(43200000000000), // 12:00:00 in nanoseconds
        PsInt.compact(3600), // +1 hour offset
      );

      expect(time.numberOfFields, equals(2));
      expect(time.tagByte, equals(0x54));
      expect(time.nanoseconds.dartValue, equals(43200000000000));
      expect(time.tzOffsetSeconds.dartValue, equals(3600));
    });

    test('serializes and deserializes correctly', () {
      final original = BoltTime(
        PsInt.compact(0), // midnight
        PsInt.compact(0), // UTC
      );

      final bytes = original.toByteData();
      expect(bytes.getUint8(0), equals(0xB2)); // 2 fields
      expect(bytes.getUint8(1), equals(0x54)); // Time tag

      final parsed = PsDataType.fromPackStreamBytes(bytes) as BoltTime;
      expect(parsed.nanoseconds.dartValue, equals(0));
      expect(parsed.tzOffsetSeconds.dartValue, equals(0));
    });
  });

  group('BoltLocalTime', () {
    test('creates local time structure', () {
      final localTime = BoltLocalTime(
        PsInt.compact(43200000000000),
      ); // 12:00:00

      expect(localTime.numberOfFields, equals(1));
      expect(localTime.tagByte, equals(0x74));
      expect(localTime.nanoseconds.dartValue, equals(43200000000000));
    });
  });

  group('BoltDateTime', () {
    test('creates datetime structure', () {
      final dateTime = BoltDateTime(
        PsInt.compact(1609459200), // 2021-01-01T00:00:00Z
        PsInt.compact(0),
        PsInt.compact(3600), // +1 hour
      );

      expect(dateTime.numberOfFields, equals(3));
      expect(dateTime.tagByte, equals(0x49));
      expect(dateTime.seconds.dartValue, equals(1609459200));
      expect(dateTime.nanoseconds.dartValue, equals(0));
      expect(dateTime.tzOffsetSeconds.dartValue, equals(3600));
    });
  });

  group('BoltDateTimeZoneId', () {
    test('creates datetime with zone id structure', () {
      final dateTimeZoneId = BoltDateTimeZoneId(
        PsInt.compact(1609459200),
        PsInt.compact(123456789),
        PsString('Europe/Berlin'),
      );

      expect(dateTimeZoneId.numberOfFields, equals(3));
      expect(dateTimeZoneId.tagByte, equals(0x69));
      expect(dateTimeZoneId.seconds.dartValue, equals(1609459200));
      expect(dateTimeZoneId.nanoseconds.dartValue, equals(123456789));
      expect(dateTimeZoneId.tzId.dartValue, equals('Europe/Berlin'));
    });
  });

  group('BoltLocalDateTime', () {
    test('creates local datetime structure', () {
      final localDateTime = BoltLocalDateTime(
        PsInt.compact(1609459200),
        PsInt.compact(987654321),
      );

      expect(localDateTime.numberOfFields, equals(2));
      expect(localDateTime.tagByte, equals(0x64));
      expect(localDateTime.seconds.dartValue, equals(1609459200));
      expect(localDateTime.nanoseconds.dartValue, equals(987654321));
    });
  });

  group('BoltDuration', () {
    test('creates duration structure', () {
      final duration = BoltDuration(
        PsInt.compact(12), // months
        PsInt.compact(30), // days
        PsInt.compact(3600), // seconds
        PsInt.compact(500000000), // nanoseconds
      );

      expect(duration.numberOfFields, equals(4));
      expect(duration.tagByte, equals(0x45));
      expect(duration.months.dartValue, equals(12));
      expect(duration.days.dartValue, equals(30));
      expect(duration.seconds.dartValue, equals(3600));
      expect(duration.nanoseconds.dartValue, equals(500000000));
    });

    test('serializes and deserializes correctly', () {
      final original = BoltDuration(
        PsInt.compact(0),
        PsInt.compact(1),
        PsInt.compact(0),
        PsInt.compact(0),
      );

      final bytes = original.toByteData();
      expect(bytes.getUint8(0), equals(0xB4)); // 4 fields
      expect(bytes.getUint8(1), equals(0x45)); // Duration tag

      final parsed = PsDataType.fromPackStreamBytes(bytes) as BoltDuration;
      expect(parsed.days.dartValue, equals(1));
    });
  });
}
