import 'package:dart_packstream/dart_packstream.dart';

/// Node structure representing a snapshot of a node within a graph database.
///
/// Tag byte: 0x4E (78 decimal)
/// Fields: 4 for version 5.0+, 3 for earlier versions
class BoltNode extends PsStructure {
  /// Creates a Node structure.
  ///
  /// For Bolt 5.0+: [id], [labels], [properties], [elementId]
  /// For earlier versions: [id], [labels], [properties]
  BoltNode(
    PsInt id,
    PsList labels,
    PsDictionary properties, {
    PsString? elementId,
  }) : super(
         elementId != null ? 4 : 3,
         0x4E, // 'N'
         elementId != null
             ? [id, labels, properties, elementId]
             : [id, labels, properties],
       );

  /// Creates a Node from parsed values.
  factory BoltNode.fromValues(List<PsDataType> values) {
    if (values.length != 3 && values.length != 4) {
      throw ArgumentError(
        'Node structure must have 3 or 4 fields, got ${values.length}',
      );
    }

    final id = values[0] as PsInt;
    final labels = values[1] as PsList;
    final properties = values[2] as PsDictionary;
    final elementId = values.length == 4 ? values[3] as PsString : null;

    return BoltNode(id, labels, properties, elementId: elementId);
  }

  /// The node ID.
  PsInt get id => values[0] as PsInt;

  /// The node labels.
  PsList get labels => values[1] as PsList;

  /// The node properties.
  PsDictionary get properties => values[2] as PsDictionary;

  /// The element ID (Bolt 5.0+).
  PsString? get elementId => values.length == 4 ? values[3] as PsString : null;

  /// Whether this node has an element ID (indicates Bolt 5.0+).
  bool get hasElementId => values.length == 4;
}
