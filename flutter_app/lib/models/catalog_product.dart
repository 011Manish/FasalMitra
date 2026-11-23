class CatalogProduct {
  final String id;
  final String category;
  final String name;
  final String? nameNe;
  final String? description;
  final String? imageUrl;
  final double? indicativePrice;
  final String currency;
  final String? unit;
  final String? sellerName;
  final String? sellerPhone;
  final String? sellerAddress;
  final String availability;
  final bool isDemo;

  CatalogProduct({
    required this.id,
    required this.category,
    required this.name,
    this.nameNe,
    this.description,
    this.imageUrl,
    this.indicativePrice,
    required this.currency,
    this.unit,
    this.sellerName,
    this.sellerPhone,
    this.sellerAddress,
    required this.availability,
    required this.isDemo,
  });

  factory CatalogProduct.fromMap(Map<String, dynamic> m) => CatalogProduct(
        id: m['id'] as String,
        category: m['category'] as String,
        name: m['name'] as String,
        nameNe: m['name_ne'] as String?,
        description: m['description'] as String?,
        imageUrl: m['image_url'] as String?,
        indicativePrice: (m['indicative_price'] as num?)?.toDouble(),
        currency: (m['currency'] as String?) ?? 'NPR',
        unit: m['unit'] as String?,
        sellerName: m['seller_name'] as String?,
        sellerPhone: m['seller_phone'] as String?,
        sellerAddress: m['seller_address'] as String?,
        availability: (m['availability'] as String?) ?? 'in_stock',
        isDemo: (m['is_demo'] as bool?) ?? false,
      );
}

/// Order matters: this is the order of the filter chips.
const catalogCategoryLabels = <String, String>{
  'seed': 'Seeds',
  'fertilizer': 'Fertilizers',
  'tool': 'Tools',
  'irrigation': 'Irrigation',
};

const catalogAvailabilityLabels = <String, String>{
  'in_stock': 'In stock',
  'limited': 'Limited',
  'out_of_stock': 'Out of stock',
};
