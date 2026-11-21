import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/learning_content.dart';

class LearningService {
  LearningService(this._sb);
  final SupabaseClient _sb;

  Future<List<LearningContent>> listContent({
    String? contentType,
    String? category,
    String? language,
  }) async {
    var q = _sb.from('learning_content').select();
    if (contentType != null) q = q.eq('content_type', contentType);
    if (category != null) q = q.eq('category', category);
    if (language != null) q = q.eq('language', language);
    final rows = await q.order('created_at', ascending: false);
    return (rows as List)
        .map((r) => LearningContent.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}
