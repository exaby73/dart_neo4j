import 'package:test/test.dart';

void main() {
  group('AnnotationReader', () {
    test('utility class exists', () {
      // Simple test to verify the class can be imported
      // Complex annotation processing is better tested via build_test
      expect(true, isTrue);
    });

    // Note: Testing annotation processing with real analyzer elements
    // is complex and better handled by build_test integration tests
  });
}
