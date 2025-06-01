import 'package:dart_packstream/dart_packstream.dart';

/// Duration structure representing a temporal amount.
///
/// Tag byte: 0x45 (69 decimal)
/// Fields: 4
class BoltDuration extends PsStructure {
  /// Creates a Duration structure.
  ///
  /// [months] - number of months.
  /// [days] - number of days.
  /// [seconds] - number of seconds.
  /// [nanoseconds] - nanoseconds component (0-999,999,999).
  BoltDuration(PsInt months, PsInt days, PsInt seconds, PsInt nanoseconds)
    : super(4, 0x45, [months, days, seconds, nanoseconds]); // 'E'

  /// Creates a Duration from parsed values.
  factory BoltDuration.fromValues(List<PsDataType> values) {
    if (values.length != 4) {
      throw ArgumentError(
        'Duration structure must have 4 fields, got ${values.length}',
      );
    }

    return BoltDuration(
      values[0] as PsInt,
      values[1] as PsInt,
      values[2] as PsInt,
      values[3] as PsInt,
    );
  }

  /// Number of months.
  PsInt get months => values[0] as PsInt;

  /// Number of days.
  PsInt get days => values[1] as PsInt;

  /// Number of seconds.
  PsInt get seconds => values[2] as PsInt;

  /// Nanoseconds component.
  PsInt get nanoseconds => values[3] as PsInt;
}
