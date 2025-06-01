import 'package:dart_packstream/dart_packstream.dart';

/// Point2D structure representing a point in a 2D coordinate reference system.
///
/// Tag byte: 0x58 (88 decimal)
/// Fields: 3
class BoltPoint2D extends PsStructure {
  /// Creates a Point2D structure.
  ///
  /// [srid] - spatial reference identifier.
  /// [x] - x coordinate.
  /// [y] - y coordinate.
  BoltPoint2D(PsInt srid, PsFloat x, PsFloat y)
    : super(3, 0x58, [srid, x, y]); // 'X'

  /// Creates a Point2D from parsed values.
  factory BoltPoint2D.fromValues(List<PsDataType> values) {
    if (values.length != 3) {
      throw ArgumentError(
        'Point2D structure must have 3 fields, got ${values.length}',
      );
    }

    return BoltPoint2D(
      values[0] as PsInt,
      values[1] as PsFloat,
      values[2] as PsFloat,
    );
  }

  /// Spatial reference identifier.
  PsInt get srid => values[0] as PsInt;

  /// X coordinate.
  PsFloat get x => values[1] as PsFloat;

  /// Y coordinate.
  PsFloat get y => values[2] as PsFloat;
}
