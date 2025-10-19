# dart_neo4j_ogm

A Neo4j Object-Graph Mapping (OGM) system for Dart that provides compile-time code generation for converting Dart classes to Cypher queries. This package works with `dart_neo4j_ogm_generator` to automatically generate extension methods that simplify Neo4j database interactions.

## Features

- 🚀 **Compile-time code generation** - No runtime reflection
- 🎯 **Type-safe** - Full compile-time type checking
- 🔧 **Customizable** - Control field mapping and ignore fields
- ❄️ **Freezed compatible** - Works seamlessly with Freezed classes
- 📦 **Minimal dependencies** - Only annotation classes, no runtime overhead

## Installation

Add both packages to your `pubspec.yaml`:

```yaml
dependencies:
  dart_neo4j_ogm: <lastest-version>

dev_dependencies:
  dart_neo4j_ogm_generator: <latest-version>
  build_runner: <latest-version>
```

## Basic Usage

### 1. Annotate your classes

```dart
import 'package:dart_neo4j_ogm/dart_neo4j_ogm.dart';

part 'user.cypher.dart';

@cypherNode
class User {
  final CypherId id;   // Required: All @cypherNode classes must have a CypherId id field
  final String name;
  final String email;

  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  factory User.fromNode(Node node) => _$UserFromNode(node);
}
```

### 2. Run code generation

```bash
dart run build_runner build
```

### 3. Use the generated methods

```dart
import 'package:dart_neo4j/dart_neo4j.dart';

// Create a user instance (id will be set by Neo4j when creating nodes)
final user = User(
  id: CypherId.none(),  // No id for new nodes - Neo4j will generate one when created
  name: 'John Doe',
  email: 'john@example.com',
);

// Use generated methods with Neo4j
final driver = Neo4jDriver.create('bolt://localhost:7687');
final session = driver.session();

// Create a node - id field is automatically excluded from properties
await session.run(
  'CREATE ${user.toCypherWithPlaceholders('u')} RETURN u',
  user.cypherParameters,
);

// The above generates: 'CREATE (u:User {name: $name, email: $email}) RETURN u'
// With parameters: {'name': 'John Doe', 'email': 'john@example.com'}
// Note: id is automatically excluded from Cypher properties

// Read nodes back using the fromNode factory
final result = await session.run('MATCH (u:User) RETURN u LIMIT 1');
final record = result.records.first;
final node = record['u'] as Node;
final userFromDb = User.fromNode(node);  // id comes from node.id, properties from node.properties

print('User ID from Neo4j: ${userFromDb.id}');  // Neo4j generated id
print('User name: ${userFromDb.name}');

await session.close();
await driver.close();
```

## Advanced Usage

### Custom Labels and Property Names

```dart
@CypherNode(label: 'Person')  // Custom Neo4j label
class Customer {
  final CypherId id;   // Required: CypherId id field (automatically excluded from Cypher properties)

  @CypherProperty(name: 'fullName')  // Custom property name in Neo4j
  final String name;

  @CypherProperty(ignore: true)  // Exclude from Cypher generation
  final String internalCode;

  final double? price;  // Nullable fields are handled automatically

  const Customer({
    required this.id,
    required this.name,
    required this.internalCode,
    this.price,
  });

  factory Customer.fromNode(Node node) => _$CustomerFromNode(node);
}
```

Generated usage:

```dart
final customer = Customer(
  id: CypherId.none(),  // No id for new nodes - Neo4j will generate one when created
  name: 'Jane Smith',
  internalCode: 'INTERNAL_123',
  price: 99.99,
);

print(customer.nodeLabel);  // 'Person'
print(customer.cypherParameters);
// {'fullName': 'Jane Smith', 'price': 99.99}
// Note: id is automatically excluded, internalCode is excluded due to @CypherProperty(ignore: true)

print(customer.toCypherWithPlaceholders('c'));
// '(c:Person {fullName: $fullName, price: $price})'
// Note: id field is automatically excluded from Cypher properties
```

## Freezed Integration

This package works seamlessly with Freezed classes. You need to configure your build system to run Freezed before the OGM generator.

### Build Configuration

Create or update your `build.yaml` file:

```yaml
targets:
  $default:
    builders:
      freezed:freezed:
        runs_before: ['dart_neo4j_ogm_generator:cypher_generator']
      dart_neo4j_ogm_generator:cypher_generator:
        enabled: true
```

### Freezed Class Example

