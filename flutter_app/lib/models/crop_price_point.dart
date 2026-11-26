class CropPricePoint {
  CropPricePoint({
    required this.id,
    required this.cropName,
    required this.source,
    required this.recordedDate,
    required this.avgPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.unit,
    this.marketName,
    this.isDemo = true,
  });

  final String id;
  final String cropName;
  final String source;
  final DateTime recordedDate;
  final double avgPrice;
  final double minPrice;
  final double maxPrice;
  final String unit;
  final String? marketName;

  /// Defaults to true on purpose: anything not explicitly marked real
  /// is treated as sample data.
  final bool isDemo;

  factory CropPricePoint.fromMap(Map<String, dynamic> m) => CropPricePoint(
        id: m['id'] as String,
        cropName: m['crop_name'] as String,
        source: m['source'] as String,
        recordedDate: DateTime.parse(m['recorded_date'] as String),
        avgPrice: (m['avg_price'] as num).toDouble(),
        minPrice: (m['min_price'] as num).toDouble(),
        maxPrice: (m['max_price'] as num).toDouble(),
        unit: m['unit'] as String,
        marketName: m['market_name'] as String?,
        isDemo: (m['is_demo'] as bool?) ?? true,
      );
}
