import 'dart:io';

import 'package:dart_neo4j/src/auth/basic_auth.dart';

/// Configuration for Neo4j test environments
class TestConfig {
  // Single Neo4j instance configuration (for bolt:// tests)
  static String get boltUri => Platform.environment['NEO4J_SINGLE_URI'] ?? 'bolt://localhost:7687';
  static String get neo4jUri => Platform.environment['NEO4J_SINGLE_NEO4J_URI'] ?? 'neo4j://localhost:7687';
  static String get singleUser => Platform.environment['NEO4J_SINGLE_USER'] ?? 'neo4j';
  static String get singlePassword => Platform.environment['NEO4J_SINGLE_PASSWORD'] ?? 'password';
  
  // Cluster configuration (for neo4j:// routing tests)
  static String get neo4jClusterUri => Platform.environment['NEO4J_CLUSTER_URI'] ?? 'neo4j://localhost:7688';
  static String get clusterUser => Platform.environment['NEO4J_CLUSTER_USER'] ?? 'neo4j';
  static String get clusterPassword => Platform.environment['NEO4J_CLUSTER_PASSWORD'] ?? 'password';
  
  // Auth token for tests
  static BasicAuth get auth => BasicAuth(singleUser, singlePassword);
  
  // Test configuration
  static int get testTimeout => int.tryParse(Platform.environment['TEST_TIMEOUT'] ?? '30000') ?? 30000;
  static int get concurrentSessions => int.tryParse(Platform.environment['TEST_CONCURRENT_SESSIONS'] ?? '50') ?? 50;
  static int get performanceQueries => int.tryParse(Platform.environment['TEST_PERFORMANCE_QUERIES'] ?? '1000') ?? 1000;
  
  // Docker service URLs for health checks
  static String get singleHealthUrl => 'http://localhost:7474/';
  static String get clusterHealthUrl => 'http://localhost:7475/';
  
  /// Checks if the single Neo4j instance is available
  static Future<bool> isSingleAvailable() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(singleHealthUrl));
      request.headers.set('Accept', 'application/json');
      
      final response = await request.close();
      await response.drain();
      client.close();
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Checks if the Neo4j cluster is available
  static Future<bool> isClusterAvailable() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(clusterHealthUrl));
      request.headers.set('Accept', 'application/json');
      
      final response = await request.close();
      await response.drain();
      client.close();
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Waits for the single Neo4j instance to be ready
  static Future<void> waitForSingle({Duration timeout = const Duration(seconds: 30)}) async {
    final deadline = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(deadline)) {
      if (await isSingleAvailable()) {
        // Give it a bit more time to fully initialize
        await Future.delayed(const Duration(seconds: 2));
        return;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    
    throw Exception('Neo4j single instance did not become available within $timeout');
  }
  
  /// Waits for the Neo4j cluster to be ready
  static Future<void> waitForCluster({Duration timeout = const Duration(seconds: 60)}) async {
    final deadline = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(deadline)) {
      if (await isClusterAvailable()) {
        // Give the cluster more time to form properly
        await Future.delayed(const Duration(seconds: 5));
        return;
      }
      await Future.delayed(const Duration(seconds: 2));
    }
    
    throw Exception('Neo4j cluster did not become available within $timeout');
  }
  
  /// Waits for Neo4j single instance to be ready (alias for consistency)
  static Future<void> waitForNeo4j({Duration timeout = const Duration(seconds: 30)}) async {
    await waitForSingle(timeout: timeout);
  }
  
  /// Waits for Neo4j cluster to be ready (alias for consistency) 
  static Future<void> waitForNeo4jCluster({Duration timeout = const Duration(seconds: 60)}) async {
    await waitForCluster(timeout: timeout);
  }
}