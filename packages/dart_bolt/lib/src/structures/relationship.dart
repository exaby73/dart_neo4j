import 'package:dart_packstream/dart_packstream.dart';

/// Relationship structure representing a snapshot of a relationship within a graph database.
///
/// Tag byte: 0x52 (82 decimal)
/// Fields: 8 for version 5.0+, 5 for earlier versions
class BoltRelationship extends PsStructure {
  /// Creates a Relationship structure.
  ///
  /// For Bolt 5.0+: [id], [startNodeId], [endNodeId], [type], [properties],
  ///                 [elementId], [startNodeElementId], [endNodeElementId]
  /// For earlier versions: [id], [startNodeId], [endNodeId], [type], [properties]
  BoltRelationship(
    PsInt id,
    PsInt startNodeId,
    PsInt endNodeId,
    PsString type,
    PsDictionary properties, {
    PsString? elementId,
    PsString? startNodeElementId,
    PsString? endNodeElementId,
  }) : super(
         elementId != null ? 8 : 5,
         0x52, // 'R'
         elementId != null
             ? [
                 id,
                 startNodeId,
                 endNodeId,
                 type,
                 properties,
                 elementId,
                 startNodeElementId!,
                 endNodeElementId!,
               ]
             : [id, startNodeId, endNodeId, type, properties],
       );

  /// Creates a Relationship from parsed values.
  factory BoltRelationship.fromValues(List<PsDataType> values) {
    if (values.length != 5 && values.length != 8) {
      throw ArgumentError(
        'Relationship structure must have 5 or 8 fields, got ${values.length}',
      );
    }

    final id = values[0] as PsInt;
    final startNodeId = values[1] as PsInt;
    final endNodeId = values[2] as PsInt;
    final type = values[3] as PsString;
    final properties = values[4] as PsDictionary;

    if (values.length == 8) {
      final elementId = values[5] as PsString;
      final startNodeElementId = values[6] as PsString;
      final endNodeElementId = values[7] as PsString;
      return BoltRelationship(
        id,
        startNodeId,
        endNodeId,
        type,
        properties,
        elementId: elementId,
        startNodeElementId: startNodeElementId,
        endNodeElementId: endNodeElementId,
      );
    }

    return BoltRelationship(id, startNodeId, endNodeId, type, properties);
  }

  /// The relationship ID.
  PsInt get id => values[0] as PsInt;

  /// The start node ID.
  PsInt get startNodeId => values[1] as PsInt;

  /// The end node ID.
  PsInt get endNodeId => values[2] as PsInt;

  /// The relationship type.
  PsString get type => values[3] as PsString;

  /// The relationship properties.
  PsDictionary get properties => values[4] as PsDictionary;

  /// The element ID (Bolt 5.0+).
  PsString? get elementId => values.length == 8 ? values[5] as PsString : null;

  /// The start node element ID (Bolt 5.0+).
  PsString? get startNodeElementId =>
      values.length == 8 ? values[6] as PsString : null;

  /// The end node element ID (Bolt 5.0+).
  PsString? get endNodeElementId =>
      values.length == 8 ? values[7] as PsString : null;

  /// Whether this relationship has element IDs (indicates Bolt 5.0+).
  bool get hasElementIds => values.length == 8;
}
