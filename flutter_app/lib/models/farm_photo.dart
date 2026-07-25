class FarmPhoto {
  final String id;
  final String userId;
  final String farmId;
  final String storagePath;
  final DateTime takenAt;

  FarmPhoto({
    required this.id,
    required this.userId,
    required this.farmId,
    required this.storagePath,
    required this.takenAt,
  });

  factory FarmPhoto.fromMap(Map<String, dynamic> row) => FarmPhoto(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        farmId: row['farm_id'] as String,
        storagePath: row['storage_path'] as String,
        takenAt: DateTime.parse(row['taken_at'] as String),
      );
}
