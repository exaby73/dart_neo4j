import 'package:dart_packstream/dart_packstream.dart';

/// LocalDateTime structure representing an instant capturing the date and time but not the time zone.
///
/// Tag byte: 0x64 (100 decimal)
/// Fields: 2
class BoltLocalDateTime extends PsStructure {
  /// Creates a LocalDateTime structure.
  ///
  /// [seconds] - seconds since Unix epoch.
  /// [nanoseconds] - nanoseconds component (0-999,999,999).
  BoltLocalDateTime(PsInt seconds, PsInt nanoseconds)
    : super(2, 0x64, [seconds, nanoseconds]); // 'd'

  /// Creates a LocalDateTime from parsed values.
  factory BoltLocalDateTime.fromValues(List<PsDataType> values) {
    if (values.length != 2) {
      throw ArgumentError(
        'LocalDateTime structure must have 2 fields, got ${values.length}',
      );
    }

    return BoltLocalDateTime(values[0] as PsInt, values[1] as PsInt);
  }

  /// Seconds since Unix epoch.
  PsInt get seconds => values[0] as PsInt;

  /// Nanoseconds component.
  PsInt get nanoseconds => values[1] as PsInt;
}
