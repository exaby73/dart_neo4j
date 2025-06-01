import 'package:dart_packstream/dart_packstream.dart';

/// Legacy DateTime structure for compatibility with older Bolt versions.
///
/// Tag byte: 0x46 (70 decimal)
/// Fields: 3
class BoltLegacyDateTime extends PsStructure {
  /// Creates a Legacy DateTime structure.
  ///
  /// [seconds] - seconds since Unix epoch.
  /// [nanoseconds] - nanoseconds component (0-999,999,999).
  /// [tzOffsetSeconds] - offset in seconds from UTC.
  BoltLegacyDateTime(PsInt seconds, PsInt nanoseconds, PsInt tzOffsetSeconds)
    : super(3, 0x46, [seconds, nanoseconds, tzOffsetSeconds]); // 'F'

  /// Creates a Legacy DateTime from parsed values.
  factory BoltLegacyDateTime.fromValues(List<PsDataType> values) {
    if (values.length != 3) {
      throw ArgumentError(
        'Legacy DateTime structure must have 3 fields, got ${values.length}',
      );
    }

    return BoltLegacyDateTime(
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
