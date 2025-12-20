import 'package:flutter_test/flutter_test.dart';
import 'package:hydroponic_app/utils/validators.dart';

void main() {
  group('Email Validator', () {
    test('Valid emails return null', () {
      expect(Validators.email('test@example.com'), null);
      expect(Validators.email('user.name@domain.co.uk'), null);
      expect(Validators.email('test123@test.org'), null);
    });

    test('Empty email returns error', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email(null), 'Email is required');
    });

    test('Invalid email format returns error', () {
      expect(Validators.email('notanemail'), contains('valid email'));
      expect(Validators.email('test@'), contains('valid email'));
      expect(Validators.email('@example.com'), contains('valid email'));
    });
  });

  group('Password Validator', () {
    test('Valid passwords return null (default 8 char min)', () {
      expect(Validators.password('Password1'), null);
      expect(Validators.password('TestPass1'), null);
    });

    test('Empty password returns error', () {
      expect(Validators.password(''), 'Password is required');
      expect(Validators.password(null), 'Password is required');
    });

    test('Short password returns error', () {
      expect(Validators.password('123'), contains('at least'));
      expect(Validators.password('12345'), contains('at least'));
    });
  });

  group('Name Validator', () {
    test('Valid names return null', () {
      expect(Validators.name('John Doe'), null);
      expect(Validators.name('Alice'), null);
      expect(Validators.name('Bob Smith'), null);
    });

    test('Empty name returns error', () {
      expect(Validators.name(''), contains('required'));
      expect(Validators.name(null), contains('required'));
    });
  });

  group('Confirm Password Validator', () {
    test('Matching passwords return null', () {
      expect(Validators.confirmPassword('password123', 'password123'), null);
    });

    test('Empty confirm password returns error', () {
      expect(Validators.confirmPassword('', 'password'), contains('confirm'));
      expect(Validators.confirmPassword(null, 'password'), contains('confirm'));
    });

    test('Non-matching passwords return error', () {
      expect(
        Validators.confirmPassword('password123', 'password456'),
        contains('match'),
      );
    });
  });
}
