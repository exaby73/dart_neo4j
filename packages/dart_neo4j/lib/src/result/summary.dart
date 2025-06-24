/// Summary information about a query execution.
class ResultSummary {
  final String _query;
  final Map<String, dynamic> _parameters;
  final String _queryType;
  final Map<String, dynamic> _counters;
  final Duration? _resultAvailableAfter;
  final Duration? _resultConsumedAfter;
  final String? _database;
  final List<String> _notifications;

  /// Creates a new result summary.
  const ResultSummary._({
    required String query,
    required Map<String, dynamic> parameters,
    required String queryType,
    required Map<String, dynamic> counters,
    Duration? resultAvailableAfter,
    Duration? resultConsumedAfter,
    String? database,
    required List<String> notifications,
  })  : _query = query,
        _parameters = parameters,
        _queryType = queryType,
        _counters = counters,
        _resultAvailableAfter = resultAvailableAfter,
        _resultConsumedAfter = resultConsumedAfter,
        _database = database,
        _notifications = notifications;

  /// Creates a result summary from Neo4j server metadata.
  factory ResultSummary.fromMetadata(
    String query,
    Map<String, dynamic> parameters,
    Map<String, dynamic>? metadata,
  ) {
    if (metadata == null) {
      return ResultSummary._(
        query: query,
        parameters: parameters,
        queryType: 'unknown',
        counters: const {},
        notifications: const [],
      );
    }

    final queryType = metadata['type'] as String? ?? 'unknown';
    final stats = metadata['stats'] as Map<String, dynamic>? ?? {};
    final resultAvailableAfter = _parseDuration(metadata['result_available_after']);
    final resultConsumedAfter = _parseDuration(metadata['result_consumed_after']);
    final database = metadata['db'] as String?;
    final notifications = (metadata['notifications'] as List?)?.cast<String>() ?? <String>[];

    return ResultSummary._(
      query: query,
      parameters: parameters,
      queryType: queryType,
      counters: stats,
      resultAvailableAfter: resultAvailableAfter,
      resultConsumedAfter: resultConsumedAfter,
      database: database,
      notifications: notifications,
    );
  }

  static Duration? _parseDuration(dynamic value) {
    if (value is int) {
      return Duration(milliseconds: value);
    }
    return null;
  }

  /// The query that was executed.
  String get query => _query;

  /// The parameters used in the query.
  Map<String, dynamic> get parameters => Map.unmodifiable(_parameters);

  /// The type of query (e.g., 'r' for read, 'w' for write).
  String get queryType => _queryType;

  /// The update counters from the query execution.
  Map<String, dynamic> get counters => Map.unmodifiable(_counters);

  /// The time until the result was available.
  Duration? get resultAvailableAfter => _resultAvailableAfter;

  /// The time until the result was consumed.
  Duration? get resultConsumedAfter => _resultConsumedAfter;

  /// The database where the query was executed.
  String? get database => _database;

  /// Notifications from the server about the query.
  List<String> get notifications => List.unmodifiable(_notifications);

  /// Whether this was a read-only query.
  bool get isReadOnly => _queryType == 'r';

  /// Whether this was a write query.
  bool get isWrite => _queryType == 'w' || _queryType == 'rw';

  /// The number of nodes created.
  int get nodesCreated => _counters['nodes-created'] as int? ?? 0;

  /// The number of nodes deleted.
  int get nodesDeleted => _counters['nodes-deleted'] as int? ?? 0;

  /// The number of relationships created.
  int get relationshipsCreated => _counters['relationships-created'] as int? ?? 0;

  /// The number of relationships deleted.
  int get relationshipsDeleted => _counters['relationships-deleted'] as int? ?? 0;

  /// The number of properties set.
  int get propertiesSet => _counters['properties-set'] as int? ?? 0;

  /// The number of labels added.
  int get labelsAdded => _counters['labels-added'] as int? ?? 0;

  /// The number of labels removed.
  int get labelsRemoved => _counters['labels-removed'] as int? ?? 0;

  /// The number of indexes added.
  int get indexesAdded => _counters['indexes-added'] as int? ?? 0;

  /// The number of indexes removed.
  int get indexesRemoved => _counters['indexes-removed'] as int? ?? 0;

  /// The number of constraints added.
  int get constraintsAdded => _counters['constraints-added'] as int? ?? 0;

  /// The number of constraints removed.
  int get constraintsRemoved => _counters['constraints-removed'] as int? ?? 0;

  /// Whether the query contained updates.
  bool get containsUpdates =>
      nodesCreated > 0 ||
      nodesDeleted > 0 ||
      relationshipsCreated > 0 ||
      relationshipsDeleted > 0 ||
      propertiesSet > 0 ||
      labelsAdded > 0 ||
      labelsRemoved > 0 ||
      indexesAdded > 0 ||
      indexesRemoved > 0 ||
      constraintsAdded > 0 ||
      constraintsRemoved > 0;

  /// Whether the query contained system updates (schema changes).
  bool get containsSystemUpdates =>
      indexesAdded > 0 ||
      indexesRemoved > 0 ||
      constraintsAdded > 0 ||
      constraintsRemoved > 0;

  @override
  String toString() {
    final buffer = StringBuffer('ResultSummary{');
    buffer.write('queryType: $queryType');
    if (containsUpdates) {
      buffer.write(', updates: {');
      final updates = <String>[];
      if (nodesCreated > 0) updates.add('nodes-created: $nodesCreated');
      if (nodesDeleted > 0) updates.add('nodes-deleted: $nodesDeleted');
      if (relationshipsCreated > 0) updates.add('relationships-created: $relationshipsCreated');
      if (relationshipsDeleted > 0) updates.add('relationships-deleted: $relationshipsDeleted');
      if (propertiesSet > 0) updates.add('properties-set: $propertiesSet');
      if (labelsAdded > 0) updates.add('labels-added: $labelsAdded');
      if (labelsRemoved > 0) updates.add('labels-removed: $labelsRemoved');
      buffer.write(updates.join(', '));
      buffer.write('}');
    }
    if (resultAvailableAfter != null) {
      buffer.write(', resultAvailableAfter: ${resultAvailableAfter!.inMilliseconds}ms');
    }
    if (database != null) {
      buffer.write(', database: $database');
    }
    buffer.write('}');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResultSummary &&
        other.query == query &&
        other.queryType == queryType &&
        other.database == database;
  }

  @override
  int get hashCode {
    return Object.hash(query, queryType, database);
  }
}