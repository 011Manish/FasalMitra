class RentalEquipment {
  RentalEquipment({
    required this.id,
    required this.name,
    required this.category,
    required this.dailyRate,
    required this.description,
    this.photoUrl,
    this.providerName,
    this.providerPhone,
    this.providerAddress,
    this.placeId,
  });

  final String id;
  final String name;
  final String category;
  final double dailyRate;
  final String description;
  final String? photoUrl;
  final String? providerName;
  final String? providerPhone;
  final String? providerAddress;
  final String? placeId;

  factory RentalEquipment.fromMap(Map<String, dynamic> m) => RentalEquipment(
        id: m['id'] as String,
        name: m['name'] as String,
        category: m['category'] as String,
        dailyRate: (m['daily_rate'] as num).toDouble(),
        description: (m['description'] as String?) ?? '',
        photoUrl: m['photo_url'] as String?,
        providerName: m['provider_name'] as String?,
        providerPhone: m['provider_phone'] as String?,
        providerAddress: m['provider_address'] as String?,
        placeId: m['place_id'] as String?,
      );
}
