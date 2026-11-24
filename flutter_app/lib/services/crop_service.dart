import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crop_info.dart';

const cropLoadError =
    'Could not load crops. Check your internet and try again.';

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
}
