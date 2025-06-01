import 'package:dart_packstream/dart_packstream.dart';

/// Path structure representing an alternating sequence of nodes and relationships.
///
/// Tag byte: 0x50 (80 decimal)
/// Fields: 3
class BoltPath extends PsStructure {
  /// Creates a Path structure.
  ///
  /// [nodes] List of Node structures
  /// [rels] List of UnboundRelationship structures
  /// [indices] List of integers describing how to construct the path
  BoltPath(PsList nodes, PsList rels, PsList indices)
    : super(
        3,
        0x50, // 'P'
        [nodes, rels, indices],
      );

  /// Creates a Path from parsed values.
  factory BoltPath.fromValues(List<PsDataType> values) {
    if (values.length != 3) {
      throw ArgumentError(
        'Path structure must have 3 fields, got ${values.length}',
      );
    }

    final nodes = values[0] as PsList;
    final rels = values[1] as PsList;
    final indices = values[2] as PsList;

    return BoltPath(nodes, rels, indices);
  }

  /// The nodes in the path.
  PsList get nodes => values[0] as PsList;

  /// The relationships in the path.
  PsList get relationships => values[1] as PsList;

  /// The indices describing how to construct the path.
  PsList get indices => values[2] as PsList;
}
