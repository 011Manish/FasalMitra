import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/farm_profile.dart';

class FarmService {
  FarmService(this._sb);
  final SupabaseClient _sb;

  String get _uid => _sb.auth.currentUser!.id;

  Future<List<FarmProfile>> listMine() async {
    final rows = await _sb
        .from('farm_profiles')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => FarmProfile.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<FarmProfile> create(FarmProfile farm) async {
    final row = await _sb
        .from('farm_profiles')
        .insert(farm.toInsert(_uid))
        .select()
        .single();
    return FarmProfile.fromMap(row);
  }

  Future<FarmProfile> update(String id, Map<String, dynamic> patch) async {
    final row = await _sb
        .from('farm_profiles')
        .update(patch)
        .eq('id', id)
        .select()
        .single();
    return FarmProfile.fromMap(row);
  }

  Future<void> delete(String id) async {
    await _sb.from('farm_profiles').delete().eq('id', id);
  }

  Future<void> deleteAccount() async {
    await _sb.rpc('delete_current_user');
    await _sb.auth.signOut();
  }
}