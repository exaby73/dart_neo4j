import 'package:dart_packstream/dart_packstream.dart';

/// Point3D structure representing a point in a 3D coordinate reference system.
///
/// Tag byte: 0x59 (89 decimal)
/// Fields: 4
class BoltPoint3D extends PsStructure {
  /// Creates a Point3D structure.
  ///
  /// [srid] - spatial reference identifier.
  /// [x] - x coordinate.
  /// [y] - y coordinate.
  /// [z] - z coordinate.
  BoltPoint3D(PsInt srid, PsFloat x, PsFloat y, PsFloat z)
    : super(4, 0x59, [srid, x, y, z]); // 'Y'

  /// Creates a Point3D from parsed values.
  factory BoltPoint3D.fromValues(List<PsDataType> values) {
    if (values.length != 4) {
      throw ArgumentError(
        'Point3D structure must have 4 fields, got ${values.length}',
      );
    }

    return BoltPoint3D(
      values[0] as PsInt,
      values[1] as PsFloat,
      values[2] as PsFloat,
      values[3] as PsFloat,
    );
  }

  /// Spatial reference identifier.
  PsInt get srid => values[0] as PsInt;

  /// X coordinate.
  PsFloat get x => values[1] as PsFloat;

  /// Y coordinate.
  PsFloat get y => values[2] as PsFloat;

  /// Z coordinate.
  PsFloat get z => values[3] as PsFloat;
}
