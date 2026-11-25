import 'package:fasalmitra/models/crop_info.dart';
import 'package:flutter_test/flutter_test.dart';

CropInfo _crop({
  String name = 'Rice',
  List<String> seasons = const ['monsoon'],
  List<String> soils = const ['clay'],
  String water = 'high',
}) =>
    CropInfo(
      id: name,
      cropType: name.toLowerCase(),
      name: name,
      seasons: seasons,
      durationDays: 100,
      waterNeed: water,
      suitableSoils: soils,
      growingSteps: const [],
      isVerified: false,
    );

List<String> _names(List<CropMatch> matches) =>
    [for (final m in matches) m.crop.name];

void main() {
  group('suggestCrops', () {
    test('returns a crop that matches season, soil and water', () {
      final result = suggestCrops([_crop()],
          season: 'monsoon', soil: 'clay', water: 'high');
      expect(_names(result), ['Rice']);
      expect(result.single.reasons, hasLength(3));
    });

    test('excludes a crop from another season', () {
      final result = suggestCrops([_crop()],
          season: 'winter', soil: 'clay', water: 'high');
      expect(result, isEmpty);
    });

    test('excludes a crop that does not suit the soil', () {
      final result = suggestCrops([_crop()],
          season: 'monsoon', soil: 'sandy', water: 'high');
      expect(result, isEmpty);
    });

    test('accepts a low-need crop with high water', () {
      final result = suggestCrops([_crop(water: 'low')],
          season: 'monsoon', soil: 'clay', water: 'high');
      expect(_names(result), ['Rice']);
    });

    test('accepts a crop whose need equals the water available', () {
      final result = suggestCrops([_crop(water: 'medium')],
          season: 'monsoon', soil: 'clay', water: 'medium');
      expect(_names(result), ['Rice']);
    });

    test('rejects a high-need crop with low water', () {
      final result = suggestCrops([_crop(water: 'high')],
          season: 'monsoon', soil: 'clay', water: 'low');
      expect(result, isEmpty);
    });

    test('rejects a crop with an unknown water need', () {
      final result = suggestCrops([_crop(water: 'extreme')],
          season: 'monsoon', soil: 'clay', water: 'high');
      expect(result, isEmpty);
    });

    test('sorts matches by name', () {
      final result = suggestCrops(
        [_crop(name: 'Wheat'), _crop(name: 'Maize')],
        season: 'monsoon',
        soil: 'clay',
        water: 'high',
      );
      expect(_names(result), ['Maize', 'Wheat']);
    });

    test('returns nothing for an empty crop list', () {
      final result = suggestCrops(const [],
          season: 'monsoon', soil: 'clay', water: 'high');
      expect(result, isEmpty);
    });
  });
}
