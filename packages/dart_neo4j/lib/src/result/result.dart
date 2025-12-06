import 'dart:async';

import 'package:dart_neo4j/src/exceptions/neo4j_exception.dart';
import 'package:dart_neo4j/src/result/record.dart';
import 'package:dart_neo4j/src/result/summary.dart';

/// The result of a Neo4j query execution.
class Result {
  final String _query;
  final Map<String, dynamic> _parameters;
  final List<String> _keys;
  final StreamController<Record> _recordController;
  final Completer<ResultSummary> _summaryCompleter;

  bool _isConsumed = false;

  /// Creates a new result.
  Result._(this._query, this._parameters, this._keys)
    : _recordController = StreamController<Record>(),
      _summaryCompleter = Completer<ResultSummary>();

  /// Creates a result for a query.
  factory Result.forQuery(
    String query,
    Map<String, dynamic> parameters,
    List<String> keys,
  ) {
    return Result._(query, parameters, keys);
  }

  /// The query that produced this result.
  String get query => _query;

  /// The parameters used in the query.
  Map<String, dynamic> get parameters => Map.unmodifiable(_parameters);

  /// The keys (column names) for this result.
  List<String> get keys => List.unmodifiable(_keys);

  /// Whether this result has been consumed.
  bool get isConsumed => _isConsumed;

  /// Future that completes when the query has finished executing.
  Future<void> get done => _summaryCompleter.future;

  /// Stream of records from this result.
  ///
  /// Can only be listened to once. Use [list()] if you need to access records multiple times.
  Stream<Record> records() {
    if (_isConsumed) {
      throw ClientException('Result has already been consumed');
    }
    _isConsumed = true;
    return _recordController.stream;
  }

  /// Consumes all records and returns them as a list.
  ///
  /// This is a convenience method that consumes the entire result stream.
  Future<List<Record>> list() async {
    final recordList = <Record>[];
    await for (final record in records()) {
      recordList.add(record);
    }
    return recordList;
  }

  /// Returns the single record from this result.
  ///
  /// Throws [ClientException] if the result contains zero or more than one record.
  Future<Record> single() async {
    final recordList = await list();
    if (recordList.isEmpty) {
      throw ClientException('Expected single record but result was empty');
    }
    if (recordList.length > 1) {
      throw ClientException(
        'Expected single record but got ${recordList.length} records',
      );
    }
    return recordList.first;
  }

  /// Returns the first record from this result, or null if empty.
  Future<Record?> firstOrNull() async {
    await for (final record in records()) {
      return record;
    }
    return null;
  }

  /// Returns the summary for this result.
  ///
  /// The summary is only available after all records have been consumed.
  Future<ResultSummary> summary() {
    return _summaryCompleter.future;
  }

  /// Consumes all records and returns only the summary.
  ///
  /// Use this when you don't need the records, only the execution statistics.
  Future<ResultSummary> consume() async {
    if (!_isConsumed) {
      await for (final _ in records()) {
        // Consume all records without storing them
      }
    }
    return summary();
  }

  @override
  String toString() {
    return 'Result{keys: $keys, consumed: $_isConsumed}';
  }
}

/// [Result] methods for internal use only.
extension ResultPrivateImpl on Result {
  /// Adds a record to this result (internal use only).
  void addRecord(Record record) {
    if (!_recordController.isClosed) {
      _recordController.add(record);
    }
  }

  /// Adds a record from data map (internal use only).
  void addRecordFromData(Map<String, dynamic> data) {
    final record = Record.fromData(data, _keys);
    addRecord(record);
  }

  /// Marks the result as complete with a summary (internal use only).
  void complete(ResultSummary summary) {
    if (!_recordController.isClosed) {
      _recordController.close();
    }
    if (!_summaryCompleter.isCompleted) {
      _summaryCompleter.complete(summary);
    }
  }

  /// Marks the result as failed with an error (internal use only).
  void completeWithError(Object error, [StackTrace? stackTrace]) {
    if (!_recordController.isClosed) {
      _recordController.addError(error, stackTrace);
      _recordController.close();
    }
    if (!_summaryCompleter.isCompleted) {
      _summaryCompleter.completeError(error, stackTrace);
    }
  }
}
