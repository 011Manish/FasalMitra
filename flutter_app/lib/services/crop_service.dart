import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crop_info.dart';

class CropService {
  CropService(this._sb);
  final SupabaseClient _sb;

  Future<List<CropInfo>> listCrops() async {
    final rows =
        await _sb.from('crops').select().eq('is_active', true).order('name');
    return (rows as List)
        .map((r) => CropInfo.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Simple rule-based matching. Season must match (2 points), then soil
  /// match (2 points) and water fit (1 point). Only crops scoring 3 or
  /// more are returned, best first. General guidance only.
  static List<CropSuggestion> suggest(
    List<CropInfo> crops, {
    required String season,
    required String soil,
    required bool irrigated,
  }) {
    final results = <CropSuggestion>[];
    for (final c in crops) {
      if (!c.seasons.contains(season)) continue;

      var score = 2;
      final reasons = <String>['Suits the $season season'];

      if (c.suitableSoils.contains(soil)) {
        score += 2;
        reasons.add('Grows well in $soil soil');
      } else {
        reasons.add('$soil soil is not ideal');
      }

      if (irrigated || c.waterNeed != 'high') {
        score += 1;
        reasons.add(c.waterNeed == 'low'
            ? 'Needs little water'
            : 'Water need is manageable');
      } else {
        reasons.add('Needs plenty of water');
      }

      if (score >= 3) {
        results.add(CropSuggestion(crop: c, score: score, reasons: reasons));
      }
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}
