final _phoneRe = RegExp(r'^\+?[0-9]{7,15}$');
final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

const phoneHint = 'Enter a valid phone number, e.g. +9779812345678';

String? phoneError(String value) =>
    _phoneRe.hasMatch(value.trim()) ? null : phoneHint;

String? optionalPhoneError(String value) =>
    value.trim().isEmpty ? null : phoneError(value);

String? emailError(String value) =>
    _emailRe.hasMatch(value.trim()) ? null : 'Enter a valid email address.';

String? passwordError(String value) =>
    value.length >= 8 ? null : 'Password must be at least 8 characters.';

String? nameError(String value) =>
    value.trim().isEmpty ? 'Enter your full name.' : null;