```dart
import 'package:dart_neo4j_ogm/dart_neo4j_ogm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.cypher.dart';

@freezed
@cypherNode
class User with _$User {
  const factory User({
    required CypherId id,  // Required: CypherId id field (automatically excluded from Cypher properties)
    required String name,

    @CypherProperty(name: 'emailAddress')
    required String email,

    @CypherProperty(ignore: true)
    required String password,

    String? bio,
  }) = _User;

  factory User.fromNode(Node node) => _$UserFromNode(node);
}
```

Usage with Freezed:

```dart
final user = User(
  id: CypherId.none(),  // No id for new nodes - Neo4j will generate one when created
  name: 'Alice Johnson',
  email: 'alice@example.com',
  password: 'secret123',
  bio: 'Software Developer',
);

print(user.cypherParameters);
// {'name': 'Alice Johnson', 'emailAddress': 'alice@example.com', 'bio': 'Software Developer'}
// Note: id is automatically excluded, password is excluded due to @CypherProperty(ignore: true)

print(user.toCypherWithPlaceholders('u'));
// '(u:User {name: $name, emailAddress: $emailAddress, bio: $bio})'
// Note: id field is automatically excluded from Cypher properties
```

## JSON Serialization with Freezed + json_serializable

The OGM system works seamlessly with Freezed classes that also use json_serializable for JSON serialization. This is particularly useful when you need to serialize your Neo4j entities to/from JSON for APIs or storage.

### Build Configuration for JSON Support

When using both Freezed and json_serializable, update your `build.yaml` to ensure proper build order:

```yaml
targets:
  $default:
    builders:
      freezed:freezed:
        runs_before: ['dart_neo4j_ogm_generator:cypher_generator']
      json_serializable:json_serializable:
        runs_before: ['dart_neo4j_ogm_generator:cypher_generator']
      dart_neo4j_ogm_generator:cypher_generator:
        enabled: true
```

### CypherId JSON Serialization

The package provides built-in helper functions for CypherId JSON serialization. These are automatically available when you import `dart_neo4j_ogm`:

- `cypherIdToJson(CypherId id)` - Converts CypherId to JSON (int? value)
- `cypherIdFromJson(int? json)` - Creates CypherId from JSON value

### Complete JSON + Neo4j Example

```dart
import 'package:dart_neo4j_ogm/dart_neo4j_ogm.dart';
import 'package:dart_neo4j/dart_neo4j.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'json_user.freezed.dart';
part 'json_user.g.dart';
part 'json_user.cypher.dart';

@freezed
@CypherNode()
class JsonUser with _$JsonUser {
  const factory JsonUser({
    @JsonKey(toJson: cypherIdToJson, fromJson: cypherIdFromJson)
    required CypherId id,
    required String name,
    required String email,
    @CypherProperty(name: 'userAge') int? age,
    @CypherProperty(ignore: true) String? internalNotes,
  }) = _JsonUser;

  factory JsonUser.fromJson(Map<String, dynamic> json) =>
      _$JsonUserFromJson(json);

  factory JsonUser.fromNode(Node node) => _$JsonUserFromNode(node);
}
```

### Usage with JSON and Neo4j

```dart
Future<void> jsonExample() async {
  // 1. Create from JSON (e.g., from API request)
  final jsonData = {
    'id': 123,
    'name': 'John Doe',
    'email': 'john@example.com',
    'userAge': 30,
    'internalNotes': 'This will be ignored in Cypher'
  };

  final user = JsonUser.fromJson(jsonData);
  print('User from JSON: \${user.name}, Age: \${user.age}');

  // 2. Use with Neo4j (internalNotes is ignored due to @CypherProperty(ignore: true))
  final driver = Neo4jDriver.create('bolt://localhost:7687');
  final session = driver.session();

  try {
    // Create in Neo4j - only name, email, and userAge are included
    await session.run(
      'CREATE \${user.toCypherWithPlaceholders('u')} RETURN u',
      user.cypherParameters,
    );
    // Generated: CREATE (u:JsonUser {name: \$name, email: \$email, userAge: \$userAge}) RETURN u

    // 3. Read from Neo4j
    final result = await session.run('MATCH (u:JsonUser) RETURN u LIMIT 1');
    final node = result.records.first['u'] as Node;
    final userFromDb = JsonUser.fromNode(node);

    // 4. Convert back to JSON (e.g., for API response)
    final jsonResponse = userFromDb.toJson();
    print('User as JSON: \$jsonResponse');
    // Output: {id: 456, name: John Doe, email: john@example.com, userAge: 30, internalNotes: null}

  } finally {
    await session.close();
    await driver.close();
  }
}
```

