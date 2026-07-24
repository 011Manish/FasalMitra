import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_app/models/farm_profile.dart';

void main() {
  group('FarmProfile.fromMap', () {
    test('parses a well-formed row', () {
      final farm = FarmProfile.fromMap({
        'id': '11111111-1111-1111-1111-111111111111',
        'user_id': '22222222-2222-2222-2222-222222222222',
        'name': 'North field',
        'crop_type': 'rice',
        'land_size_hectares': 2.5,
        'plantation_date': '2026-04-01',
        'soil_type': 'loamy',
        'irrigation_system': 'drip',
        'location_label': null,
        'latitude': null,
        'longitude': null,
      });
      expect(farm.name, 'North field');
      expect(farm.landSizeHectares, 2.5);
      expect(farm.plantationDate.year, 2026);
    });
  });

  group('enum lists', () {
    test('crop, soil, and irrigation lists match the SQL enums', () {
      expect(cropTypes, ['rice', 'maize', 'wheat']);
      expect(soilTypes, ['sandy', 'loamy', 'clay', 'silty', 'peaty', 'chalky']);
      expect(irrigationSystems, ['rainfed', 'drip', 'sprinkler', 'flood', 'canal']);
    });
  });
}
