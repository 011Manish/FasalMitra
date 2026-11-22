class MarketplaceListing {
  MarketplaceListing({
    required this.id,
    required this.sellerId,
    this.farmId,
    required this.title,
    this.description,
    required this.unit,
    required this.quantity,
    required this.price,
    this.currency = 'NPR',
    this.status = 'active',
    required this.createdAt,
    this.stateProvince,
    this.district,
    this.municipality,
    this.availableFrom,
    this.isHidden = false,
  });

  final String id;
  final String sellerId;
  final String? farmId;
  final String title; // crop name
  final String? description;
  final String unit;
  final double quantity;
  final double price;
  final String currency;
  final String status; // 'active' | 'sold' | 'cancelled' | 'expired'
  final DateTime createdAt;
  final String? stateProvince;
  final String? district;
  final String? municipality;
  final DateTime? availableFrom;
  final bool isHidden;

  bool get isActive => status == 'active';

  String get locationText => [municipality, district, stateProvince]
      .whereType<String>()
      .where((s) => s.trim().isNotEmpty)
      .join(', ');

  factory MarketplaceListing.fromMap(Map<String, dynamic> row) =>
      MarketplaceListing(
        id: row['id'] as String,
        sellerId: row['seller_id'] as String,
        farmId: row['farm_id'] as String?,
        title: row['title'] as String,
        description: row['description'] as String?,
        unit: row['unit'] as String,
        quantity: (row['quantity'] as num).toDouble(),
        price: (row['price'] as num).toDouble(),
        currency: (row['currency'] as String?) ?? 'NPR',
        status: row['status'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        stateProvince: row['state_province'] as String?,
        district: row['district'] as String?,
        municipality: row['municipality'] as String?,
        availableFrom: row['available_from'] == null
            ? null
            : DateTime.parse(row['available_from'] as String),
        isHidden: (row['is_hidden'] as bool?) ?? false,
      );

  Map<String, dynamic> toInsert(String sellerId) => {
        'seller_id': sellerId,
        'farm_id': farmId,
        'title': title,
        'description': description,
        'unit': unit,
        'quantity': quantity,
        'price': price,
        'currency': currency,
        'state_province': stateProvince,
        'district': district,
        'municipality': municipality,
        'available_from': availableFrom?.toIso8601String().substring(0, 10),
      };
}

class ListingPhoto {
  ListingPhoto({
    required this.id,
    required this.listingId,
    required this.storagePath,
  });

  final String id;
  final String listingId;
  final String storagePath;

  factory ListingPhoto.fromMap(Map<String, dynamic> row) => ListingPhoto(
        id: row['id'] as String,
        listingId: row['listing_id'] as String,
        storagePath: row['storage_path'] as String,
      );
}

class ListingEnquiry {
  ListingEnquiry({
    required this.id,
    required this.listingId,
    required this.buyerId,
    this.buyerName,
    required this.message,
    this.contactPhone,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String listingId;
  final String buyerId;
  final String? buyerName;
  final String message;
  final String? contactPhone;
  final String status;
  final DateTime createdAt;

  factory ListingEnquiry.fromMap(Map<String, dynamic> row) => ListingEnquiry(
        id: row['id'] as String,
        listingId: row['listing_id'] as String,
        buyerId: row['buyer_id'] as String,
        buyerName: row['buyer_name'] as String?,
        message: row['message'] as String,
        contactPhone: row['contact_phone'] as String?,
        status: (row['status'] as String?) ?? '',
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}