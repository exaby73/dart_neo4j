# dart_neo4j

A comprehensive Neo4j driver for Dart applications. This library provides a high-level, type-safe interface for connecting to Neo4j databases using the Bolt protocol, supporting both direct connections and routing for clusters.

## Features

- 🚀 **High-Performance**: Built on the Bolt protocol with connection pooling
- 🔒 **Type-Safe**: Strongly typed API with comprehensive error handling
- 🌐 **Multiple URI Schemes**: Support for bolt://, bolt+s://, neo4j://, and more
- 🔐 **Authentication**: Basic, Bearer, and Kerberos authentication support
- 📊 **Rich Types**: Full support for Neo4j types (Node, Relationship, Path, etc.)
- ⚡ **Transactions**: Both auto-commit and explicit transaction management
- 🔄 **Connection Management**: Automatic connection pooling and retries
- 📋 **Comprehensive**: Stream-based results with multiple consumption patterns

## Installation

Add `dart_neo4j` to your `pubspec.yaml`:

```yaml
dependencies:
  dart_neo4j: ^1.0.0
```

Then run:

```bash
dart pub get
```

## Quick Start

```dart
import 'package:dart_neo4j/dart_neo4j.dart';

void main() async {
  // Create a driver
  final driver = Neo4jDriver.create(
    'bolt://localhost:7687',
    auth: BasicAuth('neo4j', 'password'),
  );

  try {
    // Verify connectivity
    await driver.verifyConnectivity();
    
    // Create a session and run a query
    final session = driver.session();
    try {
      final result = await session.run(
        'MATCH (p:Person {name: \$name}) RETURN p.name, p.age',
        {'name': 'Alice'},
      );

      // Process results
      await for (final record in result.records()) {
        final name = record.getString('p.name');
        final age = record.getIntOrNull('p.age');
        print('\$name is \${age ?? 'unknown'} years old');
      }
    } finally {
      await session.close();
    }
  } finally {
    await driver.close();
  }
}
```

## Connection URIs

The driver supports multiple URI schemes for different connection types:

### Direct Connections

```dart
// Unencrypted connection
final driver = Neo4jDriver.create('bolt://localhost:7687');

// Encrypted with full certificate validation
final driver = Neo4jDriver.create('bolt+s://localhost:7687');

// Encrypted with self-signed certificates
final driver = Neo4jDriver.create('bolt+ssc://localhost:7687');
```

### Routing Connections (Clusters)

```dart
// Unencrypted routing
final driver = Neo4jDriver.create('neo4j://localhost:7687');

// Encrypted routing with full certificate validation
final driver = Neo4jDriver.create('neo4j+s://localhost:7687');

// Encrypted routing with self-signed certificates
final driver = Neo4jDriver.create('neo4j+ssc://localhost:7687');
```

## Authentication

### Basic Authentication

```dart
final driver = Neo4jDriver.create(
  'bolt://localhost:7687',
  auth: BasicAuth('username', 'password'),
);
```

### Bearer Token

```dart
final driver = Neo4jDriver.create(
  'bolt://localhost:7687',
  auth: BearerAuth('your-bearer-token'),
);
```

### Kerberos

```dart
final driver = Neo4jDriver.create(
  'bolt://localhost:7687',
  auth: KerberosAuth('principal', 'ticket'),
);
```

### No Authentication

```dart
final driver = Neo4jDriver.create('bolt://localhost:7687');
// or explicitly:
final driver = Neo4jDriver.create(
  'bolt://localhost:7687',
  auth: NoAuth(),
);
```

## SSL/TLS Encryption

The driver supports encrypted connections to Neo4j using SSL/TLS. This is essential for production environments and recommended for any network communication.

### SSL URI Schemes

The driver supports different levels of SSL validation:

- **`bolt+s://`** - Full SSL with certificate validation (recommended for production)
- **`bolt+ssc://`** - SSL with self-signed certificate support (useful for development/testing)
- **`neo4j+s://`** - Routing with full SSL certificate validation
- **`neo4j+ssc://`** - Routing with self-signed certificate support

### Production SSL Setup

For production environments with properly signed certificates:

```dart
final driver = Neo4jDriver.create(
  'bolt+s://your-neo4j-server.com:7687',
  auth: BasicAuth('username', 'password'),
);
```

### Custom CA Certificate

