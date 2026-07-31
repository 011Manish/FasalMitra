import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crop_price_point.dart';
import '../models/price_trend.dart';

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
}
