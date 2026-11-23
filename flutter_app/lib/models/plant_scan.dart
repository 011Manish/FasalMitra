class PlantScan {
  const PlantScan({
    required this.id,
    required this.farmId,
    required this.photoStoragePath,
    required this.analysis,
    required this.confidenceLevel,
    required this.createdAt,
  });

  final String id;
  final String? farmId;
  final String photoStoragePath;
  final Map<String, dynamic> analysis;
  final String confidenceLevel;
  final DateTime createdAt;

  factory PlantScan.fromMap(Map<String, dynamic> map) => PlantScan(
        id: map['id'] as String,
        farmId: map['farm_id'] as String?,
        photoStoragePath: map['photo_storage_path'] as String,
        analysis: Map<String, dynamic>.from(map['analysis'] as Map),
        confidenceLevel: map['confidence_level'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
