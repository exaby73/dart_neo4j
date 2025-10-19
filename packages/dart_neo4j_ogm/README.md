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
  final String id;
  final String name;
  final String email;

  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  // Optional: Add factory constructor for reading from Neo4j results
  factory User.fromCypherMap(Map<String, dynamic> map) =>
      _$UserFromCypherMap(map);
}
```

### 2. Run code generation

```bash
dart run build_runner build
```

### 3. Use the generated methods

```dart
import 'package:dart_neo4j/dart_neo4j.dart';

// Create a user instance
final user = User(
  id: '123',
  name: 'John Doe',
  email: 'john@example.com',
);

// Use generated methods with Neo4j
final driver = Neo4jDriver.create('bolt://localhost:7687');
final session = driver.session();

// Create a node using the new toCypherWithPlaceholders method (recommended)
await session.run(
  'CREATE ${user.toCypherWithPlaceholders('u')} RETURN u',
  user.cypherParameters,
);

// The above generates: 'CREATE (u:User {id: $id, name: $name, email: $email}) RETURN u'
// With parameters: {'id': '123', 'name': 'John Doe', 'email': 'john@example.com'}

// Alternative: use individual methods
await session.run(
  'CREATE (u:${user.nodeLabel} ${user.cypherProperties}) RETURN u',
  user.cypherParameters,
);

await session.close();
await driver.close();
```

## Advanced Usage

### Custom Labels and Property Names

```dart
@CypherNode(label: 'Person')  // Custom Neo4j label
class Customer {
  final String id;

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

  factory Customer.fromCypherMap(Map<String, dynamic> map) =>
      _$CustomerFromCypherMap(map);
}
```

Generated usage:

```dart
final customer = Customer(
  id: '456',
  name: 'Jane Smith',
  internalCode: 'INTERNAL_123',
  price: 99.99,
);

print(customer.nodeLabel);  // 'Person'
print(customer.cypherParameters);
// {'id': '456', 'fullName': 'Jane Smith', 'price': 99.99}
// Note: internalCode is excluded due to @CypherProperty(ignore: true)

print(customer.toCypherWithPlaceholders('c'));
// '(c:Person {id: $id, fullName: $fullName, price: $price})'
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
@CypherNode(includeFromCypherMap: false)  // Freezed already provides fromJson
class User with _$User {
  const factory User({
    required String id,
    required String name,

    @CypherProperty(name: 'emailAddress')
    required String email,

    @CypherProperty(ignore: true)
    required String password,

    String? bio,
  }) = _User;
}
```

Usage with Freezed:

```dart
final user = User(
  id: '789',
  name: 'Alice Johnson',
  email: 'alice@example.com',
  password: 'secret123',
  bio: 'Software Developer',
);

print(user.cypherParameters);
// {'id': '789', 'name': 'Alice Johnson', 'emailAddress': 'alice@example.com', 'bio': 'Software Developer'}
// Note: password is excluded, email uses custom name 'emailAddress'

print(user.toCypherWithPlaceholders('u'));
// '(u:User {id: $id, name: $name, emailAddress: $emailAddress, bio: $bio})'
```

## Avoiding Parameter Name Collisions

When working with complex queries involving multiple nodes, parameter names can collide. The OGM provides prefixed methods to solve this:

```dart
final user = User(id: '1', name: 'John', email: 'john@example.com');
final post = BlogPost(id: '1', title: 'Hello World', content: 'My first post', authorId: '1');

// Without prefixes - parameter collision on 'id'!
// This would cause issues: {...user.cypherParameters, ...post.cypherParameters}

// With prefixes - no collisions
await session.run('''
  CREATE ${user.toCypherWithPlaceholdersWithPrefix('u', 'user_')}
  CREATE ${post.toCypherWithPlaceholdersWithPrefix('p', 'post_')}
  CREATE (u)-[:AUTHORED]->(p)
''', {
  ...user.cypherParametersWithPrefix('user_'),
  ...post.cypherParametersWithPrefix('post_'),
});

// Generated query:
// CREATE (u:User {id: $user_id, name: $user_name, email: $user_email})
// CREATE (p:Post {id: $post_id, title: $post_title, content: $post_content, authorId: $post_authorId})
// CREATE (u)-[:AUTHORED]->(p)

