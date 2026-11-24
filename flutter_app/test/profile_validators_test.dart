import 'package:agrismart_ai/services/profile_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phoneError accepts 7 to 15 digits with an optional +', () {
    expect(phoneError('+9779812345678'), isNull);
    expect(phoneError('9812345'), isNull);
    expect(phoneError('123456'), phoneHint);
    expect(phoneError('1234567890123456'), phoneHint);
    expect(phoneError('98123abc45'), phoneHint);
    expect(phoneError(''), phoneHint);
  });

  test('optionalPhoneError allows empty but still checks a value', () {
    expect(optionalPhoneError(''), isNull);
    expect(optionalPhoneError('   '), isNull);
    expect(optionalPhoneError('123'), phoneHint);
    expect(optionalPhoneError('+9779812345678'), isNull);
  });

  test('emailError needs something@domain.tld', () {
    expect(emailError('a@b.com'), isNull);
    expect(emailError('a@b'), isNotNull);
    expect(emailError('no-at-sign.com'), isNotNull);
    expect(emailError(''), isNotNull);
  });

  test('passwordError needs 8 characters', () {
    expect(passwordError('12345678'), isNull);
    expect(passwordError('1234567'), isNotNull);
  });

  test('nameError rejects empty and blank names', () {
    expect(nameError('Asha'), isNull);
    expect(nameError(''), isNotNull);
    expect(nameError('   '), isNotNull);
  });
}
