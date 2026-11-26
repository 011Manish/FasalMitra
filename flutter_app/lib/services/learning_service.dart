import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/learning_content.dart';

class LearningService {
  LearningService(this._sb);
  final SupabaseClient _sb;

  static const _videoLanguageOrder = ['ne', 'en', 'hi'];

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
    final items = (rows as List)
        .map((r) => LearningContent.fromMap(r as Map<String, dynamic>))
        .toList();
    return contentType == videoContentType ? _groupByLanguage(items) : items;
  }

  /// Keeps the newest-first order inside each language group.
  List<LearningContent> _groupByLanguage(List<LearningContent> items) {
    return [
      for (final lang in _videoLanguageOrder)
        ...items.where((i) => i.language == lang),
      ...items.where((i) => !_videoLanguageOrder.contains(i.language)),
    ];
  }
}
