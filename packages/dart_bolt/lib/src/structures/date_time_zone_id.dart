import 'package:dart_packstream/dart_packstream.dart';

/// DateTimeZoneId structure representing an instant capturing the date, time, and time zone.
/// The time zone information is specified with a zone identifier.
///
/// Tag byte: 0x69 (105 decimal)
/// Fields: 3
class BoltDateTimeZoneId extends PsStructure {
  /// Creates a DateTimeZoneId structure.
  ///
  /// [seconds] - seconds since Unix epoch.
  /// [nanoseconds] - nanoseconds component (0-999,999,999).
  /// [tzId] - timezone name as understood by the timezone database.
  BoltDateTimeZoneId(PsInt seconds, PsInt nanoseconds, PsString tzId)
    : super(3, 0x69, [seconds, nanoseconds, tzId]); // 'i'

  /// Creates a DateTimeZoneId from parsed values.
  factory BoltDateTimeZoneId.fromValues(List<PsDataType> values) {
    if (values.length != 3) {
      throw ArgumentError(
        'DateTimeZoneId structure must have 3 fields, got ${values.length}',
      );
    }

    return BoltDateTimeZoneId(
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
