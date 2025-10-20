// ignore_for_file: deprecated_member_use

import 'package:dart_neo4j/dart_neo4j.dart';
import 'package:dart_bolt/dart_bolt.dart';
import 'package:dart_neo4j_ogm/dart_neo4j_ogm.dart';
import 'package:test/test.dart';

import '../fixtures/user.dart';
import '../fixtures/person.dart';
import '../fixtures/product.dart';
import '../fixtures/freezed_user.dart';
import '../fixtures/json_user.dart';
import '../fixtures/modern_user.dart';
import '../fixtures/hybrid_user.dart';

void main() {
  group('Generated API Tests', () {
    group('User class (with fromCypherMap)', () {
      test('cypherParameters returns correct map', () {
        final user = User(
          id: CypherId.value(1),
          name: 'John',
          email: 'john@example.com',
        );

        expect(user.cypherParameters, {
          'name': 'John',
          'email': 'john@example.com',
        });
      });

      test('nodeLabel returns correct label', () {
        final user = User(
          id: CypherId.value(1),
          name: 'John',
          email: 'john@example.com',
        );

        expect(user.nodeLabel, equals('User'));
      });

      test('cypherPropertyNames returns correct list', () {
        final user = User(
          id: CypherId.value(1),
          name: 'John',
          email: 'john@example.com',
        );

        expect(user.cypherPropertyNames, equals(['name', 'email']));
      });

      test('cypherProperties returns correct Cypher syntax', () {
        final user = User(
          id: CypherId.value(1),
          name: 'John',
          email: 'john@example.com',
        );

        expect(user.cypherProperties, equals('{name: \$name, email: \$email}'));
      });

      test('toCypherWithPlaceholders returns complete node syntax', () {
        final user = User(
          id: CypherId.value(1),
          name: 'John',
          email: 'john@example.com',
        );

        expect(
          user.toCypherWithPlaceholders('u'),
          equals('(u:User {name: \$name, email: \$email})'),
        );
      });

      test('fromNode creates correct instance', () {
        final boltNode = BoltNode(
          PsInt.compact(1),
          PsList([PsString('User')]),
          PsDictionary({
            PsString('name'): PsString('John'),
            PsString('email'): PsString('john@example.com'),
          }),
        );
        final node = Node.fromBolt(boltNode);

        final user = User.fromNode(node);

        expect(user.id.idOrThrow, equals(1));
        expect(user.name, equals('John'));
        expect(user.email, equals('john@example.com'));
      });

      test(
        'cypherPropertiesWithPrefix returns prefixed Cypher properties string',
        () {
          final user = User(
            id: CypherId.value(1),
            name: 'John',
            email: 'john@example.com',
          );

          expect(
            user.cypherPropertiesWithPrefix('user_'),
            equals('{name: \$user_name, email: \$user_email}'),
          );
        },
      );

      test('cypherPropertiesWithPrefix works with empty prefix', () {
        final user = User(
          id: CypherId.value(1),
          name: 'John',
          email: 'john@example.com',
        );

        expect(
          user.cypherPropertiesWithPrefix(''),
          equals('{name: \$name, email: \$email}'),
        );
      });

      test('cypherParametersWithPrefix returns prefixed parameter map', () {
        final user = User(
          id: CypherId.value(1),
          name: 'John',
          email: 'john@example.com',
        );

        expect(user.cypherParametersWithPrefix('user_'), {
          'user_name': 'John',
          'user_email': 'john@example.com',
        });
      });

      test('cypherParametersWithPrefix works with empty prefix', () {
        final user = User(
          id: CypherId.value(1),
          name: 'John',
          email: 'john@example.com',
        );

        expect(user.cypherParametersWithPrefix(''), {
          'name': 'John',
          'email': 'john@example.com',
        });
      });

      test(
        'toCypherWithPlaceholdersWithPrefix returns prefixed Cypher syntax',
        () {
          final user = User(
            id: CypherId.value(1),
            name: 'John',
            email: 'john@example.com',
          );

          expect(
            user.toCypherWithPlaceholdersWithPrefix('u', 'user_'),
            equals('(u:User {name: \$user_name, email: \$user_email})'),
          );
        },
      );

      test('toCypherWithPlaceholdersWithPrefix works with empty prefix', () {
        final user = User(
          id: CypherId.value(1),
          name: 'John',
          email: 'john@example.com',
        );

        expect(
          user.toCypherWithPlaceholdersWithPrefix('u', ''),
          equals('(u:User {name: \$name, email: \$email})'),
        );
      });
    });

    group('Customer class (with custom label)', () {
      test('nodeLabel returns custom label', () {
        final customer = Customer(id: CypherId.value(1), name: 'Jane');

        expect(customer.nodeLabel, equals('Person'));
      });

      test('cypherParameters returns correct map', () {
        final customer = Customer(id: CypherId.value(1), name: 'Jane');

        expect(customer.cypherParameters, {'name': 'Jane'});
      });

      test('cypherProperties returns correct Cypher syntax', () {
        final customer = Customer(id: CypherId.value(1), name: 'Jane');

        expect(customer.cypherProperties, equals('{name: \$name}'));
      });

      test('toCypherWithPlaceholders uses custom label', () {
        final customer = Customer(id: CypherId.value(1), name: 'Jane');

        expect(
          customer.toCypherWithPlaceholders('c'),
          equals('(c:Person {name: \$name})'),
        );
      });

      test('fromNode creates correct instance', () {
        final boltNode = BoltNode(
          PsInt.compact(1),
          PsList([PsString('Person')]),
          PsDictionary({PsString('name'): PsString('Jane')}),
        );
        final node = Node.fromBolt(boltNode);

        final customer = Customer.fromNode(node);

        expect(customer.id.idOrThrow, equals(1));
        expect(customer.name, equals('Jane'));
      });
    });

    group('Product class (with @CypherProperty and no fromCypherMap)', () {
      test(
        'cypherParameters uses custom property names and ignores fields',
        () {
          final product = Product(
            id: CypherId.value(1),
            name: 'Widget',
            internalCode: 'INTERNAL123',
            price: 9.99,
          );

          expect(product.cypherParameters, {
            'productName': 'Widget', // Custom name from @CypherProperty
            'price': 9.99,
            // internalCode should be ignored
          });

          expect(product.cypherParameters.containsKey('internalCode'), isFalse);
        },
      );

      test('cypherPropertyNames excludes ignored fields', () {
        final product = Product(
          id: CypherId.value(1),
          name: 'Widget',
          internalCode: 'INTERNAL123',
          price: 9.99,
        );

        expect(product.cypherPropertyNames, equals(['productName', 'price']));
        expect(product.cypherPropertyNames.contains('internalCode'), isFalse);
      });

      test(
        'cypherProperties uses custom property names and excludes ignored fields',
        () {
          final product = Product(
            id: CypherId.value(1),
            name: 'Widget',
            internalCode: 'INTERNAL123',
            price: 9.99,
          );

          expect(
            product.cypherProperties,
            equals('{productName: \$productName, price: \$price}'),
          );
        },
      );

      test(
        'toCypherWithPlaceholders works with custom properties and ignored fields',
        () {
          final product = Product(
            id: CypherId.value(1),
            name: 'Widget',
            internalCode: 'INTERNAL123',
            price: 9.99,
          );

          expect(
            product.toCypherWithPlaceholders('p'),
            equals('(p:Product {productName: \$productName, price: \$price})'),
          );
        },
      );

      test('handles nullable fields correctly', () {
        final product = Product(
          id: CypherId.value(1),
          name: 'Widget',
          internalCode: 'INTERNAL123',
          price: null, // nullable field
        );

        expect(product.cypherParameters['price'], isNull);
      });

      test(
        'cypherPropertiesWithPrefix uses custom property names and ignores fields',
        () {
          final product = Product(
            id: CypherId.value(1),
            name: 'Widget',
            internalCode: 'INTERNAL123',
            price: 9.99,
          );

          expect(
            product.cypherPropertiesWithPrefix('prod_'),
            equals('{productName: \$prod_productName, price: \$prod_price}'),
          );
        },
      );

      test(
        'cypherParametersWithPrefix uses custom property names and ignores fields',
        () {
          final product = Product(
            id: CypherId.value(1),
            name: 'Widget',
            internalCode: 'INTERNAL123',
            price: 9.99,
          );

          expect(product.cypherParametersWithPrefix('prod_'), {
            'prod_productName': 'Widget', // Custom name from @CypherProperty
            'prod_price': 9.99,
            // internalCode should be ignored
          });

          expect(
            product
                .cypherParametersWithPrefix('prod_')
                .containsKey('prod_internalCode'),
            isFalse,
          );
        },
      );

      test(
        'toCypherWithPlaceholdersWithPrefix works with custom properties and ignored fields',
        () {
          final product = Product(
            id: CypherId.value(1),
            name: 'Widget',
            internalCode: 'INTERNAL123',
            price: 9.99,
          );

          expect(
            product.toCypherWithPlaceholdersWithPrefix('p', 'prod_'),
            equals(
              '(p:Product {productName: \$prod_productName, price: \$prod_price})',
            ),
          );
        },
      );
    });

    group('FreezedUser class (Freezed with no fromCypherMap)', () {
      test('cypherParameters works with Freezed classes', () {
        final user = FreezedUser(
          id: CypherId.value(1),
          name: 'Alice',
          email: 'alice@example.com',
          password: 'secret123',
          bio: 'Developer',
        );

        expect(user.cypherParameters, {
          'name': 'Alice',
          'emailAddress':
              'alice@example.com', // Custom name from @CypherProperty
          'bio': 'Developer',
          // password should be ignored
        });

        expect(user.cypherParameters.containsKey('password'), isFalse);
      });

      test('handles nullable fields in Freezed classes', () {
        final user = FreezedUser(
          id: CypherId.value(1),
          name: 'Alice',
          email: 'alice@example.com',
          password: 'secret123',
          bio: null, // nullable field
        );

        expect(user.cypherParameters['bio'], isNull);
      });

      test('cypherProperties works with Freezed classes', () {
        final user = FreezedUser(
          id: CypherId.value(1),
          name: 'Alice',
          email: 'alice@example.com',
          password: 'secret123',
          bio: 'Developer',
        );

        expect(
          user.cypherProperties,
          equals('{name: \$name, emailAddress: \$emailAddress, bio: \$bio}'),
        );
      });

      test('toCypherWithPlaceholders works with Freezed classes', () {
        final user = FreezedUser(
          id: CypherId.value(1),
          name: 'Alice',
          email: 'alice@example.com',
          password: 'secret123',
          bio: 'Developer',
        );

        expect(
          user.toCypherWithPlaceholders('fu'),
          equals(
            '(fu:FreezedUser {name: \$name, emailAddress: \$emailAddress, bio: \$bio})',
          ),
        );
      });

      test('cypherPropertiesWithPrefix works with Freezed classes', () {
        final user = FreezedUser(
          id: CypherId.value(1),
          name: 'Alice',
          email: 'alice@example.com',
          password: 'secret123',
          bio: 'Developer',
        );

        expect(
          user.cypherPropertiesWithPrefix('fu_'),
          equals(
            '{name: \$fu_name, emailAddress: \$fu_emailAddress, bio: \$fu_bio}',
          ),
        );
      });

      test('cypherParametersWithPrefix works with Freezed classes', () {
        final user = FreezedUser(
          id: CypherId.value(1),
          name: 'Alice',
          email: 'alice@example.com',
          password: 'secret123',
          bio: 'Developer',
        );

        expect(user.cypherParametersWithPrefix('fu_'), {
          'fu_name': 'Alice',
          'fu_emailAddress':
              'alice@example.com', // Custom name from @CypherProperty
          'fu_bio': 'Developer',
          // password should be ignored
        });

        expect(
          user.cypherParametersWithPrefix('fu_').containsKey('fu_password'),
          isFalse,
        );
      });

      test('toCypherWithPlaceholdersWithPrefix works with Freezed classes', () {
        final user = FreezedUser(
          id: CypherId.value(1),
          name: 'Alice',
          email: 'alice@example.com',
          password: 'secret123',
          bio: 'Developer',
        );

        expect(
          user.toCypherWithPlaceholdersWithPrefix('fu', 'fu_'),
          equals(
            '(fu:FreezedUser {name: \$fu_name, emailAddress: \$fu_emailAddress, bio: \$fu_bio})',
          ),
        );
      });
    });

    group('JsonUser class (Freezed + json_serializable + CypherId)', () {
      test('CypherId JSON serialization works', () {
        // Test CypherId.none() serialization
        final noneId = CypherId.none();
        expect(noneId.toJson(), isNull);
        expect(CypherId.fromJson(null), equals(noneId));

        // Test CypherId.value() serialization
        final valueId = CypherId.value(42);
        expect(valueId.toJson(), equals(42));
        expect(CypherId.fromJson(42), equals(valueId));
      });

      test('JsonUser with CypherId.none() serializes correctly', () {
        final user = JsonUser(
          id: CypherId.none(),
          name: 'John Doe',
          email: 'john@example.com',
          age: 30,
          internalNotes: 'Secret notes',
        );

        final json = user.toJson();
        expect(json['id'], isNull);
        expect(json['name'], equals('John Doe'));
        expect(json['email'], equals('john@example.com'));
        expect(json['age'], equals(30));
        expect(
          json.containsKey('internalNotes'),
          isTrue,
        ); // json_serializable includes all fields

        final reconstructed = JsonUser.fromJson(json);
        expect(reconstructed.id.hasNoId, isTrue);
        expect(reconstructed.name, equals('John Doe'));
        expect(reconstructed.email, equals('john@example.com'));
        expect(reconstructed.age, equals(30));
      });

      test('JsonUser with CypherId.value() serializes correctly', () {
        final user = JsonUser(
          id: CypherId.value(123),
          name: 'Jane Doe',
          email: 'jane@example.com',
          age: 25,
          internalNotes: 'More secret notes',
        );

        final json = user.toJson();
        expect(json['id'], equals(123));
        expect(json['name'], equals('Jane Doe'));
        expect(json['email'], equals('jane@example.com'));
        expect(json['age'], equals(25));

        final reconstructed = JsonUser.fromJson(json);
        expect(reconstructed.id.hasId, isTrue);
        expect(reconstructed.id.idOrThrow, equals(123));
        expect(reconstructed.name, equals('Jane Doe'));
        expect(reconstructed.email, equals('jane@example.com'));
        expect(reconstructed.age, equals(25));
      });

      test('JsonUser cypher properties exclude id and ignored fields', () {
        final user = JsonUser(
          id: CypherId.value(456),
          name: 'Bob Smith',
          email: 'bob@example.com',
          age: 35,
          internalNotes: 'Internal stuff',
        );

        // Cypher properties should exclude id and internalNotes
        expect(user.cypherParameters, {
          'name': 'Bob Smith',
          'email': 'bob@example.com',
          'userAge': 35, // Custom name from @CypherProperty
        });

        expect(user.cypherPropertyNames, equals(['name', 'email', 'userAge']));
        expect(
          user.cypherProperties,
          equals('{name: \$name, email: \$email, userAge: \$userAge}'),
        );
      });

      test('JsonUser fromNode works with CypherId', () {
        final boltNode = BoltNode(
          PsInt.compact(789),
          PsList([PsString('JsonUser')]),
          PsDictionary({
            PsString('name'): PsString('Alice Johnson'),
            PsString('email'): PsString('alice@example.com'),
            PsString('userAge'): PsInt.compact(28),
          }),
        );
        final node = Node.fromBolt(boltNode);

        final user = JsonUser.fromNode(node);

        expect(user.id.hasId, isTrue);
        expect(user.id.idOrThrow, equals(789));
        expect(user.name, equals('Alice Johnson'));
        expect(user.email, equals('alice@example.com'));
        expect(user.age, equals(28));
        expect(user.internalNotes, isNull); // Not in node properties
      });

      test('JsonUser handles nullable fields correctly', () {
        final user = JsonUser(
          id: CypherId.none(),
          name: 'Test User',
          email: 'test@example.com',
          age: null, // nullable field
          internalNotes: null, // nullable field
        );

        final json = user.toJson();
        expect(json['age'], isNull);
        expect(json['internalNotes'], isNull);

        final reconstructed = JsonUser.fromJson(json);
        expect(reconstructed.age, isNull);
        expect(reconstructed.internalNotes, isNull);

        // Cypher parameters should include null values
        expect(user.cypherParameters, {
          'name': 'Test User',
          'email': 'test@example.com',
          'userAge': null,
        });
      });
    });

    group('ModernUser class (with CypherElementId)', () {
      test('CypherElementId JSON serialization works', () {
        // Test CypherElementId.none() serialization
        final noneId = CypherElementId.none();
        expect(noneId.toJson(), isNull);
        expect(CypherElementId.fromJson(null), equals(noneId));

        // Test CypherElementId.value() serialization
        final valueId = CypherElementId.value('4:abc123:42');
        expect(valueId.toJson(), equals('4:abc123:42'));
        expect(CypherElementId.fromJson('4:abc123:42'), equals(valueId));
      });

      test('cypherParameters returns correct map', () {
        final user = ModernUser(
          elementId: CypherElementId.value('4:abc123:1'),
          name: 'Alice',
          email: 'alice@example.com',
        );

        expect(user.cypherParameters, {
          'name': 'Alice',
          'email': 'alice@example.com',
        });
      });

      test('cypherProperties returns correct Cypher syntax', () {
        final user = ModernUser(
          elementId: CypherElementId.value('4:abc123:1'),
          name: 'Alice',
          email: 'alice@example.com',
        );

        expect(user.cypherProperties, equals('{name: \$name, email: \$email}'));
      });

      test('fromNode creates correct instance with elementId', () {
        final boltNode = BoltNode(
          PsInt.compact(1),
          PsList([PsString('ModernUser')]),
          PsDictionary({
            PsString('name'): PsString('Alice'),
            PsString('email'): PsString('alice@example.com'),
          }),
          elementId: PsString('4:abc123:1'),
        );
        final node = Node.fromBolt(boltNode);

        final user = ModernUser.fromNode(node);

        expect(user.elementId.elementIdOrThrow, equals('4:abc123:1'));
        expect(user.name, equals('Alice'));
        expect(user.email, equals('alice@example.com'));
      });

      test('CypherElementId.none() behaves correctly', () {
        final user = ModernUser(
          elementId: CypherElementId.none(),
          name: 'Bob',
          email: 'bob@example.com',
        );

        expect(user.elementId.hasNoElementId, isTrue);
        expect(user.elementId.hasElementId, isFalse);
        expect(user.elementId.elementIdOrNull, isNull);
        expect(
          () => user.elementId.elementIdOrThrow,
          throwsA(isA<StateError>()),
        );
      });

      test('CypherElementId.value() behaves correctly', () {
        final user = ModernUser(
          elementId: CypherElementId.value('4:abc123:99'),
          name: 'Charlie',
          email: 'charlie@example.com',
        );

        expect(user.elementId.hasElementId, isTrue);
        expect(user.elementId.hasNoElementId, isFalse);
        expect(user.elementId.elementIdOrNull, equals('4:abc123:99'));
        expect(user.elementId.elementIdOrThrow, equals('4:abc123:99'));
      });
    });

    group('HybridUser class (with both CypherId and CypherElementId)', () {
      test('cypherParameters returns correct map', () {
        final user = HybridUser(
          legacyId: CypherId.value(42),
          elementId: CypherElementId.value('4:abc123:42'),
          username: 'hybrid_user',
        );

        expect(user.cypherParameters, {'username': 'hybrid_user'});
      });

      test('fromNode creates correct instance with both IDs', () {
        final boltNode = BoltNode(
          PsInt.compact(42),
          PsList([PsString('HybridUser')]),
          PsDictionary({PsString('username'): PsString('hybrid_user')}),
          elementId: PsString('4:abc123:42'),
        );
        final node = Node.fromBolt(boltNode);

        final user = HybridUser.fromNode(node);

        expect(user.legacyId.idOrThrow, equals(42));
        expect(user.elementId.elementIdOrThrow, equals('4:abc123:42'));
        expect(user.username, equals('hybrid_user'));
      });

      test('both ID types work independently', () {
        final user = HybridUser(
          legacyId: CypherId.value(123),
          elementId: CypherElementId.value('4:def456:123'),
          username: 'test_hybrid',
        );

        // Test CypherId
        expect(user.legacyId.hasId, isTrue);
        expect(user.legacyId.idOrThrow, equals(123));
        expect(user.legacyId.idOrNull, equals(123));

        // Test CypherElementId
        expect(user.elementId.hasElementId, isTrue);
        expect(user.elementId.elementIdOrThrow, equals('4:def456:123'));
        expect(user.elementId.elementIdOrNull, equals('4:def456:123'));
      });

      test('both ID types can be unset', () {
        final user = HybridUser(
          legacyId: CypherId.none(),
          elementId: CypherElementId.none(),
          username: 'new_hybrid',
        );

        expect(user.legacyId.hasNoId, isTrue);
        expect(user.elementId.hasNoElementId, isTrue);
        expect(user.legacyId.idOrNull, isNull);
        expect(user.elementId.elementIdOrNull, isNull);
      });
    });
  });
}