If your Neo4j server uses a custom Certificate Authority (CA), you can configure the driver to trust it:

```dart
final driver = Neo4jDriver.create(
  'bolt+s://your-neo4j-server.com:7687',
  auth: BasicAuth('username', 'password'),
  config: DriverConfig(
    customCACertificatePath: '/path/to/your/ca-certificate.pem',
  ),
);
```

### Custom Certificate Validation

For advanced SSL scenarios, you can provide a custom certificate validator:

```dart
bool validateCertificate(X509Certificate cert) {
  // Custom validation logic
  // Check issuer, validity period, fingerprint, etc.
  if (cert.issuer.contains('YourCompany')) {
    final now = DateTime.now();
    return now.isAfter(cert.startValidity) && now.isBefore(cert.endValidity);
  }
  return false;
}

final driver = Neo4jDriver.create(
  'bolt+s://your-neo4j-server.com:7687',
  auth: BasicAuth('username', 'password'),
  config: DriverConfig(
    certificateValidator: validateCertificate,
  ),
);
```

### Development with Self-Signed Certificates

For development environments using self-signed certificates:

```dart
// Option 1: Use bolt+ssc:// scheme (allows self-signed certificates)
final driver = Neo4jDriver.create(
  'bolt+ssc://localhost:7687',
  auth: BasicAuth('neo4j', 'password'),
);

// Option 2: Use custom certificate validator for specific certificates
final driver = Neo4jDriver.create(
  'bolt+s://localhost:7687',
  auth: BasicAuth('neo4j', 'password'),
  config: DriverConfig(
    certificateValidator: (cert) {
      // Accept certificates from localhost with specific issuer
      return cert.subject.contains('localhost') && 
             cert.issuer.contains('Development CA');
    },
  ),
);
```

### SSL Configuration Examples

#### Enterprise Production Setup

```dart
final driver = Neo4jDriver.create(
  'neo4j+s://cluster.neo4j.company.com:7687',
  auth: BasicAuth('app_user', 'secure_password'),
  config: DriverConfig(
    maxConnectionPoolSize: 50,
    connectionTimeout: Duration(seconds: 10),
    // Uses system's trusted CA certificates
  ),
);
```

#### Internal Infrastructure with Custom CA

```dart
final driver = Neo4jDriver.create(
  'bolt+s://internal-neo4j.company.local:7687',
  auth: BasicAuth('service_account', 'service_password'),
  config: DriverConfig(
    customCACertificatePath: '/etc/ssl/certs/company-ca.pem',
    connectionTimeout: Duration(seconds: 5),
  ),
);
```

#### Development Environment

```dart
final driver = Neo4jDriver.create(
  'bolt+ssc://dev-neo4j:7687',
  auth: BasicAuth('neo4j', 'dev_password'),
  config: DriverConfig(
    connectionTimeout: Duration(seconds: 30), // Longer timeout for dev
  ),
);
```

### SSL Best Practices

1. **Always use SSL in production**: Never transmit credentials or sensitive data over unencrypted connections.

2. **Validate certificates properly**: Use `bolt+s://` with proper CA certificates rather than accepting all certificates.

3. **Rotate certificates regularly**: Ensure your certificate validation doesn't break when certificates are renewed.

4. **Environment-specific configuration**: Use different SSL configurations for development, staging, and production:

   ```dart
   // Environment-based configuration
   final isProduction = Platform.environment['ENVIRONMENT'] == 'production';
   
   final driver = Neo4jDriver.create(
     isProduction 
       ? 'bolt+s://prod-neo4j.company.com:7687'
       : 'bolt+ssc://localhost:7687',
     auth: BasicAuth(
       Platform.environment['NEO4J_USER'] ?? 'neo4j',
       Platform.environment['NEO4J_PASSWORD'] ?? 'password',
     ),
     config: DriverConfig(
       customCACertificatePath: isProduction 
         ? '/etc/ssl/certs/company-ca.pem'
         : null,
     ),
   );
   ```

5. **Certificate pinning for high security**: For maximum security, implement certificate pinning:

   ```dart
   final driver = Neo4jDriver.create(
     'bolt+s://secure-neo4j.company.com:7687',
     auth: BasicAuth('username', 'password'),
     config: DriverConfig(
       certificateValidator: (cert) {
         // Pin to specific certificate fingerprint
         const expectedFingerprint = [0x12, 0x34, 0x56, /* ... */];
         return cert.sha1.toString() == expectedFingerprint.toString();
       },
     ),
   );
   ```

