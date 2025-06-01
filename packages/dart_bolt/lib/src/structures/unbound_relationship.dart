import 'package:dart_packstream/dart_packstream.dart';

/// UnboundRelationship structure representing a relationship without start or end node ID.
/// Used internally for Path serialization.
///
/// Tag byte: 0x72 (114 decimal)
/// Fields: 4 for version 5.0+, 3 for earlier versions
class BoltUnboundRelationship extends PsStructure {
  /// Creates an UnboundRelationship structure.
  ///
  /// For Bolt 5.0+: [id], [type], [properties], [elementId]
  /// For earlier versions: [id], [type], [properties]
  BoltUnboundRelationship(
    PsInt id,
    PsString type,
    PsDictionary properties, {
    PsString? elementId,
  }) : super(
         elementId != null ? 4 : 3,
         0x72, // 'r'
         elementId != null
             ? [id, type, properties, elementId]
             : [id, type, properties],
       );

  /// Creates an UnboundRelationship from parsed values.
  factory BoltUnboundRelationship.fromValues(List<PsDataType> values) {
    if (values.length != 3 && values.length != 4) {
      throw ArgumentError(
        'UnboundRelationship structure must have 3 or 4 fields, got ${values.length}',
      );
    }

    final id = values[0] as PsInt;
    final type = values[1] as PsString;
    final properties = values[2] as PsDictionary;
    final elementId = values.length == 4 ? values[3] as PsString : null;

    return BoltUnboundRelationship(id, type, properties, elementId: elementId);
  }

  /// The relationship ID.
  PsInt get id => values[0] as PsInt;

  /// The relationship type.
  PsString get type => values[1] as PsString;

  /// The relationship properties.
  PsDictionary get properties => values[2] as PsDictionary;

  /// The element ID (Bolt 5.0+).
  PsString? get elementId => values.length == 4 ? values[3] as PsString : null;

  /// Whether this relationship has an element ID (indicates Bolt 5.0+).
  bool get hasElementId => values.length == 4;
}
