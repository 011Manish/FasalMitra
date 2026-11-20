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
    return (rows as List).map((r) => FarmProfile.fromMap(r as Map<String, dynamic>)).toList();
  }

  Future<FarmProfile> create(FarmProfile farm) async {
    final row = await _sb
        .from('farm_profiles')
        .insert(farm.toInsert(_uid))
        .select()
        .single();
    final created = FarmProfile.fromMap(row);
    await _regenerateSchedule(created.id);
    return created;
  }

  Future<FarmProfile> update(String id, Map<String, dynamic> patch) async {
    final row = await _sb.from('farm_profiles').update(patch).eq('id', id).select().single();
    final updated = FarmProfile.fromMap(row);
    await _regenerateSchedule(updated.id);
    return updated;
  }

  Future<void> delete(String id) async {
    await _sb.from('farm_profiles').delete().eq('id', id);
  }

  Future<List<ScheduleItem>> reminders() async {
    final today = DateTime.now().toUtc();
    final todayStr = today.toIso8601String().substring(0, 10);

    final rows = await _sb
        .from('schedule_items')
        .select()
        .eq('status', 'pending')
        .lte('due_date', todayStr)
        .order('due_date', ascending: true);

    return (rows as List).map((r) => ScheduleItem.fromMap(r as Map<String, dynamic>)).toList();
  }

  Future<void> markScheduleItem(String id, String status) async {
    await _sb.from('schedule_items').update({
      'status': status,
      'completed_at': status == 'done' ? DateTime.now().toIso8601String() : null,
    }).eq('id', id);
  }

  Future<void> deleteAccount() async {
    await _sb.rpc('delete_current_user');
    await _sb.auth.signOut();
  }

  Future<void> _regenerateSchedule(String farmId) async {
    await _sb.functions.invoke('generate-schedule', body: {'farm_id': farmId});
  }
}
