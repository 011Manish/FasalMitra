import 'package:agrismart_ai/models/crop_price_point.dart';
import 'package:agrismart_ai/services/price_prediction_service.dart';
import 'package:flutter_test/flutter_test.dart';

CropPricePoint _point({
  required String id,
  required String crop,
  required String market,
  required DateTime date,
}) =>
    CropPricePoint(
      id: id,
      cropName: crop,
      source: 'kalimati',
      recordedDate: date,
      avgPrice: 10,
      minPrice: 8,
      maxPrice: 12,
      unit: 'per kg',
      marketName: market,
    );

void main() {
  test('keeps the most recent record for a crop and market', () {
    final older = _point(
        id: 'old', crop: 'Tomato', market: 'A', date: DateTime(2026, 7, 17));
    final newer = _point(
        id: 'new', crop: 'Tomato', market: 'A', date: DateTime(2026, 7, 24));

    final result = latestPerCropAndMarket([newer, older]);

    expect(result, hasLength(1));
    expect(result.single.id, 'new');
  });

  test('keeps different markets of the same crop separate', () {
    final a = _point(
        id: 'a', crop: 'Tomato', market: 'A', date: DateTime(2026, 7, 24));
    final b = _point(
        id: 'b', crop: 'Tomato', market: 'B', date: DateTime(2026, 7, 17));

    final result = latestPerCropAndMarket([b, a]);

    expect(result.map((p) => p.id), ['a', 'b']);
  });

  test('returns an empty list for empty input', () {
    expect(latestPerCropAndMarket([]), isEmpty);
  });
}
