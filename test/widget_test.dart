import 'package:flutter_test/flutter_test.dart';
import 'package:heloappa/core/utils/extensions.dart';

void main() {
  group('String Extensions Tests', () {
    test('capitalize() should capitalize first character of a string', () {
      expect('hello'.capitalize(), 'Hello');
      expect('world'.capitalize(), 'World');
      expect(''.capitalize(), '');
    });

    test('isValidEmail() should correctly validate email formats', () {
      expect('test@example.com'.isValidEmail(), true);
      expect('invalid-email'.isValidEmail(), false);
      expect('name.surname@domain.co.uk'.isValidEmail(), true);
    });
  });
}
