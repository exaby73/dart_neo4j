import 'package:dart_neo4j/src/exceptions/connection_exception.dart';

/// Represents the type of connection based on the URI scheme.
enum ConnectionType {
  /// Direct connection (bolt://, bolt+s://, bolt+ssc://)
  direct,

  /// Routing connection (neo4j://, neo4j+s://, neo4j+ssc://)
  routing,
}

/// Represents the encryption configuration based on the URI scheme.
enum EncryptionLevel {
  /// No encryption
  none,

  /// Full encryption with certificate validation
  encrypted,

  /// Encryption with self-signed certificate support
  encryptedSelfSigned,
}

/// Parsed URI information for Neo4j connections.
class ParsedUri {
  /// The type of connection (direct or routing).
  final ConnectionType connectionType;

  /// The encryption level.
  final EncryptionLevel encryptionLevel;

  /// The hostname or IP address.
  final String host;

  /// The port number.
  final int port;

  /// The database name, if specified in the path.
  final String? database;

  /// Query parameters from the URI.
  final Map<String, String> parameters;

  /// The original URI string.
  final String originalUri;

  /// Creates a new parsed URI.
  const ParsedUri({
    required this.connectionType,
    required this.encryptionLevel,
    required this.host,
    required this.port,
    this.database,
    required this.parameters,
    required this.originalUri,
  });

  /// Whether this connection uses encryption.
  bool get encrypted => encryptionLevel != EncryptionLevel.none;

  /// Whether this connection supports self-signed certificates.
  bool get allowsSelfSignedCertificates => encryptionLevel == EncryptionLevel.encryptedSelfSigned;

  /// Whether this is a direct connection.
  bool get isDirect => connectionType == ConnectionType.direct;

  /// Whether this is a routing connection.
  bool get isRouting => connectionType == ConnectionType.routing;

  @override
  String toString() {
    return 'ParsedUri{type: $connectionType, encryption: $encryptionLevel, host: $host, port: $port, database: $database}';
  }
}

/// Utility class for parsing Neo4j URIs.
class UriParser {
  /// Supported URI schemes and their configurations.
  static const Map<String, ({ConnectionType type, EncryptionLevel encryption})> _supportedSchemes = {
    // Direct connections
    'bolt': (type: ConnectionType.direct, encryption: EncryptionLevel.none),
    'bolt+s': (type: ConnectionType.direct, encryption: EncryptionLevel.encrypted),
    'bolt+ssc': (type: ConnectionType.direct, encryption: EncryptionLevel.encryptedSelfSigned),
    
    // Routing connections
    'neo4j': (type: ConnectionType.routing, encryption: EncryptionLevel.none),
    'neo4j+s': (type: ConnectionType.routing, encryption: EncryptionLevel.encrypted),
    'neo4j+ssc': (type: ConnectionType.routing, encryption: EncryptionLevel.encryptedSelfSigned),
  };

  /// Default port for Neo4j Bolt protocol.
  static const int defaultPort = 7687;

  /// Parses a Neo4j URI string.
  ///
  /// Supports the following URI schemes:
  /// - bolt://host:port/database
  /// - bolt+s://host:port/database
  /// - bolt+ssc://host:port/database
  /// - neo4j://host:port/database
  /// - neo4j+s://host:port/database
  /// - neo4j+ssc://host:port/database
  ///
  /// Throws [InvalidUriException] if the URI is invalid or uses an unsupported scheme.
  static ParsedUri parse(String uriString) {
    try {
      final uri = Uri.parse(uriString);
      
      // Check if scheme is supported
      final schemeConfig = _supportedSchemes[uri.scheme];
      if (schemeConfig == null) {
        throw InvalidUriException(
          'Unsupported URI scheme: ${uri.scheme}. Supported schemes: ${_supportedSchemes.keys.join(', ')}',
          uriString,
        );
      }

      // Validate host
      if (uri.host.isEmpty) {
        throw InvalidUriException('Host cannot be empty', uriString);
      }

      // Get port (use default if not specified)
      final port = uri.hasPort ? uri.port : defaultPort;
      if (port < 1 || port > 65535) {
        throw InvalidUriException('Invalid port: $port. Port must be between 1 and 65535', uriString);
      }

      // Extract database name from path
      String? database;
      if (uri.path.isNotEmpty && uri.path != '/') {
        // Remove leading slash and use the first path segment as database name
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          database = pathSegments.first;
          
          // Validate database name
          if (!_isValidDatabaseName(database)) {
            throw InvalidUriException('Invalid database name: $database', uriString);
          }
        }
      }

      // Parse query parameters
      final parameters = <String, String>{};
      uri.queryParameters.forEach((key, value) {
        parameters[key] = value;
      });

      return ParsedUri(
        connectionType: schemeConfig.type,
        encryptionLevel: schemeConfig.encryption,
        host: uri.host,
        port: port,
        database: database,
        parameters: parameters,
        originalUri: uriString,
      );
    } catch (e) {
      if (e is InvalidUriException) {
        rethrow;
      }
      throw InvalidUriException('Failed to parse URI: $e', uriString, e);
    }
  }

  /// Validates a database name according to Neo4j naming rules.
  static bool _isValidDatabaseName(String name) {
    // Neo4j database names must:
    // - Be between 3 and 63 characters long
    // - Start with a letter
    // - Contain only letters, digits, dots, hyphens, and underscores
    // - Not end with a dot or hyphen
    // - Not contain consecutive dots
    
    if (name.length < 3 || name.length > 63) {
      return false;
    }
    
    // Must start with a letter
    if (!RegExp(r'^[a-zA-Z]').hasMatch(name)) {
      return false;
    }
    
    // Must not end with dot or hyphen
    if (name.endsWith('.') || name.endsWith('-')) {
      return false;
    }
    
    // Must not contain consecutive dots
    if (name.contains('..')) {
      return false;
    }
    
    // Must contain only valid characters
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(name)) {
      return false;
    }
    
    return true;
  }

  /// Gets the default database name for a connection.
  /// 
  /// Returns the database name from the URI if specified, otherwise returns 'neo4j'.
  static String getDefaultDatabase(ParsedUri parsedUri) {
    return parsedUri.database ?? 'neo4j';
  }

  /// Creates a connection string for display purposes (without sensitive information).
  static String createDisplayString(ParsedUri parsedUri) {
    final buffer = StringBuffer();
    
    // Add scheme
    switch (parsedUri.connectionType) {
      case ConnectionType.direct:
        buffer.write('bolt');
        break;
      case ConnectionType.routing:
        buffer.write('neo4j');
        break;
    }
    
    // Add encryption suffix
    switch (parsedUri.encryptionLevel) {
      case EncryptionLevel.encrypted:
        buffer.write('+s');
        break;
      case EncryptionLevel.encryptedSelfSigned:
        buffer.write('+ssc');
        break;
      case EncryptionLevel.none:
        // No suffix
        break;
    }
    
    // Add host and port
    buffer.write('://${parsedUri.host}:${parsedUri.port}');
    
    // Add database if specified
    if (parsedUri.database != null) {
      buffer.write('/${parsedUri.database}');
    }
    
    return buffer.toString();
  }
}