### Troubleshooting SSL Issues

#### Certificate Verification Failed

```dart
try {
  await driver.verifyConnectivity();
} on ServiceUnavailableException catch (e) {
  if (e.message.contains('CERTIFICATE_VERIFY_FAILED')) {
    print('SSL certificate verification failed. Check:');
    print('1. Certificate is valid and not expired');
    print('2. Hostname matches certificate subject');
    print('3. CA certificate is trusted');
    print('4. Consider using bolt+ssc:// for self-signed certificates');
  }
}
```

#### Common SSL Configuration Issues

1. **Hostname mismatch**: Ensure the hostname in your URI matches the certificate's subject or SAN.
2. **Expired certificates**: Check certificate validity dates.
3. **Missing CA certificate**: For custom CAs, ensure the CA certificate is provided.
4. **Wrong port**: SSL-enabled Neo4j typically runs on a different port than unencrypted.

#### Testing SSL Configuration

```dart
// Test SSL connectivity before using in application
Future<void> testSSLConnection() async {
  final driver = Neo4jDriver.create(
    'bolt+s://your-server:7687',
    auth: BasicAuth('username', 'password'),
  );
  
  try {
    await driver.verifyConnectivity();
    print('SSL connection successful!');
    
    final session = driver.session();
    try {
      final result = await session.run('RETURN "SSL Test" AS message');
      final record = await result.single();
      print('Query result: ${record['message']}');
    } finally {
      await session.close();
    }
  } catch (e) {
    print('SSL connection failed: $e');
  } finally {
    await driver.close();
  }
}
```

## Sessions

Sessions are the primary interface for executing queries. They can be configured for different access modes and databases.

### Basic Session

```dart
final session = driver.session();
```

### Read-Only Session

```dart
final session = driver.session(
  SessionConfig.read(database: 'mydb'),
);
```

### Write Session with Bookmarks

```dart
final session = driver.session(
  SessionConfig.write(
    database: 'mydb',
    bookmarks: ['bookmark1', 'bookmark2'],
  ),
);
```

## Queries (Auto-Commit Transactions)

The simplest way to execute queries is using auto-commit transactions via `session.run()`.

### Basic Query

```dart
final result = await session.run('RETURN 1 as number');
```

### Parameterized Query

```dart
final result = await session.run(
  'CREATE (p:Person {name: \$name, age: \$age}) RETURN p',
  {
    'name': 'John Doe',
    'age': 30,
  },
);
```

### Multiple Operations

```dart
final result = await session.run('''
  MATCH (p:Person {name: \$name})
  SET p.lastLogin = datetime()
  RETURN p.name, p.lastLogin
''', {'name': 'Alice'});
```

## Explicit Transactions

For more control over transaction boundaries, use explicit transactions.

### Read Transaction

```dart
final result = await session.executeRead((tx) async {
  final result = await tx.run(
    'MATCH (p:Person) WHERE p.age > \$minAge RETURN p',
    {'minAge': 25},
  );
  return await result.list();
});
```

### Write Transaction

```dart
final person = await session.executeWrite((tx) async {
  // Create person
  final createResult = await tx.run(
    'CREATE (p:Person {name: \$name, email: \$email}) RETURN p',
    {'name': 'Jane Doe', 'email': 'jane@example.com'},
  );
  
  final record = await createResult.single();
  final person = record.getNode('p');
  
  // Update statistics
  await tx.run('MATCH (s:Stats) SET s.userCount = s.userCount + 1');
  
  return person;
});
```

### Manual Transaction Control

```dart
final transaction = await session.beginTransaction();
try {
  await transaction.run('CREATE (p:Person {name: "Test"})');
  await transaction.run('CREATE (c:Company {name: "Test Corp"})');
  
  // Commit if everything succeeds
  await transaction.commit();
} catch (e) {
  // Rollback on error
  await transaction.rollback();
  rethrow;
} finally {
  await transaction.close();
}
```

## Results and Records

Results provide multiple ways to consume query data with full type safety.

### Stream Processing

```dart
final result = await session.run('MATCH (p:Person) RETURN p.name, p.age');

await for (final record in result.records()) {
  final name = record.getString('p.name');
  final age = record.getInt('p.age');
  print('\$name: \$age');
}
```

