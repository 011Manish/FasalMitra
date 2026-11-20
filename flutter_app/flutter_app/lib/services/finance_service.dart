import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/farm_income_entry.dart';
import '../models/finance_info.dart';

class FinanceService {
  FinanceService(this._sb);
  final SupabaseClient _sb;

  String get _uid => _sb.auth.currentUser!.id;

  Future<List<FinanceInfo>> listFinanceInfo({String? category}) async {
    var q = _sb.from('finance_info').select();
    if (category != null) q = q.eq('category', category);
    final rows = await q.order('created_at', ascending: false);
    return (rows as List)
        .map((r) => FinanceInfo.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<FarmIncomeEntry>> listIncomeEntries(String farmId) async {
    final rows = await _sb
        .from('farm_income_entries')
        .select()
        .eq('farm_id', farmId)
        .order('entry_date', ascending: false);
    return (rows as List)
        .map((r) => FarmIncomeEntry.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<FarmIncomeEntry> addIncomeEntry({
    required String farmId,
    required String description,
    required double amount,
    required DateTime entryDate,
  }) async {
    final row = await _sb
        .from('farm_income_entries')
        .insert({
          'user_id': _uid,
          'farm_id': farmId,
          'description': description,
          'amount': amount,
          'entry_date': entryDate.toIso8601String().substring(0, 10),
        })
        .select()
        .single();
    return FarmIncomeEntry.fromMap(row);
  }

  Future<void> deleteIncomeEntry(String entryId) async {
    await _sb.from('farm_income_entries').delete().eq('id', entryId);
  }
}
