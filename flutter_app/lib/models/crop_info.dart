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

class CropSuggestion {
  CropSuggestion({
    required this.crop,
    required this.score,
    required this.reasons,
  });

  final CropInfo crop;
  final int score; // out of 5
  final List<String> reasons;
}
