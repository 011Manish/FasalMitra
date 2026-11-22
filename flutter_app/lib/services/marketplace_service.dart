import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/marketplace_listing.dart';
import 'photo_service.dart' show maxPhotoBytes, PhotoTooLarge;

const _listingBucket = 'listing-media';

class MarketplaceService {
  MarketplaceService(this._sb);
  final SupabaseClient _sb;

  String get _uid => _sb.auth.currentUser!.id;

  /// 'farmer', 'buyer' or 'admin' (null if the profile can't be read).
  Future<String?> myRole() async {
    final row =
        await _sb.from('profiles').select('role').eq('id', _uid).maybeSingle();
    return row?['role'] as String?;
  }

  /// Active, visible listings from everyone, newest first.
  /// [search] matches crop name, district or municipality.
  Future<List<MarketplaceListing>> browse({String? search}) async {
    var query = _sb
        .from('marketplace_listings')
        .select()
        .eq('status', 'active')
        .eq('is_hidden', false)
        .neq('seller_id', _uid);
    final q = _cleanSearch(search);
    if (q.isNotEmpty) {
      query = query
          .or('title.ilike.%$q%,district.ilike.%$q%,municipality.ilike.%$q%');
    }
    final rows = await query.order('created_at', ascending: false);
    return (rows as List)
        .map((r) => MarketplaceListing.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<MarketplaceListing>> myListings() async {
    final rows = await _sb
        .from('marketplace_listings')
        .select()
        .eq('seller_id', _uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => MarketplaceListing.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<MarketplaceListing> create(MarketplaceListing listing) async {
    final row = await _sb
        .from('marketplace_listings')
        .insert(listing.toInsert(_uid))
        .select()
        .single();
    return MarketplaceListing.fromMap(row);
  }

  /// 'active' (available), 'sold' or 'cancelled'.
  Future<void> setStatus(String listingId, String status) async {
    await _sb
        .from('marketplace_listings')
        .update({'status': status}).eq('id', listingId);
  }

  // Photos ----------------------------------------------------------

  Future<List<ListingPhoto>> photos(String listingId) async {
    final rows = await _sb
        .from('listing_photos')
        .select()
        .eq('listing_id', listingId)
        .order('created_at', ascending: true);
    return (rows as List)
        .map((r) => ListingPhoto.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<ListingPhoto> uploadPhoto({
    required String listingId,
    required File file,
  }) async {
    final size = await file.length();
    if (size > maxPhotoBytes) throw PhotoTooLarge(size);

    final ext = _extensionFor(file.path);
    final filename = '${DateTime.now().toUtc().millisecondsSinceEpoch}-'
        '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}$ext';
    // Path convention: <seller id>/<listing id>/<file>
    final path = '$_uid/$listingId/$filename';

    await _sb.storage.from(_listingBucket).upload(
          path,
          file,
          fileOptions:
              FileOptions(contentType: _contentTypeFor(ext), upsert: false),
        );

    try {
      final row = await _sb
          .from('listing_photos')
          .insert({
            'listing_id': listingId,
            'user_id': _uid,
            'storage_path': path,
          })
          .select()
          .single();
      return ListingPhoto.fromMap(row);
    } catch (e) {
      await _sb.storage.from(_listingBucket).remove([path]);
      rethrow;
    }
  }

  Future<String> signedUrl(String storagePath, {int expiresInSeconds = 3600}) {
    return _sb.storage
        .from(_listingBucket)
        .createSignedUrl(storagePath, expiresInSeconds);
  }

  // Enquiries -------------------------------------------------------

  Future<void> sendEnquiry({
    required String listingId,
    required String message,
    String? phone,
  }) async {
    await _sb.from('listing_enquiries').insert({
      'listing_id': listingId,
      'buyer_id': _uid,
      'message': message,
      'contact_phone': phone,
    });
  }

  /// Row-level security decides what comes back: the listing's seller sees
  /// all enquiries on it, a buyer sees only their own.
  Future<List<ListingEnquiry>> enquiriesFor(String listingId) async {
    final rows = await _sb
        .from('listing_enquiries')
        .select()
        .eq('listing_id', listingId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => ListingEnquiry.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // Helpers ---------------------------------------------------------

  String _cleanSearch(String? raw) =>
      (raw ?? '').replaceAll(RegExp(r'[,()%*\\]'), ' ').trim();

  String _extensionFor(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    return const ['.jpg', '.jpeg', '.png', '.heic', '.webp'].contains(ext)
        ? ext
        : '.jpg';
  }

  String _contentTypeFor(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.heic':
        return 'image/heic';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
