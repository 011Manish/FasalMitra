const listingCurrencies = ['NPR', 'INR'];
const maxEnquiryLength = 1000;
const _photoExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

abstract final class ListingStatus {
  static const active = 'active';
  static const sold = 'sold';
  static const cancelled = 'cancelled';
}

abstract final class EnquiryStatus {
  static const received = 'new';
  static const contacted = 'contacted';
  static const closed = 'closed';
}

String formatNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

String? validateRequired(String? value) =>
    (value == null || value.trim().isEmpty) ? 'Required' : null;

String? validatePositiveNumber(String? value) {
  final n = double.tryParse(value?.trim() ?? '');
  return (n == null || !n.isFinite || n <= 0)
      ? 'Enter a positive number'
      : null;
}

String? validateEnquiryMessage(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Write a short message to the seller.';
  if (text.length > maxEnquiryLength) {
    return 'Keep the message under $maxEnquiryLength characters.';
  }
  return null;
}

/// Lower-case extension if the bucket accepts it, otherwise null.
String? photoExtension(String path) {
  final dot = path.lastIndexOf('.');
  if (dot == -1) return null;
  final ext = path.substring(dot).toLowerCase();
  return _photoExtensions.contains(ext) ? ext : null;
}

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
    this.status = ListingStatus.active,
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

  bool get isActive => status == ListingStatus.active;

  String get statusLabel => switch (status) {
        ListingStatus.active => 'Available',
        ListingStatus.sold => 'Sold',
        ListingStatus.cancelled => 'Removed',
        _ => status,
      };

  String get quantityLabel => '${formatNumber(quantity)} $unit';

  String get locationText => [municipality, district, stateProvince]
      .whereType<String>()
      .where((s) => s.trim().isNotEmpty)
      .join(', ');

  String? get _availableFromDate =>
      availableFrom?.toIso8601String().substring(0, 10);

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
        ...toUpdate(),
      };

  /// Only the columns a seller edits; status and visibility are changed elsewhere.
  Map<String, dynamic> toUpdate() => {
        'title': title,
        'description': description,
        'unit': unit,
        'quantity': quantity,
        'price': price,
        'currency': currency,
        'state_province': stateProvince,
        'district': district,
        'municipality': municipality,
        'available_from': _availableFromDate,
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

  String get statusLabel => switch (status) {
        EnquiryStatus.received => 'New',
        EnquiryStatus.contacted => 'Contacted',
        EnquiryStatus.closed => 'Closed',
        _ => status,
      };

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