### List Processing

```dart
final result = await session.run('MATCH (p:Person) RETURN p.name, p.age');
final records = await result.list();

for (final record in records) {
  final name = record.getString('p.name');
  final age = record.getInt('p.age');
  print('\$name: \$age');
}
```

### Single Record

```dart
final result = await session.run(
  'MATCH (p:Person {id: \$id}) RETURN p',
  {'id': 123},
);

final record = await result.single(); // Throws if 0 or >1 records
final person = record.getNode('p');
```

### Optional Single Record

```dart
final result = await session.run(
  'MATCH (p:Person {email: \$email}) RETURN p',
  {'email': 'user@example.com'},
);

final record = await result.firstOrNull();
if (record != null) {
  final person = record.getNode('p');
  print('Found: \${person.properties}');
} else {
  print('Person not found');
}
```

## Type-Safe Record Access

Records provide strongly typed methods for accessing field values:

### Basic Types

```dart
// Required fields (throw if null or wrong type)
final name = record.getString('name');
final age = record.getInt('age');
final score = record.getDouble('score');
final active = record.getBool('active');
final tags = record.getList<String>('tags');
final metadata = record.getMap<dynamic>('metadata');

// Optional fields (return null if missing/null)
final email = record.getStringOrNull('email');
final phone = record.getIntOrNull('phone');
final rating = record.getDoubleOrNull('rating');
final verified = record.getBoolOrNull('verified');
```

### Neo4j Graph Types

```dart
// Graph types
final person = record.getNode('person');
final friendship = record.getRelationship('friendship');
final path = record.getPath('shortestPath');

// Optional graph types
final manager = record.getNodeOrNull('manager');
final relationship = record.getRelationshipOrNull('rel');
```

### Generic Access

```dart
// Generic typed access
final value = record.get<String>('field');
final optionalValue = record.getOrNull<int>('optional_field');

// Dynamic access
final dynamicValue = record['field_name'];
final byIndex = record[0];
```

## Neo4j Types

The driver provides rich support for Neo4j's graph types.

### Working with Nodes

```dart
final result = await session.run('MATCH (p:Person) RETURN p LIMIT 1');
final record = await result.single();
final person = record.getNode('p');

print('Node ID: \${person.id}');
print('Labels: \${person.labels}');
print('Properties: \${person.properties}');

// Type-safe property access
final name = person.getProperty<String>('name');
final age = person.getPropertyOrNull<int>('age');

// Check for labels and properties
if (person.hasLabel('Employee')) {
  print('This person is an employee');
}

if (person.hasProperty('email')) {
  final email = person.getProperty<String>('email');
  print('Email: \$email');
}
```

### Working with Relationships

```dart
final result = await session.run('''
  MATCH (p:Person)-[r:WORKS_FOR]->(c:Company) 
  RETURN r LIMIT 1
''');
final record = await result.single();
final relationship = record.getRelationship('r');

print('Relationship ID: \${relationship.id}');
print('Type: \${relationship.type}');
print('Start Node ID: \${relationship.startNodeId}');
print('End Node ID: \${relationship.endNodeId}');
print('Properties: \${relationship.properties}');

// Property access
final since = relationship.getPropertyOrNull<String>('since');
if (since != null) {
  print('Working since: \$since');
}
```

### Working with Paths

```dart
final result = await session.run('''
  MATCH path = shortestPath((a:Person {name: "Alice"})-[*]-(b:Person {name: "Bob"}))
  RETURN path
''');
final record = await result.single();
final path = record.getPath('path');

print('Path length: \${path.length}');
print('Number of nodes: \${path.nodes.length}');
print('Number of relationships: \${path.relationships.length}');

// Access start and end nodes
final startNode = path.start;
final endNode = path.end;

if (startNode != null && endNode != null) {
  print('Path from \${startNode.getProperty<String>('name')} to \${endNode.getProperty<String>('name')}');
}

// Iterate through the path
for (int i = 0; i < path.nodes.length; i++) {
  final node = path.nodes[i];
  print('Node \$i: \${node.getProperty<String>('name')}');
  
  if (i < path.relationships.length) {
    final rel = path.relationships[i];
    print('  -> \${rel.type}');
  }
}
```

## Error Handling

The driver provides a comprehensive exception hierarchy for robust error handling:

