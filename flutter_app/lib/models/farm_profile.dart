class FarmProfile {
  final String id;
  final String userId;
  final String name;
  final String cropType;
  final double landSizeHectares;
  final double? landSizeValue;
  final String landUnit;
  final DateTime plantationDate;
  final String soilType;
  final String irrigationSystem;
  final String? stateProvince;
  final String? district;
  final String? municipality;

  FarmProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.cropType,
    required this.landSizeHectares,
    this.landSizeValue,
    this.landUnit = 'hectare',
    required this.plantationDate,
    required this.soilType,
    required this.irrigationSystem,
    this.stateProvince,
    this.district,
    this.municipality,
  });

  factory FarmProfile.fromMap(Map<String, dynamic> row) => FarmProfile(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        name: row['name'] as String,
        cropType: row['crop_type'] as String,
        landSizeHectares: (row['land_size_hectares'] as num).toDouble(),
        landSizeValue: (row['land_size_value'] as num?)?.toDouble(),
        landUnit: (row['land_unit'] as String?) ?? 'hectare',
        plantationDate: DateTime.parse(row['plantation_date'] as String),
        soilType: row['soil_type'] as String,
        irrigationSystem: row['irrigation_system'] as String,
        stateProvince: row['state_province'] as String?,
        district: row['district'] as String?,
        municipality: row['municipality'] as String?,
      );

  Map<String, dynamic> toInsert(String userId) => {
        'user_id': userId,
        'name': name,
        'crop_type': cropType,
        'land_size_hectares': landSizeHectares,
        'land_size_value': landSizeValue,
        'land_unit': landUnit,
        'plantation_date': plantationDate.toIso8601String().substring(0, 10),
        'soil_type': soilType,
        'irrigation_system': irrigationSystem,
        'state_province': stateProvince,
        'district': district,
        'municipality': municipality,
      };

  /// Land size in the unit the user entered, for example "2 bigha".
  String get landSizeLabel {
    final value = landSizeValue ?? landSizeHectares;
    final unit = landSizeValue == null ? 'hectare' : landUnit;
    final text =
        value == value.roundToDouble() ? value.toInt().toString() : '$value';
    return '$text $unit';
  }

  /// Municipality, district and state in one line. Empty when none is set.
  String get locationSummary => [municipality, district, stateProvince]
      .whereType<String>()
      .where((part) => part.isNotEmpty)
      .join(', ');
}

const cropTypes = [
  'rice',
  'maize',
  'wheat',
  'potato',
  'tomato',
  'cauliflower',
  'onion',
  'millet',
  'lentil',
];
const soilTypes = ['sandy', 'loamy', 'clay', 'silty', 'peaty', 'chalky'];
const irrigationSystems = ['rainfed', 'drip', 'sprinkler', 'flood', 'canal'];

/// Approximate hectares in 1 unit (ropani, kattha and bigha are Nepal values).
const landUnitToHectares = {
  'hectare': 1.0,
  'acre': 0.404686,
  'ropani': 0.050872,
  'kattha': 0.033863,
  'bigha': 0.677263,
};