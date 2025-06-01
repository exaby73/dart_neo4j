import 'package:dart_packstream/dart_packstream.dart';

/// LocalTime structure representing an instant capturing the time of day, but neither the date nor time zone.
///
/// Tag byte: 0x74 (116 decimal)
/// Fields: 1
class BoltLocalTime extends PsStructure {
  /// Creates a LocalTime structure.
  ///
  /// [nanoseconds] - nanoseconds since midnight.
  BoltLocalTime(PsInt nanoseconds) : super(1, 0x74, [nanoseconds]); // 't'

  /// Creates a LocalTime from parsed values.
  factory BoltLocalTime.fromValues(List<PsDataType> values) {
    if (values.length != 1) {
      throw ArgumentError(
        'LocalTime structure must have 1 field, got ${values.length}',
      );
    }

    return BoltLocalTime(values[0] as PsInt);
  }

  /// Nanoseconds since midnight.
  PsInt get nanoseconds => values[0] as PsInt;
}
