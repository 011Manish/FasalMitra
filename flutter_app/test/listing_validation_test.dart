import 'package:fasalmitra/models/marketplace_listing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateRequired', () {
    test('rejects null and blank text', () {
      expect(validateRequired(null), isNotNull);
      expect(validateRequired('   '), isNotNull);
    });

    test('accepts text', () {
      expect(validateRequired('Tomato'), isNull);
    });
  });

  group('validatePositiveNumber', () {
    test('rejects empty, text, zero, negative and non-finite values', () {
      for (final v in [null, '', 'abc', '0', '-1', 'NaN', 'Infinity']) {
        expect(validatePositiveNumber(v), isNotNull, reason: '$v');
      }
    });

    test('accepts positive numbers with spaces or decimals', () {
      expect(validatePositiveNumber('2.5'), isNull);
      expect(validatePositiveNumber(' 3 '), isNull);
    });
  });

  group('validateEnquiryMessage', () {
    test('rejects an empty message', () {
      expect(validateEnquiryMessage(''), isNotNull);
      expect(validateEnquiryMessage('   '), isNotNull);
    });

    test('rejects more than $maxEnquiryLength characters', () {
      expect(validateEnquiryMessage('a' * (maxEnquiryLength + 1)), isNotNull);
    });

    test('accepts up to $maxEnquiryLength characters', () {
      expect(validateEnquiryMessage('a' * maxEnquiryLength), isNull);
    });
  });

  group('photoExtension', () {
    test('accepts jpg, jpeg, png and webp in any case', () {
      expect(photoExtension('/tmp/a.JPG'), '.jpg');
      expect(photoExtension('/tmp/a.jpeg'), '.jpeg');
      expect(photoExtension('/tmp/a.PNG'), '.png');
      expect(photoExtension('/tmp/a.webp'), '.webp');
    });

    test('rejects heic, other types and paths without an extension', () {
      expect(photoExtension('/tmp/a.heic'), isNull);
      expect(photoExtension('/tmp/a.gif'), isNull);
      expect(photoExtension('/tmp/a'), isNull);
    });
  });

  group('formatNumber', () {
    test('drops a trailing .0', () {
      expect(formatNumber(12), '12');
      expect(formatNumber(12.5), '12.5');
    });
  });
}
