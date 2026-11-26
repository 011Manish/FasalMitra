import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/catalog_product.dart';

class CatalogService {
  final _client = Supabase.instance.client;

  Future<List<CatalogProduct>> fetchProducts({String? category}) async {
    var query = _client.from('catalog_products').select().eq('is_active', true);
    if (category != null) {
      query = query.eq('category', category);
    }
    final rows = await query.order('name');
    return (rows as List)
        .map((r) => CatalogProduct.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendEnquiry({
    required String productId,
    required String message,
    String? phone,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Please log in first');
    await _client.from('catalog_enquiries').insert({
      'product_id': productId,
      'user_id': user.id,
      'message': message,
      'contact_phone': phone,
    });
  }
}
