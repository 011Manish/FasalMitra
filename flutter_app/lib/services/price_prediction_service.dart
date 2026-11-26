import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crop_price_point.dart';
import '../models/price_trend.dart';

String marketLabel(CropPricePoint point) => point.marketName ?? point.source;

/// Keeps only the newest record for each crop and market, sorted by crop, then market.
List<CropPricePoint> latestPerCropAndMarket(List<CropPricePoint> points) {
  final latest = <(String, String), CropPricePoint>{};
  for (final point in points) {
    final key = (point.cropName, marketLabel(point));
    final current = latest[key];
    if (current == null || point.recordedDate.isAfter(current.recordedDate)) {
      latest[key] = point;
    }
  }
  return latest.values.toList()
    ..sort((a, b) {
      final byCrop = a.cropName.compareTo(b.cropName);
      return byCrop != 0 ? byCrop : marketLabel(a).compareTo(marketLabel(b));
    });
}

class PricePredictionService {
  PricePredictionService(this._sb);
  final SupabaseClient _sb;

  Future<List<String>> listCrops() async {
    final rows = await _sb.from('crop_price_history').select('crop_name');
    final names =
        (rows as List).map((r) => r['crop_name'] as String).toSet().toList();
    names.sort();
    return names;
  }

  Future<PriceTrend> fetchTrend(String cropName) async {
    final rows = await _sb
        .from('crop_price_history')
        .select()
        .eq('crop_name', cropName)
        .order('recorded_date', ascending: true);
    final points = (rows as List)
        .map((r) => CropPricePoint.fromMap(r as Map<String, dynamic>))
        .toList();
    return PriceTrend.fromPoints(points);
  }

  // Assumes the table has fewer than 1000 rows (the Supabase default limit).
  Future<List<CropPricePoint>> fetchLatestPrices() async {
    final rows = await _sb
        .from('crop_price_history')
        .select()
        .order('recorded_date', ascending: false);
    final points = (rows as List)
        .map((r) => CropPricePoint.fromMap(r as Map<String, dynamic>))
        .toList();
    return latestPerCropAndMarket(points);
  }
}
