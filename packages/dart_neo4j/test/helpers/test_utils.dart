import 'dart:async';
import 'dart:math';

import 'package:test/test.dart';

/// Utility functions for testing
class TestUtils {
  static final _random = Random();
  
  /// Generates a random string of given length
  static String randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(_random.nextInt(chars.length))),
    );
  }
  
  /// Generates a random integer within a range
  static int randomInt(int min, int max) {
    return min + _random.nextInt(max - min + 1);
  }
  
  /// Generates a random double within a range
  static double randomDouble(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }
  
  /// Generates random test data map
  static Map<String, dynamic> randomTestData() {
    return {
      'id': randomInt(1, 1000000),
      'name': randomString(10),
      'value': randomDouble(0.0, 100.0),
      'active': _random.nextBool(),
      'tags': List.generate(randomInt(1, 5), (_) => randomString(5)),
      'metadata': {
        'created': DateTime.now().millisecondsSinceEpoch,
        'category': randomString(8),
      },
    };
  }
  
  /// Waits for a condition to be true with timeout
  static Future<void> waitFor(
    bool Function() condition,
    String message, {
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final deadline = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(deadline)) {
      if (condition()) {
        return;
      }
      await Future.delayed(interval);
    }
    
    throw TimeoutException(message, timeout);
  }
  
  /// Measures execution time of a function
  static Future<Duration> measureTime(Future<void> Function() fn) async {
    final stopwatch = Stopwatch()..start();
    await fn();
    stopwatch.stop();
    return stopwatch.elapsed;
  }
  
  /// Runs a function multiple times and returns statistics
  static Future<PerformanceStats> measurePerformance(
    Future<void> Function() fn,
    int iterations,
  ) async {
    final times = <Duration>[];
    
    for (int i = 0; i < iterations; i++) {
      final time = await measureTime(fn);
      times.add(time);
    }
    
    times.sort((a, b) => a.compareTo(b));
    
    final total = times.fold(Duration.zero, (sum, time) => sum + time);
    final average = Duration(microseconds: total.inMicroseconds ~/ iterations);
    final median = times[iterations ~/ 2];
    final min = times.first;
    final max = times.last;
    
    return PerformanceStats(
      iterations: iterations,
      total: total,
      average: average,
      median: median,
      min: min,
      max: max,
    );
  }
  
  /// Retries a function until it succeeds or max attempts reached
  static Future<T> retry<T>(
    Future<T> Function() fn, {
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await fn();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        if (attempt < maxAttempts) {
          await Future.delayed(delay);
        }
      }
    }
    
    throw lastException!;
  }
  
  /// Creates a stress test that runs multiple concurrent operations
  static Future<void> stressTest(
    Future<void> Function() operation,
    int concurrency,
    Duration duration,
  ) async {
    final futures = <Future<void>>[];
    final deadline = DateTime.now().add(duration);
    
    for (int i = 0; i < concurrency; i++) {
      futures.add(_runUntilDeadline(operation, deadline));
    }
    
    await Future.wait(futures);
  }
  
  static Future<void> _runUntilDeadline(
    Future<void> Function() operation,
    DateTime deadline,
  ) async {
    while (DateTime.now().isBefore(deadline)) {
      await operation();
      // Small delay to prevent overwhelming the system
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }
  
  /// Validates that a function throws a specific exception
  static Future<void> expectThrows<T extends Exception>(
    Future<void> Function() fn,
    String message,
  ) async {
    try {
      await fn();
      fail('Expected $T to be thrown, but function completed normally');
    } catch (e) {
      if (e is! T) {
        fail('Expected $T to be thrown, but got ${e.runtimeType}: $e');
      }
      // Expected exception was thrown
    }
  }
  
  /// Creates a memory pressure test by allocating large amounts of data
  static Future<void> memoryPressureTest(
    Future<void> Function() operation, {
    int pressureMB = 100,
  }) async {
    // Allocate memory to create pressure
    final pressure = <List<int>>[];
    for (int i = 0; i < pressureMB; i++) {
      pressure.add(List.filled(1024 * 1024, i)); // 1MB chunks
    }
    
    try {
      await operation();
    } finally {
      pressure.clear();
    }
  }
}

/// Performance statistics from measuring execution times
class PerformanceStats {
  final int iterations;
  final Duration total;
  final Duration average;
  final Duration median;
  final Duration min;
  final Duration max;
  
  const PerformanceStats({
    required this.iterations,
    required this.total,
    required this.average,
    required this.median,
    required this.min,
    required this.max,
  });
  
  /// Calculates operations per second
  double get operationsPerSecond {
    return iterations / (total.inMicroseconds / Duration.microsecondsPerSecond);
  }
  
  @override
  String toString() {
    return 'PerformanceStats{'
        'iterations: $iterations, '
        'average: ${average.inMilliseconds}ms, '
        'median: ${median.inMilliseconds}ms, '
        'min: ${min.inMilliseconds}ms, '
        'max: ${max.inMilliseconds}ms, '
        'ops/sec: ${operationsPerSecond.toStringAsFixed(2)}'
        '}';
  }
}