import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:dart_neo4j/dart_neo4j.dart';

/// SSL configuration helper for testing with custom CA certificates.
class SSLTestHelper {
  /// Path to the project's SSL certificates directory
  static String get sslCertsPath {
    // Allow override via environment variable (useful for CI)
    final envPath = Platform.environment['SSL_CERTS_PATH'];
    if (envPath != null) return envPath;

    // Calculate dynamically from current file location
    final currentFile = Platform.script.toFilePath();
    final projectRoot = _findProjectRoot(currentFile);
    return path.join(projectRoot, 'ssl-certs');
  }

  /// Path to the CA certificate for testing
  static String get caCertPath => path.join(sslCertsPath, 'ca-cert.pem');

  /// Finds the project root directory by looking for dpk.yaml or docker-compose.yml
  static String _findProjectRoot(String currentPath) {
    var dir = Directory(path.dirname(currentPath));

    while (dir.path != dir.parent.path) {
      // Check for project root indicators
      if (File(path.join(dir.path, 'dpk.yaml')).existsSync() ||
          File(path.join(dir.path, 'docker-compose.yml')).existsSync()) {
        return dir.path;
      }
      dir = dir.parent;
    }

    // Fallback: try to go up from current working directory
    var workingDir = Directory.current;
    while (workingDir.path != workingDir.parent.path) {
      if (File(path.join(workingDir.path, 'dpk.yaml')).existsSync() ||
          File(path.join(workingDir.path, 'docker-compose.yml')).existsSync()) {
        return workingDir.path;
      }
      workingDir = workingDir.parent;
    }

    throw Exception(
      'Could not find project root. Ensure dpk.yaml exists in the project root. Current working directory: ${Directory.current.path}',
    );
  }

  /// Sets up the global SSL context to trust our test CA certificate.
  /// This allows SSL connections to work with our self-signed certificates.
  static Future<void> setupSSLContextForTesting() async {
    final caCertFile = File(caCertPath);
    if (!await caCertFile.exists()) {
      throw Exception(
        'CA certificate not found at $caCertPath. Run ./scripts/generate-ssl-certs.sh first.',
      );
    }

    // Read the CA certificate
    final caCertBytes = await caCertFile.readAsBytes();

    // Set up the global SSL context to trust our CA
    SecurityContext.defaultContext.setTrustedCertificatesBytes(caCertBytes);
  }

  /// Creates a custom SecurityContext with our CA certificate.
  /// This can be used for individual connections.
  static Future<SecurityContext> createCustomSSLContext() async {
    final caCertFile = File(caCertPath);
    if (!await caCertFile.exists()) {
      throw Exception(
        'CA certificate not found at $caCertPath. Run ./scripts/generate-ssl-certs.sh first.',
      );
    }

    final context = SecurityContext();
    context.setTrustedCertificates(caCertPath);
    return context;
  }

  /// Creates a Neo4j driver with SSL configuration that trusts our CA certificate.
  static Neo4jDriver createSSLDriver(String uri, AuthToken auth) {
    return Neo4jDriver.create(
      uri,
      auth: auth,
      config: DriverConfig(
        customCACertificatePath: caCertPath,
        certificateValidator: validateTestCertificate,
      ),
    );
  }

  /// Validates if a certificate is signed by our test CA.
  /// Returns true if the certificate should be trusted for testing.
  static bool validateTestCertificate(X509Certificate cert) {
    // Check if the certificate is issued by our test CA
    const expectedIssuer =
        '/C=US/ST=CA/L=Test/O=Neo4j Test/OU=Testing/CN=Neo4j Test CA';
    if (cert.issuer != expectedIssuer) {
      return false;
    }

    // Check if it's within the validity period
    final now = DateTime.now();
    if (now.isBefore(cert.startValidity) || now.isAfter(cert.endValidity)) {
      return false;
    }

    // For localhost/127.0.0.1 connections, check the subject
    const expectedSubject =
        '/C=US/ST=CA/L=Test/O=Neo4j Test/OU=Testing/CN=localhost';
    if (cert.subject != expectedSubject) {
      return false;
    }

    return true;
  }

  /// Checks if SSL certificates are available
  static Future<bool> areCertificatesAvailable() async {
    final caCertFile = File(caCertPath);
    return await caCertFile.exists();
  }
}