### Key Benefits

1. **Dual Serialization**: Objects can be serialized to both JSON (for APIs) and Cypher (for Neo4j)
2. **Field Control**: Use `@CypherProperty(ignore: true)` for JSON-only fields that shouldn't go to Neo4j
3. **Custom Mapping**: Use `@CypherProperty(name: 'customName')` for different property names in Neo4j vs JSON
4. **Type Safety**: Full compile-time type checking for both JSON and Cypher operations
5. **ID Handling**: Proper CypherId serialization with custom JSON converters

### Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  dart_neo4j_ogm: <latest-version>
  freezed_annotation: <latest-version>
  json_annotation: <latest-version>

dev_dependencies:
  dart_neo4j_ogm_generator: <latest-version>
  build_runner: <latest-version>
  freezed: <latest-version>
  json_serializable: <latest-version>
```

## Avoiding Parameter Name Collisions

When working with complex queries involving multiple nodes, parameter names can collide. The OGM provides prefixed methods to solve this:

```dart
final user = User(id: CypherId.none(), name: 'John', email: 'john@example.com');
final post = BlogPost(id: CypherId.none(), title: 'Hello World', content: 'My first post', name: 'John');

// Without prefixes - parameter collision on 'name'!
// This would cause issues: {...user.cypherParameters, ...post.cypherParameters}
// Both objects have a 'name' field, causing parameter collision

// With prefixes - no collisions
await session.run('''
  CREATE ${user.toCypherWithPlaceholdersWithPrefix('u', 'user_')}
  CREATE ${post.toCypherWithPlaceholdersWithPrefix('p', 'post_')}
  CREATE (u)-[:AUTHORED]->(p)
''', {
  ...user.cypherParametersWithPrefix('user_'),
  ...post.cypherParametersWithPrefix('post_'),
});

// Generated query (note: id fields are automatically excluded):
// CREATE (u:User {name: $user_name, email: $user_email})
// CREATE (p:BlogPost {title: $post_title, content: $post_content, name: $post_name})
// CREATE (u)-[:AUTHORED]->(p)

// With parameters:
// {
//   'user_name': 'John', 'user_email': 'john@example.com',
//   'post_title': 'Hello World', 'post_content': 'My first post', 'post_name': 'John'
// }
```

## Generated API Reference

The code generator creates extension methods on your annotated classes:

### Properties

- **`cypherParameters`** - `Map<String, dynamic>` containing field values for Cypher queries (excludes id field)
- **`cypherProperties`** - `String` containing Cypher node properties syntax with parameter placeholders (e.g., `{name: $name, email: $email}`)
- **`nodeLabel`** - `String` containing the Neo4j node label (from annotation or class name)
- **`cypherPropertyNames`** - `List<String>` containing the property names used in Cypher

### Methods

- **`toCypherMap()`** - Returns the same as `cypherParameters` (alias for consistency)
- **`toCypherWithPlaceholders(String variableName)`** - Returns complete Cypher node syntax with variable name, label, and properties (e.g., `(u:User {name: $name, email: $email})`)
- **`cypherPropertiesWithPrefix(String prefix)`** - Returns Cypher properties string with prefixed parameter placeholders (e.g., `{name: $user_name, email: $user_email}`)
- **`cypherParametersWithPrefix(String prefix)`** - Returns parameter map with prefixed keys to avoid name collisions (e.g., `{'user_name': 'John', 'user_email': 'john@example.com'}`)
- **`toCypherWithPlaceholdersWithPrefix(String variableName, String prefix)`** - Returns complete Cypher node syntax with prefixed parameter placeholders (e.g., `(u:User {name: $user_name, email: $user_email})`)

### Factory Methods

The generator creates static factory methods for creating instances from Neo4j Node objects:

- **`fromNode(Node node)`** - Creates an instance from a Neo4j Node object, extracting the id from `node.id` and other properties from `node.properties`

## Annotations Reference

### @cypherNode / @CypherNode

Marks a class for Cypher code generation.

```dart
@cypherNode  // Uses class name as label
// or
@CypherNode(label: 'CustomLabel')  // Uses custom label
```

**Parameters:**

- `label` (optional): Custom Neo4j node label. Defaults to class name.

### @CypherProperty

Controls how individual fields are handled in Cypher generation.

```dart
@CypherProperty(
  ignore: false,  // Whether to exclude this field (default: false)
  name: null,     // Custom property name in Neo4j (default: field name)
)
```

**Parameters:**

- `ignore` (optional): Set to `true` to exclude the field from Cypher generation
- `name` (optional): Custom property name to use in Neo4j instead of the field name

## Examples

### Complete Neo4j Integration Example

```dart
import 'package:dart_neo4j/dart_neo4j.dart';
import 'package:dart_neo4j_ogm/dart_neo4j_ogm.dart';

