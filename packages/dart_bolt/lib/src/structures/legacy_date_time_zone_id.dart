import 'package:dart_packstream/dart_packstream.dart';

/// Legacy DateTimeZoneId structure for compatibility with older Bolt versions.
///
/// Tag byte: 0x66 (102 decimal)
/// Fields: 3
class BoltLegacyDateTimeZoneId extends PsStructure {
  /// Creates a Legacy DateTimeZoneId structure.
  ///
  /// [seconds] - seconds since Unix epoch.
  /// [nanoseconds] - nanoseconds component (0-999,999,999).
  /// [tzId] - timezone name as understood by the timezone database.
  BoltLegacyDateTimeZoneId(PsInt seconds, PsInt nanoseconds, PsString tzId)
    : super(3, 0x66, [seconds, nanoseconds, tzId]); // 'f'

  /// Creates a Legacy DateTimeZoneId from parsed values.
  factory BoltLegacyDateTimeZoneId.fromValues(List<PsDataType> values) {
    if (values.length != 3) {
      throw ArgumentError(
        'Legacy DateTimeZoneId structure must have 3 fields, got ${values.length}',
      );
    }

    return BoltLegacyDateTimeZoneId(
      values[0] as PsInt,
      values[1] as PsInt,
      values[2] as PsString,
    );
  }

  /// Seconds since Unix epoch.
  PsInt get seconds => values[0] as PsInt;

  /// Nanoseconds component.
  PsInt get nanoseconds => values[1] as PsInt;

  /// Timezone ID.
  PsString get tzId => values[2] as PsString;
}
