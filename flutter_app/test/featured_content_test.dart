import 'package:fasalmitra/models/learning_content.dart';
import 'package:fasalmitra/services/home_content_service.dart';
import 'package:flutter_test/flutter_test.dart';

LearningContent _item(
  String id,
  String language, {
  String type = videoContentType,
}) =>
    LearningContent(
      id: id,
      contentType: type,
      title: 'Title $id',
      summary: 'Summary',
      body: '',
      language: language,
    );

void main() {
  group('pickFeaturedVideo', () {
    test('prefers Nepali over a newer English video', () {
      final result =
          pickFeaturedVideo([_item('en-new', 'en'), _item('ne-old', 'ne')]);
      expect(result?.id, 'ne-old');
    });

    test('prefers Hindi over English when there is no Nepali', () {
      final result = pickFeaturedVideo([_item('en', 'en'), _item('hi', 'hi')]);
      expect(result?.id, 'hi');
    });

    test('takes the first, newest, video within a language', () {
      final result =
          pickFeaturedVideo([_item('new', 'ne'), _item('old', 'ne')]);
      expect(result?.id, 'new');
    });

    test('falls back to the first video of another language', () {
      final result = pickFeaturedVideo([_item('fr', 'fr')]);
      expect(result?.id, 'fr');
    });

    test('ignores items that are not videos', () {
      final result = pickFeaturedVideo(
          [_item('course', 'ne', type: 'course'), _item('video', 'en')]);
      expect(result?.id, 'video');
    });

    test('returns null when there is no video', () {
      expect(pickFeaturedVideo(const []), isNull);
      expect(pickFeaturedVideo([_item('c', 'ne', type: 'course')]), isNull);
    });
  });

  group('firstNameOf', () {
    test('returns the first word', () {
      expect(firstNameOf('Ram Bahadur Thapa'), 'Ram');
    });

    test('trims spaces', () {
      expect(firstNameOf('  Sita  '), 'Sita');
    });

    test('returns null for empty, blank or missing names', () {
      expect(firstNameOf(null), isNull);
      expect(firstNameOf(''), isNull);
      expect(firstNameOf('   '), isNull);
    });
  });
}
