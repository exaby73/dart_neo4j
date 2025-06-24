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
  
  // SSL configuration (for bolt+s:// and bolt+ssc:// tests)
  static String get boltSslUri => Platform.environment['NEO4J_SSL_URI'] ?? 'bolt+s://localhost:7694';
  static String get boltSelfSignedUri => Platform.environment['NEO4J_SELF_SIGNED_URI'] ?? 'bolt+ssc://localhost:7695';
  static String get sslUser => Platform.environment['NEO4J_SSL_USER'] ?? 'neo4j';
  static String get sslPassword => Platform.environment['NEO4J_SSL_PASSWORD'] ?? 'password';
  
  // Auth token for tests
  static BasicAuth get auth => BasicAuth(singleUser, singlePassword);
  static BasicAuth get sslAuth => BasicAuth(sslUser, sslPassword);
  
  // Test configuration
  static int get testTimeout => int.tryParse(Platform.environment['TEST_TIMEOUT'] ?? '30000') ?? 30000;
  static int get concurrentSessions => int.tryParse(Platform.environment['TEST_CONCURRENT_SESSIONS'] ?? '50') ?? 50;
  static int get performanceQueries => int.tryParse(Platform.environment['TEST_PERFORMANCE_QUERIES'] ?? '1000') ?? 1000;
  
  // Docker service URLs for health checks
  static String get singleHealthUrl => 'http://localhost:7474/';
  static String get clusterHealthUrl => 'http://localhost:7475/';
  static String get sslHealthUrl => 'http://localhost:7478/';
  static String get selfSignedHealthUrl => 'http://localhost:7479/';
  
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
  
  /// Checks if the SSL Neo4j instance is available
  static Future<bool> isSslAvailable() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(sslHealthUrl));
      request.headers.set('Accept', 'application/json');
      
      final response = await request.close();
      await response.drain();
      client.close();
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Checks if the self-signed SSL Neo4j instance is available
  static Future<bool> isSelfSignedAvailable() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(selfSignedHealthUrl));
      request.headers.set('Accept', 'application/json');
      
      final response = await request.close();
      await response.drain();
      client.close();
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Waits for the SSL Neo4j instance to be ready
  static Future<void> waitForSsl({Duration timeout = const Duration(seconds: 30)}) async {
    final deadline = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(deadline)) {
      if (await isSslAvailable()) {
        // Give SSL instance extra time to initialize certificates
        await Future.delayed(const Duration(seconds: 3));
        return;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    
    throw Exception('Neo4j SSL instance did not become available within $timeout');
  }
  
  /// Waits for the self-signed SSL Neo4j instance to be ready
  static Future<void> waitForSelfSigned({Duration timeout = const Duration(seconds: 30)}) async {
    final deadline = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(deadline)) {
      if (await isSelfSignedAvailable()) {
        // Give self-signed SSL instance extra time to initialize certificates
        await Future.delayed(const Duration(seconds: 3));
        return;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    
    throw Exception('Neo4j self-signed SSL instance did not become available within $timeout');
  }
}