import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/marketplace_listing.dart';
import 'photo_service.dart' show maxPhotoBytes, PhotoTooLarge;

const _listingBucket = 'listing-media';
const _genericError =
    'Could not complete this request. Check your internet and try again.';
const _offlineError = 'No internet connection. Check it and try again.';
const _deniedError = 'You are not allowed to do that.';
const _postgresRaiseCode = 'P0001';
const _postgresPermissionCode = '42501';

const farmerOnlyMessage =
    'Only farmer accounts can post listings. Change your role in Profile.';

class UnsupportedPhotoType implements Exception {
  const UnsupportedPhotoType();

  @override
  String toString() => 'Use a JPG, PNG or WebP photo.';
}

/// Turns an expected failure into one short sentence for the user.
/// Messages raised by our own database triggers are already plain words.
String marketplaceErrorMessage(
  Object error, {
  String fallback = _genericError,
  String denied = _deniedError,
}) {
  if (error is PhotoTooLarge || error is UnsupportedPhotoType) {
    return error.toString();
  }
  if (error is PostgrestException) {
    if (error.code == _postgresRaiseCode) return error.message;
    if (error.code == _postgresPermissionCode) return denied;
  }
  if (error is StorageException && error.statusCode?.toString() == '413') {
    return 'The photo is too large. The limit is 5 MB.';
  }
  if (error is SocketException) return _offlineError;
  return fallback;
}

class MarketplaceService {
  MarketplaceService(this._sb);
  final SupabaseClient _sb;

  String get _uid => _sb.auth.currentUser!.id;

  String get currentUserId => _uid;

  /// 'farmer', 'buyer' or 'admin' (null if the profile can't be read).
  Future<String?> myRole() async {
    final row =
        await _sb.from('profiles').select('role').eq('id', _uid).maybeSingle();
    return row?['role'] as String?;
  }

  /// Active, visible listings from other sellers, newest first.
  /// [search] matches the crop name; [district] filters by district.
  Future<List<MarketplaceListing>> browse({
    String? search,
    String? district,
  }) async {
    var query = _sb
        .from('marketplace_listings')
        .select()
        .eq('status', ListingStatus.active)
        .eq('is_hidden', false)
        .neq('seller_id', _uid);
    final q = _cleanSearch(search);
    if (q.isNotEmpty) query = query.ilike('title', '%$q%');
    final d = _cleanSearch(district);
    if (d.isNotEmpty) query = query.ilike('district', '%$d%');
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

  Future<MarketplaceListing> update(MarketplaceListing listing) async {
    final row = await _sb
        .from('marketplace_listings')
        .update(listing.toUpdate())
        .eq('id', listing.id)
        .select()
        .single();
    return MarketplaceListing.fromMap(row);
  }

  Future<void> setStatus(String listingId, String status) async {
    await _sb
        .from('marketplace_listings')
        .update({'status': status})
        .eq('id', listingId)
        .select('id')
        .single();
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
    final ext = photoExtension(file.path);
    if (ext == null) throw const UnsupportedPhotoType();
    final size = await file.length();
    if (size > maxPhotoBytes) throw PhotoTooLarge(size);

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
    } catch (_) {
      await _sb.storage.from(_listingBucket).remove([path]);
      rethrow;
    }
  }

  Future<String> signedUrl(String storagePath, {int expiresInSeconds = 3600}) {
    return _sb.storage
        .from(_listingBucket)
        .createSignedUrl(storagePath, expiresInSeconds);
  }

  /// First photo of each listing, as a signed URL keyed by listing id.
  /// A listing whose photo cannot be signed is left out and shows the fallback icon.
  Future<Map<String, String>> thumbnailUrls(List<String> listingIds) async {
    if (listingIds.isEmpty) return {};
    final rows = await _sb
        .from('listing_photos')
        .select('listing_id, storage_path')
        .inFilter('listing_id', listingIds)
        .order('created_at', ascending: true);
    final firstPath = <String, String>{};
    for (final r in rows as List) {
      final row = r as Map<String, dynamic>;
      firstPath.putIfAbsent(
          row['listing_id'] as String, () => row['storage_path'] as String);
    }
    final signed = await Future.wait<MapEntry<String, String>?>(
      firstPath.entries.map((e) async {
        try {
          return MapEntry(e.key, await signedUrl(e.value));
        } on StorageException {
          return null;
        }
      }),
    );
    return {
      for (final e in signed.whereType<MapEntry<String, String>>())
        e.key: e.value,
    };
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

  Future<void> setEnquiryStatus(String enquiryId, String status) async {
    await _sb
        .from('listing_enquiries')
        .update({'status': status})
        .eq('id', enquiryId)
        .select('id')
        .single();
  }

  // Helpers ---------------------------------------------------------

  String _cleanSearch(String? raw) =>
      (raw ?? '').replaceAll(RegExp(r'[,()%*\\]'), ' ').trim();

  String _contentTypeFor(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
