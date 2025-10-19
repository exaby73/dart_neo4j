import 'package:test/test.dart';

import '../fixtures/user.dart';
import '../fixtures/person.dart';
import '../fixtures/product.dart';
import '../fixtures/freezed_user.dart';

void main() {
  group('Generated API Tests', () {
    group('User class (with fromCypherMap)', () {
      test('cypherParameters returns correct map', () {
        final user = User(id: '1', name: 'John', email: 'john@example.com');

        expect(user.cypherParameters, {
          'id': '1',
          'name': 'John',
          'email': 'john@example.com',
        });
      });

      test('toCypherMap returns same as cypherParameters', () {
        final user = User(id: '1', name: 'John', email: 'john@example.com');

        expect(user.toCypherMap(), equals(user.cypherParameters));
      });

      test('nodeLabel returns correct label', () {
        final user = User(id: '1', name: 'John', email: 'john@example.com');

        expect(user.nodeLabel, equals('User'));
      });

      test('cypherPropertyNames returns correct list', () {
        final user = User(id: '1', name: 'John', email: 'john@example.com');

        expect(user.cypherPropertyNames, equals(['id', 'name', 'email']));
      });

      test('cypherProperties returns correct Cypher syntax', () {
        final user = User(id: '1', name: 'John', email: 'john@example.com');

        expect(
          user.cypherProperties,
          equals('{id: \$id, name: \$name, email: \$email}'),
        );
      });

      test('toCypherWithPlaceholders returns complete node syntax', () {
        final user = User(id: '1', name: 'John', email: 'john@example.com');

        expect(
          user.toCypherWithPlaceholders('u'),
          equals('(u:User {id: \$id, name: \$name, email: \$email})'),
        );
      });

      test('fromCypherMap creates correct instance', () {
        final map = {'id': '1', 'name': 'John', 'email': 'john@example.com'};

        final user = User.fromCypherMap(map);

        expect(user.id, equals('1'));
        expect(user.name, equals('John'));
        expect(user.email, equals('john@example.com'));
      });

      test(
        'cypherPropertiesWithPrefix returns prefixed Cypher properties string',
        () {
          final user = User(id: '1', name: 'John', email: 'john@example.com');

          expect(
            user.cypherPropertiesWithPrefix('user_'),
            equals('{id: \$user_id, name: \$user_name, email: \$user_email}'),
          );
        },
      );

      test('cypherPropertiesWithPrefix works with empty prefix', () {
        final user = User(id: '1', name: 'John', email: 'john@example.com');

        expect(
          user.cypherPropertiesWithPrefix(''),
          equals('{id: \$id, name: \$name, email: \$email}'),
        );
      });

      test('cypherParametersWithPrefix returns prefixed parameter map', () {
        final user = User(id: '1', name: 'John', email: 'john@example.com');

        expect(user.cypherParametersWithPrefix('user_'), {
          'user_id': '1',
          'user_name': 'John',
          'user_email': 'john@example.com',
        });
      });

      test('cypherParametersWithPrefix works with empty prefix', () {
        final user = User(id: '1', name: 'John', email: 'john@example.com');

        expect(user.cypherParametersWithPrefix(''), {
          'id': '1',
          'name': 'John',
          'email': 'john@example.com',
        });
      });

      test(
        'toCypherWithPlaceholdersWithPrefix returns prefixed Cypher syntax',
        () {
          final user = User(id: '1', name: 'John', email: 'john@example.com');

          expect(
            user.toCypherWithPlaceholdersWithPrefix('u', 'user_'),
            equals(
              '(u:User {id: \$user_id, name: \$user_name, email: \$user_email})',
            ),
          );
        },
      );

      test('toCypherWithPlaceholdersWithPrefix works with empty prefix', () {
        final user = User(id: '1', name: 'John', email: 'john@example.com');

        expect(
          user.toCypherWithPlaceholdersWithPrefix('u', ''),
          equals('(u:User {id: \$id, name: \$name, email: \$email})'),
        );
      });
    });

    group('Customer class (with custom label)', () {
      test('nodeLabel returns custom label', () {
        final customer = Customer(id: '1', name: 'Jane');

        expect(customer.nodeLabel, equals('Person'));
      });

      test('cypherParameters returns correct map', () {
        final customer = Customer(id: '1', name: 'Jane');

        expect(customer.cypherParameters, {'id': '1', 'name': 'Jane'});
      });

      test('cypherProperties returns correct Cypher syntax', () {
        final customer = Customer(id: '1', name: 'Jane');

        expect(customer.cypherProperties, equals('{id: \$id, name: \$name}'));
      });

      test('toCypherWithPlaceholders uses custom label', () {
        final customer = Customer(id: '1', name: 'Jane');

        expect(
          customer.toCypherWithPlaceholders('c'),
          equals('(c:Person {id: \$id, name: \$name})'),
        );
      });

      test('fromCypherMap creates correct instance', () {
        final map = {'id': '1', 'name': 'Jane'};

        final customer = Customer.fromCypherMap(map);

        expect(customer.id, equals('1'));
        expect(customer.name, equals('Jane'));
      });
    });

    group('Product class (with @CypherProperty and no fromCypherMap)', () {
      test(
        'cypherParameters uses custom property names and ignores fields',
        () {
          final product = Product(
            id: '1',
            name: 'Widget',
            internalCode: 'INTERNAL123',
            price: 9.99,
          );

          expect(product.cypherParameters, {
            'id': '1',
            'productName': 'Widget', // Custom name from @CypherProperty
            'price': 9.99,
            // internalCode should be ignored
          });

          expect(product.cypherParameters.containsKey('internalCode'), isFalse);
        },
      );

      test('cypherPropertyNames excludes ignored fields', () {
        final product = Product(
          id: '1',
          name: 'Widget',
          internalCode: 'INTERNAL123',
          price: 9.99,
        );

        expect(
          product.cypherPropertyNames,
          equals(['id', 'productName', 'price']),
        );
        expect(product.cypherPropertyNames.contains('internalCode'), isFalse);
      });

      test(
        'cypherProperties uses custom property names and excludes ignored fields',
        () {
          final product = Product(
            id: '1',
            name: 'Widget',
            internalCode: 'INTERNAL123',
            price: 9.99,
          );

          expect(
            product.cypherProperties,
            equals('{id: \$id, productName: \$productName, price: \$price}'),
          );
        },
      );

      test(
        'toCypherWithPlaceholders works with custom properties and ignored fields',
        () {
          final product = Product(
            id: '1',
            name: 'Widget',
            internalCode: 'INTERNAL123',
            price: 9.99,
          );

          expect(
            product.toCypherWithPlaceholders('p'),
            equals(
              '(p:Product {id: \$id, productName: \$productName, price: \$price})',
            ),
          );
        },
      );

      test('handles nullable fields correctly', () {
        final product = Product(
          id: '1',
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
            id: '1',
            name: 'Widget',
            internalCode: 'INTERNAL123',
            price: 9.99,
          );

          expect(
            product.cypherPropertiesWithPrefix('prod_'),
            equals(
              '{id: \$prod_id, productName: \$prod_productName, price: \$prod_price}',
            ),
          );
        },
      );

      test(
        'cypherParametersWithPrefix uses custom property names and ignores fields',
        () {
          final product = Product(
            id: '1',
            name: 'Widget',
            internalCode: 'INTERNAL123',
            price: 9.99,
          );

          expect(product.cypherParametersWithPrefix('prod_'), {
            'prod_id': '1',
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
            id: '1',
            name: 'Widget',
            internalCode: 'INTERNAL123',
            price: 9.99,
          );

          expect(
            product.toCypherWithPlaceholdersWithPrefix('p', 'prod_'),
            equals(
              '(p:Product {id: \$prod_id, productName: \$prod_productName, price: \$prod_price})',
            ),
          );
        },
      );
    });

    group('FreezedUser class (Freezed with no fromCypherMap)', () {
      test('cypherParameters works with Freezed classes', () {
        final user = FreezedUser(
          id: '1',
          name: 'Alice',
          email: 'alice@example.com',
          password: 'secret123',
          bio: 'Developer',
        );

        expect(user.cypherParameters, {
          'id': '1',
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
          id: '1',
          name: 'Alice',
          email: 'alice@example.com',
          password: 'secret123',
          bio: null, // nullable field
        );

        expect(user.cypherParameters['bio'], isNull);
      });

      test('cypherProperties works with Freezed classes', () {
        final user = FreezedUser(
          id: '1',
          name: 'Alice',
          email: 'alice@example.com',
          password: 'secret123',
          bio: 'Developer',
        );

        expect(
          user.cypherProperties,
          equals(
            '{id: \$id, name: \$name, emailAddress: \$emailAddress, bio: \$bio}',
          ),
        );
      });

      test('toCypherWithPlaceholders works with Freezed classes', () {
        final user = FreezedUser(
          id: '1',
          name: 'Alice',
          email: 'alice@example.com',
          password: 'secret123',
          bio: 'Developer',
        );

        expect(
          user.toCypherWithPlaceholders('fu'),
          equals(
            '(fu:FreezedUser {id: \$id, name: \$name, emailAddress: \$emailAddress, bio: \$bio})',
          ),
        );
      });

      test('cypherPropertiesWithPrefix works with Freezed classes', () {
        final user = FreezedUser(
          id: '1',
          name: 'Alice',
          email: 'alice@example.com',
          password: 'secret123',
          bio: 'Developer',
        );

        expect(
          user.cypherPropertiesWithPrefix('fu_'),
          equals(
            '{id: \$fu_id, name: \$fu_name, emailAddress: \$fu_emailAddress, bio: \$fu_bio}',
          ),
        );
      });

      test('cypherParametersWithPrefix works with Freezed classes', () {
        final user = FreezedUser(
          id: '1',
          name: 'Alice',
          email: 'alice@example.com',
          password: 'secret123',
          bio: 'Developer',
        );

        expect(user.cypherParametersWithPrefix('fu_'), {
          'fu_id': '1',
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
          id: '1',
          name: 'Alice',
          email: 'alice@example.com',
          password: 'secret123',
          bio: 'Developer',
        );

        expect(
          user.toCypherWithPlaceholdersWithPrefix('fu', 'fu_'),
          equals(
            '(fu:FreezedUser {id: \$fu_id, name: \$fu_name, emailAddress: \$fu_emailAddress, bio: \$fu_bio})',
          ),
        );
      });
    });
  });
}
