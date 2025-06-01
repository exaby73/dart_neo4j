import 'package:dart_packstream/dart_packstream.dart';

/// DateTime structure representing an instant capturing the date, time, and time zone.
/// The time zone information is specified with a zone offset.
///
/// Tag byte: 0x49 (73 decimal)
/// Fields: 3
class BoltDateTime extends PsStructure {
  /// Creates a DateTime structure.
  ///
  /// [seconds] - seconds since Unix epoch.
  /// [nanoseconds] - nanoseconds component (0-999,999,999).
  /// [tzOffsetSeconds] - offset in seconds from UTC.
  BoltDateTime(PsInt seconds, PsInt nanoseconds, PsInt tzOffsetSeconds)
    : super(3, 0x49, [seconds, nanoseconds, tzOffsetSeconds]); // 'I'

  /// Creates a DateTime from parsed values.
  factory BoltDateTime.fromValues(List<PsDataType> values) {
    if (values.length != 3) {
      throw ArgumentError(
        'DateTime structure must have 3 fields, got ${values.length}',
      );
    }

    return BoltDateTime(
      values[0] as PsInt,
      values[1] as PsInt,
      values[2] as PsInt,
    );
  }

  /// Seconds since Unix epoch.
  PsInt get seconds => values[0] as PsInt;

  /// Nanoseconds component.
  PsInt get nanoseconds => values[1] as PsInt;

  /// Timezone offset in seconds from UTC.
  PsInt get tzOffsetSeconds => values[2] as PsInt;
}