```dart
try {
  final result = await session.run('INVALID CYPHER QUERY');
  await result.consume();
} on DatabaseException catch (e) {
  print('Database error: \${e.message}');
  if (e.code != null) {
    print('Error code: \${e.code}');
  }
} on AuthenticationException catch (e) {
  print('Authentication failed: \${e.message}');
} on ServiceUnavailableException catch (e) {
  print('Service unavailable: \${e.message}');
} on ClientException catch (e) {
  print('Client error: \${e.message}');
} on Neo4jException catch (e) {
  print('Neo4j error: \${e.message}');
} catch (e) {
  print('Unexpected error: \$e');
}
```

### Exception Types

- **`DatabaseException`**: Server-side database errors (syntax errors, constraint violations, etc.)
- **`AuthenticationException`**: Authentication failures
- **`AuthorizationException`**: Authorization/permission errors
- **`ServiceUnavailableException`**: Connection or service availability issues
- **`SessionExpiredException`**: Session used after being closed
- **`TransactionClosedException`**: Transaction used after being closed/committed
- **`ClientException`**: Client-side errors (invalid usage, etc.)
- **`TransientException`**: Temporary errors that may be retried

### Type-Safe Field Access Errors

```dart
try {
  final record = await result.single();
  final name = record.getString('name'); // Required field
} on FieldNotFoundException catch (e) {
  print('Field not found: \${e.fieldName}');
  print('Available fields: \${e.availableFields}');
} on UnexpectedNullException catch (e) {
  print('Field \${e.fieldName} was null but required');
} on TypeMismatchException catch (e) {
  print('Field \${e.fieldName} expected \${e.expectedType} but got \${e.actualType}');
}
```

## Driver Configuration

Customize driver behavior with `DriverConfig`:

```dart
final driver = Neo4jDriver.create(
  'bolt://localhost:7687',
  auth: BasicAuth('neo4j', 'password'),
  config: DriverConfig(
    maxConnectionPoolSize: 50,
    connectionTimeout: Duration(seconds: 10),
    maxTransactionRetryTime: Duration(seconds: 30),
    encrypted: true,
    trustAllCertificates: false, // Only for development!
    customCACertificatePath: '/path/to/ca-cert.pem',
    certificateValidator: (cert) => validateCustomCert(cert),
  ),
);
```

### Configuration Options

- **`maxConnectionPoolSize`**: Maximum connections in the pool (default: 100)
- **`connectionTimeout`**: Connection establishment timeout (default: 30s)
- **`maxTransactionRetryTime`**: Maximum time to retry transient failures (default: 30s)
- **`encrypted`**: Force encryption on/off (null = auto-detect from URI)
- **`trustAllCertificates`**: Accept self-signed certificates (default: false)
- **`customCACertificatePath`**: Path to custom CA certificate file for SSL validation
- **`certificateValidator`**: Custom function to validate SSL certificates

## Best Practices

### Resource Management

Always close sessions and drivers to prevent resource leaks:

```dart
// Using try-finally
final driver = Neo4jDriver.create('bolt://localhost:7687');
try {
  final session = driver.session();
  try {
    // Use session
  } finally {
    await session.close();
  }
} finally {
  await driver.close();
}

// Or using helper functions
Future<T> withSession<T>(
  Neo4jDriver driver,
  Future<T> Function(Session session) work,
) async {
  final session = driver.session();
  try {
    return await work(session);
  } finally {
    await session.close();
  }
}

// Usage
final result = await withSession(driver, (session) async {
  return await session.run('RETURN 1');
});
```

### Connection Pooling

The driver automatically manages connection pooling. Create one driver instance per application and reuse it:

```dart
// Good: One driver instance
class DatabaseService {
  static final _driver = Neo4jDriver.create(
    'bolt://localhost:7687',
    auth: BasicAuth('neo4j', 'password'),
  );
  
  static Neo4jDriver get driver => _driver;
}

// Bad: Creating multiple drivers
// Don't do this - creates unnecessary overhead
final driver1 = Neo4jDriver.create('bolt://localhost:7687');
final driver2 = Neo4jDriver.create('bolt://localhost:7687');
```

### Transaction Patterns

Use appropriate transaction patterns based on your needs:

