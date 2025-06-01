import 'package:dart_packstream/dart_packstream.dart';

/// Time structure representing an instant capturing the time of day and timezone, but not the date.
///
/// Tag byte: 0x54 (84 decimal)
/// Fields: 2
class BoltTime extends PsStructure {
  /// Creates a Time structure.
  ///
  /// [nanoseconds] - nanoseconds since midnight (not UTC).
  /// [tzOffsetSeconds] - offset in seconds from UTC.
  BoltTime(PsInt nanoseconds, PsInt tzOffsetSeconds)
    : super(2, 0x54, [nanoseconds, tzOffsetSeconds]); // 'T'

  /// Creates a Time from parsed values.
  factory BoltTime.fromValues(List<PsDataType> values) {
    if (values.length != 2) {
      throw ArgumentError(
        'Time structure must have 2 fields, got ${values.length}',
      );
    }

    return BoltTime(values[0] as PsInt, values[1] as PsInt);
  }

  /// Nanoseconds since midnight.
  PsInt get nanoseconds => values[0] as PsInt;

  /// Timezone offset in seconds from UTC.
  PsInt get tzOffsetSeconds => values[1] as PsInt;
}