part 'models.cypher.dart';

@cypherNode
class User {
  final CypherId id;  // Required CypherId id field
  final String name;
  final String email;

  const User({required this.id, required this.name, required this.email});

  factory User.fromNode(Node node) => _$UserFromNode(node);
}

@CypherNode(label: 'Post')
class BlogPost {
  final CypherId id;  // Required CypherId id field
  final String title;
  final String content;
  final CypherId authorId;

  const BlogPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
  });

  factory BlogPost.fromNode(Node node) => _$BlogPostFromNode(node);
}

// Usage
Future<void> example() async {
  final driver = Neo4jDriver.create('bolt://localhost:7687');
  final session = driver.session();

  final user = User(id: CypherId.none(), name: 'John', email: 'john@example.com');
  final post = BlogPost(
    id: CypherId.none(),
    title: 'Hello World',
    content: 'My first post',
    authorId: CypherId.none(),  // Will be set to actual user id after creation
  );

  try {
    // Option 1: Create user first, then create post with relationship
    final userResult = await session.run(
      'CREATE ${user.toCypherWithPlaceholders('u')} RETURN u',
      user.cypherParameters,
    );
    final createdUserNode = userResult.records.first['u'] as Node;
    final createdUser = User.fromNode(createdUserNode);

    // Update post with actual user id
    final postWithUserId = BlogPost(
      id: CypherId.none(),
      title: post.title,
      content: post.content,
      authorId: CypherId.value(createdUser.id.idOrThrow),
    );

    await session.run('''
      MATCH (u:User) WHERE id(u) = \$authorId
      CREATE ${postWithUserId.toCypherWithPlaceholders('p')}
      CREATE (u)-[:AUTHORED]->(p)
    ''', postWithUserId.cypherParameters);

    // Option 2: Create both nodes with prefixed parameters (no relationship)
    final newUser = User(id: CypherId.none(), name: 'Jane', email: 'jane@example.com');
    final newPost = BlogPost(
      id: CypherId.none(),
      title: 'Another Post',
      content: 'Different content',
      authorId: CypherId.none(),
    );

    await session.run('''
      CREATE ${newUser.toCypherWithPlaceholdersWithPrefix('u', 'user_')}
      CREATE ${newPost.toCypherWithPlaceholdersWithPrefix('p', 'post_')}
    ''', {
      ...newUser.cypherParametersWithPrefix('user_'),
      ...newPost.cypherParametersWithPrefix('post_'),
    });

    // The above generates (note: id fields are automatically excluded):
    // CREATE (u:User {name: $user_name, email: $user_email})
    // CREATE (p:Post {title: $post_title, content: $post_content, authorId: $post_authorId})
    //
    // With parameters: {
    //   'user_name': 'Jane', 'user_email': 'jane@example.com',
    //   'post_title': 'Another Post', 'post_content': 'Different content', 'post_authorId': null
    // }

    // Query with results using fromNode factories
    final result = await session.run(
      'MATCH (u:User)-[:AUTHORED]->(p:Post) RETURN u, p',
    );

    // Read results using fromNode factories
    await for (final record in result) {
      final userNode = record['u'] as Node;
      final postNode = record['p'] as Node;

      final retrievedUser = User.fromNode(userNode);
      final retrievedPost = BlogPost.fromNode(postNode);

      print('User: ${retrievedUser.name} (ID: ${retrievedUser.id.idOrThrow})');
      print('Post: ${retrievedPost.title} (ID: ${retrievedPost.id.idOrThrow})');
    }

  } finally {
    await session.close();
    await driver.close();
  }
}
```

## Requirements

- Dart SDK: >=3.0.0
- Compatible with both regular Dart classes and Freezed classes
- Requires `build_runner` for code generation

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our GitHub repository.

## License

This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.