```dart
// Read-only operations: use executeRead
final users = await session.executeRead((tx) async {
  final result = await tx.run('MATCH (u:User) RETURN u');
  return await result.list();
});

// Write operations: use executeWrite
await session.executeWrite((tx) async {
  await tx.run(
    'CREATE (u:User {name: \$name, email: \$email})',
    {'name': 'John', 'email': 'john@example.com'},
  );
});

// Mixed operations: use explicit transactions
final tx = await session.beginTransaction();
try {
  // Read first
  final result = await tx.run('MATCH (u:User {id: \$id}) RETURN u', {'id': 123});
  final user = (await result.single()).getNode('u');
  
  // Then write based on read
  await tx.run(
    'CREATE (l:LoginEvent {userId: \$id, timestamp: datetime()})',
    {'id': user.id},
  );
  
  await tx.commit();
} catch (e) {
  await tx.rollback();
  rethrow;
} finally {
  await tx.close();
}
```

### Performance Tips

1. **Use parameters**: Always use parameterized queries to prevent injection and enable query plan caching:

   ```dart
   // Good
   await session.run('MATCH (u:User {name: \$name}) RETURN u', {'name': userName});
   
   // Bad
   await session.run('MATCH (u:User {name: "\$userName"}) RETURN u');
   ```

2. **Limit results**: Use `LIMIT` in queries when you don't need all results:

   ```dart
   await session.run('MATCH (u:User) RETURN u ORDER BY u.created DESC LIMIT 10');
   ```

3. **Stream processing**: For large result sets, use streaming instead of loading everything into memory:

   ```dart
   final result = await session.run('MATCH (u:User) RETURN u');
   await for (final record in result.records()) {
     // Process one record at a time
     processUser(record.getNode('u'));
   }
   ```

4. **Connection reuse**: Reuse sessions when possible, but don't hold them open unnecessarily:

   ```dart
   // Good: Short-lived sessions
   final session = driver.session();
   try {
     await session.run('...');
     await session.run('...');
   } finally {
     await session.close();
   }
   ```

## Examples

### User Management System

```dart
class UserService {
  final Neo4jDriver _driver;
  
  UserService(this._driver);
  
  Future<Node> createUser(String name, String email) async {
    final session = _driver.session();
    try {
      final result = await session.run('''
        CREATE (u:User {
          id: randomUUID(),
          name: \$name,
          email: \$email,
          created: datetime()
        })
        RETURN u
      ''', {'name': name, 'email': email});
      
      final record = await result.single();
      return record.getNode('u');
    } finally {
      await session.close();
    }
  }
  
  Future<Node?> findUserByEmail(String email) async {
    final session = _driver.session();
    try {
      final result = await session.run(
        'MATCH (u:User {email: \$email}) RETURN u',
        {'email': email},
      );
      
      final record = await result.firstOrNull();
      return record?.getNodeOrNull('u');
    } finally {
      await session.close();
    }
  }
  
  Future<List<Node>> getFriends(String userId) async {
    final session = _driver.session();
    try {
      final result = await session.run('''
        MATCH (u:User {id: \$userId})-[:FRIEND_OF]-(friend:User)
        RETURN friend
        ORDER BY friend.name
      ''', {'userId': userId});
      
      final friends = <Node>[];
      await for (final record in result.records()) {
        friends.add(record.getNode('friend'));
      }
      return friends;
    } finally {
      await session.close();
    }
  }
}
```

### Recommendation Engine

```dart
class RecommendationService {
  final Neo4jDriver _driver;
  
  RecommendationService(this._driver);
  
  Future<List<Node>> recommendProducts(String userId, {int limit = 10}) async {
    final session = _driver.session();
    try {
      return await session.executeRead((tx) async {
        final result = await tx.run('''
          MATCH (u:User {id: \$userId})-[:PURCHASED]->(p:Product)
          MATCH (p)<-[:PURCHASED]-(other:User)-[:PURCHASED]->(rec:Product)
          WHERE NOT (u)-[:PURCHASED]->(rec)
          RETURN rec, count(*) as score
          ORDER BY score DESC
          LIMIT \$limit
        ''', {'userId': userId, 'limit': limit});
        
        final recommendations = <Node>[];
        await for (final record in result.records()) {
          recommendations.add(record.getNode('rec'));
        }
        return recommendations;
      });
    } finally {
      await session.close();
    }
  }
}
```

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For questions and support, please open an issue on the GitHub repository.