// With parameters:
// {
//   'user_id': '1', 'user_name': 'John', 'user_email': 'john@example.com',
//   'post_id': '1', 'post_title': 'Hello World', 'post_content': 'My first post', 'post_authorId': '1'
// }
```

## Generated API Reference

The code generator creates extension methods on your annotated classes:

### Properties

- **`cypherParameters`** - `Map<String, dynamic>` containing field values for Cypher queries
- **`cypherProperties`** - `String` containing Cypher node properties syntax with parameter placeholders (e.g., `{id: $id, name: $name}`)
- **`nodeLabel`** - `String` containing the Neo4j node label (from annotation or class name)
- **`cypherPropertyNames`** - `List<String>` containing the property names used in Cypher

### Methods

- **`toCypherMap()`** - Returns the same as `cypherParameters` (alias for consistency)
- **`toCypherWithPlaceholders(String variableName)`** - Returns complete Cypher node syntax with variable name, label, and properties (e.g., `(u:User {id: $id, name: $name})`)
- **`cypherPropertiesWithPrefix(String prefix)`** - Returns Cypher properties string with prefixed parameter placeholders (e.g., `{id: $user_id, name: $user_name}`)
- **`cypherParametersWithPrefix(String prefix)`** - Returns parameter map with prefixed keys to avoid name collisions (e.g., `{'user_id': '123', 'user_name': 'John'}`)
- **`toCypherWithPlaceholdersWithPrefix(String variableName, String prefix)`** - Returns complete Cypher node syntax with prefixed parameter placeholders (e.g., `(u:User {id: $user_id, name: $user_name})`)

### Factory Functions (Optional)

If you include a `fromCypherMap` factory constructor, the generator creates:

- **`_$YourClassFromCypherMap(Map<String, dynamic> map)`** - Creates an instance from a Cypher result map

## Annotations Reference

### @cypherNode / @CypherNode

Marks a class for Cypher code generation.

```dart
@cypherNode  // Uses class name as label
// or
@CypherNode(label: 'CustomLabel')  // Uses custom label
// or
@CypherNode(includeFromCypherMap: false)  // Skip fromCypherMap generation
```

**Parameters:**

- `label` (optional): Custom Neo4j node label. Defaults to class name.
- `includeFromCypherMap` (optional): Whether to generate the `_$ClassFromCypherMap` helper function. Defaults to `true`. Set to `false` if you don't need to create instances from Neo4j result maps.

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
  final String id;
  final String name;
  final String email;

  const User({required this.id, required this.name, required this.email});

  factory User.fromCypherMap(Map<String, dynamic> map) =>
      _$UserFromCypherMap(map);
}

@CypherNode(label: 'Post')
class BlogPost {
  final String id;
  final String title;
  final String content;
  final String authorId;

  const BlogPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
  });

  factory BlogPost.fromCypherMap(Map<String, dynamic> map) =>
      _$BlogPostFromCypherMap(map);
}

// Usage
Future<void> example() async {
  final driver = Neo4jDriver.create('bolt://localhost:7687');
  final session = driver.session();

  final user = User(id: '1', name: 'John', email: 'john@example.com');
  final post = BlogPost(
    id: '1',
    title: 'Hello World',
    content: 'My first post',
    authorId: user.id,
  );

  // Option 1: Create nodes separately (no parameter collisions)
  await session.run(
    'CREATE ${user.toCypherWithPlaceholders('u')} RETURN u',
    user.cypherParameters,
  );

  await session.run(
    'CREATE ${post.toCypherWithPlaceholders('p')} RETURN p',
    post.cypherParameters,
  );

  // Option 2: Create user and post with relationship using prefixed methods to avoid parameter collisions
  await session.run('''
    CREATE ${user.toCypherWithPlaceholdersWithPrefix('u', 'user_')}
    CREATE ${post.toCypherWithPlaceholdersWithPrefix('p', 'post_')}
    CREATE (u)-[:AUTHORED]->(p)
  ''', {
    ...user.cypherParametersWithPrefix('user_'),
    ...post.cypherParametersWithPrefix('post_'),
  });

  // The above generates:
  // CREATE (u:User {id: $user_id, name: $user_name, email: $user_email})
  // CREATE (p:Post {id: $post_id, title: $post_title, content: $post_content, authorId: $post_authorId})
  // CREATE (u)-[:AUTHORED]->(p)
  //
  // With parameters: {
  //   'user_id': '1', 'user_name': 'John', 'user_email': 'john@example.com',
  //   'post_id': '1', 'post_title': 'Hello World', 'post_content': 'My first post', 'post_authorId': '1'
  // }

  // Query with results
  final result = await session.run(
    'MATCH (u:${user.nodeLabel})-[:AUTHORED]->(p:${post.nodeLabel}) '
    'RETURN u, p',
  );

  // Read results
  await for (final record in result) {
    final userData = record['u'].asMap();
    final postData = record['p'].asMap();

    final retrievedUser = User.fromCypherMap(userData);
    final retrievedPost = BlogPost.fromCypherMap(postData);

    print('User: ${retrievedUser.name}');
    print('Post: ${retrievedPost.title}');
  }

  await session.close();
  await driver.close();
}
```

## Requirements

- Dart SDK: >=3.0.0
- Compatible with both regular Dart classes and Freezed classes
- Requires `build_runner` for code generation

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our GitHub repository.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
