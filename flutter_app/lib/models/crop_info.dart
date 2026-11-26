const cropSeasons = ['monsoon', 'winter', 'spring'];
const waterLevels = ['low', 'medium', 'high'];

const guidanceDisclaimer = 'General guidance, not a guaranteed recommendation.';
const unverifiedNotice = 'General guidance. Not yet verified by an expert.';

String capitalized(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

class CropInfo {
  CropInfo({
    required this.id,
    required this.cropType,
    required this.name,
    this.nameNe,
    required this.seasons,
    required this.durationDays,
    required this.waterNeed,
    required this.suitableSoils,
    required this.growingSteps,
    this.notes,
    required this.isVerified,
  });

  final String id;
  final String cropType;
  final String name;
  final String? nameNe;
  final List<String> seasons;
  final int durationDays;
  final String waterNeed;
  final List<String> suitableSoils;
  final List<String> growingSteps;
  final String? notes;
  final bool isVerified;

  String get seasonsText => seasons.map(capitalized).join(', ');
  String get soilsText => suitableSoils.map(capitalized).join(', ');
  String get durationText => 'About $durationDays days';

  factory CropInfo.fromMap(Map<String, dynamic> m) => CropInfo(
        id: m['id'] as String,
        cropType: m['crop_type'] as String,
        name: m['name'] as String,
        nameNe: m['name_ne'] as String?,
        seasons: List<String>.from(m['seasons'] as List? ?? const []),
        durationDays: m['duration_days'] as int,
        waterNeed: (m['water_need'] as String?) ?? 'medium',
        suitableSoils:
            List<String>.from(m['suitable_soils'] as List? ?? const []),
        growingSteps: (m['growing_steps'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        notes: m['notes'] as String?,
        isVerified: (m['is_verified'] as bool?) ?? false,
      );
}

class CropMatch {
  CropMatch({required this.crop, required this.reasons});

  final CropInfo crop;
  final List<String> reasons;
}

/// Keeps a crop when it grows in [season], suits [soil], and its water need
/// does not exceed the [water] available (low < medium < high).
/// A crop or input with an unknown water level never matches.
List<CropMatch> suggestCrops(
  List<CropInfo> crops, {
  required String season,
  required String soil,
  required String water,
}) {
  final available = waterLevels.indexOf(water);
  final matches = <CropMatch>[];
  for (final crop in crops) {
    final need = waterLevels.indexOf(crop.waterNeed);
    if (available < 0 || need < 0 || need > available) continue;
    if (!crop.seasons.contains(season)) continue;
    if (!crop.suitableSoils.contains(soil)) continue;
    matches.add(CropMatch(crop: crop, reasons: [
      'Grown in the $season season',
      'Suits $soil soil',
      'Needs ${crop.waterNeed} water; you have $water water available',
    ]));
  }
  matches.sort((a, b) => a.crop.name.compareTo(b.crop.name));
  return matches;
}
