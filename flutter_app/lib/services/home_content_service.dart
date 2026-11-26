import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/catalog_product.dart';
import '../models/learning_content.dart';
import 'learning_service.dart';
import 'profile_service.dart';

const featuredLanguageOrder = ['ne', 'hi', 'en'];

/// The first word of [fullName], or null when it is empty or blank.
String? firstNameOf(String? fullName) {
  final first = (fullName ?? '').trim().split(RegExp(r'\s+')).first;
  return first.isEmpty ? null : first;
}

/// Picks the featured video from [items], which must be newest first:
/// LearningContent carries no timestamp, so list order is the only date.
/// Prefers Nepali, then Hindi, then English; any other video comes last.
LearningContent? pickFeaturedVideo(List<LearningContent> items) {
  final videos = items.where((i) => i.contentType == videoContentType).toList();
  for (final language in featuredLanguageOrder) {
    final match = videos.where((v) => v.language == language).firstOrNull;
    if (match != null) return match;
  }
  return videos.firstOrNull;
}

class HomeContentService {
  HomeContentService(SupabaseClient sb)
      : _sb = sb,
        _learning = LearningService(sb),
        _profile = ProfileService(sb);

  final SupabaseClient _sb;
  final LearningService _learning;
  final ProfileService _profile;

  Future<String?> firstName() async =>
      firstNameOf((await _profile.fetch()).fullName);

  Future<LearningContent?> featuredVideo() async => pickFeaturedVideo(
        await _learning.listContent(contentType: videoContentType),
      );

  Future<CatalogProduct?> featuredProduct() async {
    final rows = await _sb
        .from('catalog_products')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(1);
    final list = rows as List;
    return list.isEmpty
        ? null
        : CatalogProduct.fromMap(list.first as Map<String, dynamic>);
  }
}
