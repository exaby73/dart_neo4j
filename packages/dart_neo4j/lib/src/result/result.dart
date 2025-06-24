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

  @override
  String toString() {
    return 'Result{keys: $keys, consumed: $_isConsumed}';
  }
}

/// A completed result that contains all records in memory.
class CompletedResult {
  final List<String> _keys;
  final List<Record> _records;
  final ResultSummary _summary;

  /// Creates a new completed result.
  const CompletedResult._(this._keys, this._records, this._summary);

  /// Creates a completed result from a list of records and summary.
  factory CompletedResult.fromRecords(
    List<String> keys,
    List<Record> records,
    ResultSummary summary,
  ) {
    return CompletedResult._(keys, records, summary);
  }

  /// The keys (column names) for this result.
  List<String> get keys => List.unmodifiable(_keys);

  /// All records in this result.
  List<Record> get records => List.unmodifiable(_records);

  /// The summary for this result.
  ResultSummary get summary => _summary;

  /// The number of records in this result.
  int get length => _records.length;

  /// Whether this result is empty.
  bool get isEmpty => _records.isEmpty;

  /// Whether this result is not empty.
  bool get isNotEmpty => _records.isNotEmpty;

  /// Gets the record at the given index.
  Record operator [](int index) {
    return _records[index];
  }

  /// Returns the single record from this result.
  ///
  /// Throws [ClientException] if the result contains zero or more than one record.
  Record single() {
    if (_records.isEmpty) {
      throw ClientException('Expected single record but result was empty');
    }
    if (_records.length > 1) {
      throw ClientException(
        'Expected single record but got ${_records.length} records',
      );
    }
    return _records.first;
  }

  /// Returns the first record from this result, or null if empty.
  Record? firstOrNull() {
    return _records.isNotEmpty ? _records.first : null;
  }

  /// Returns the last record from this result, or null if empty.
  Record? lastOrNull() {
    return _records.isNotEmpty ? _records.last : null;
  }

  @override
  String toString() {
    return 'CompletedResult{keys: $keys, records: ${_records.length}, summary: $summary}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompletedResult &&
        other._keys.length == _keys.length &&
        other._records.length == _records.length &&
        other.summary == summary;
  }

  @override
  int get hashCode {
    return Object.hash(_keys.length, _records.length, summary);
  }
}
