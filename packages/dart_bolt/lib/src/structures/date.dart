import 'package:dart_packstream/dart_packstream.dart';

/// Date structure representing a date without a time-zone in the ISO-8601 calendar system.
///
/// Tag byte: 0x44 (68 decimal)
/// Fields: 1
class BoltDate extends PsStructure {
  /// Creates a Date structure.
  ///
  /// [days] - days since Unix epoch (0 = 1970-01-01).
  BoltDate(PsInt days) : super(1, 0x44, [days]); // 'D'

  /// Creates a Date from parsed values.
  factory BoltDate.fromValues(List<PsDataType> values) {
    if (values.length != 1) {
      throw ArgumentError(
        'Date structure must have 1 field, got ${values.length}',
      );
    }

    return BoltDate(values[0] as PsInt);
  }

  /// Days since Unix epoch.
  PsInt get days => values[0] as PsInt;
}
