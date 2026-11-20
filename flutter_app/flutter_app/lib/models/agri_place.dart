enum AgriPlaceType {
  agriShop,
  coldStorage,
  equipmentRental,
  collectionCenter,
  veterinaryClinic,
  fertilizerDealer,
  seedStore,
  all,
}

extension AgriPlaceTypeExtension on AgriPlaceType {
  String get label {
    switch (this) {
      case AgriPlaceType.agriShop:
        return 'Agri Shops';
      case AgriPlaceType.coldStorage:
        return 'Cold Storage';
      case AgriPlaceType.equipmentRental:
        return 'Equipment Rental';
      case AgriPlaceType.collectionCenter:
        return 'Collection Centers';
      case AgriPlaceType.veterinaryClinic:
        return 'Vet Clinics';
      case AgriPlaceType.fertilizerDealer:
        return 'Fertilizer Dealers';
      case AgriPlaceType.seedStore:
        return 'Seed Stores';
      case AgriPlaceType.all:
        return 'All';
    }
  }

  String get icon {
    switch (this) {
      case AgriPlaceType.agriShop:
        return '🌾';
      case AgriPlaceType.coldStorage:
        return '❄️';
      case AgriPlaceType.equipmentRental:
        return '🚜';
      case AgriPlaceType.collectionCenter:
        return '📦';
      case AgriPlaceType.veterinaryClinic:
        return '🐄';
      case AgriPlaceType.fertilizerDealer:
        return '🧪';
      case AgriPlaceType.seedStore:
        return '🌱';
      case AgriPlaceType.all:
        return '📍';
    }
  }

  List<String> get searchKeywords {
    switch (this) {
      case AgriPlaceType.agriShop:
        return ['agriculture shop', 'krishi pasal', 'agri store'];
      case AgriPlaceType.coldStorage:
        return ['cold storage', 'refrigeration storage'];
      case AgriPlaceType.equipmentRental:
        return ['tractor rental', 'farm equipment rental', 'agricultural equipment'];
      case AgriPlaceType.collectionCenter:
        return ['agri collection center', 'vegetable collection', 'crop collection'];
      case AgriPlaceType.veterinaryClinic:
        return ['veterinary clinic', 'animal hospital', 'pashu clinic'];
      case AgriPlaceType.fertilizerDealer:
        return ['fertilizer dealer', 'malpot pasal', 'manure store'];
      case AgriPlaceType.seedStore:
        return ['seed store', 'biu bijan', 'nursery'];
      case AgriPlaceType.all:
        return ['agriculture', 'krishi'];
    }
  }
}

class AgriPlace {
  final String placeId;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final double? rating;
  final int? userRatingsTotal;
  final bool? isOpen;
  final String? phoneNumber;
  final double? distanceKm;
  final AgriPlaceType placeType;
  final String? photoReference;

  const AgriPlace({
    required this.placeId,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.userRatingsTotal,
    this.isOpen,
    this.phoneNumber,
    this.distanceKm,
    required this.placeType,
    this.photoReference,
  });

  factory AgriPlace.fromGooglePlacesJson(
    Map<String, dynamic> json,
    AgriPlaceType type,
  ) {
    final geometry = json['geometry']?['location'];
    final openingHours = json['opening_hours'];
    return AgriPlace(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      address: json['vicinity'] ?? json['formatted_address'],
      latitude: (geometry?['lat'] ?? 0.0).toDouble(),
      longitude: (geometry?['lng'] ?? 0.0).toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      isOpen: openingHours?['open_now'] as bool?,
      placeType: type,
      photoReference: (json['photos'] as List?)?.isNotEmpty == true
          ? json['photos'][0]['photo_reference'] as String?
          : null,
    );
  }

  AgriPlace copyWith({double? distanceKm}) {
    return AgriPlace(
      placeId: placeId,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
      userRatingsTotal: userRatingsTotal,
      isOpen: isOpen,
      phoneNumber: phoneNumber,
      distanceKm: distanceKm ?? this.distanceKm,
      placeType: placeType,
      photoReference: photoReference,
    );
  }
}