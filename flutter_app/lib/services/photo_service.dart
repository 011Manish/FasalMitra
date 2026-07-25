import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/farm_photo.dart';

const maxPhotoBytes = 5 * 1024 * 1024;
const _bucket = 'farm-media';

class PhotoTooLarge implements Exception {
  const PhotoTooLarge(this.bytes);
  final int bytes;
  @override
  String toString() =>
      'Photo is ${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB; max is 5 MB.';
}

class PhotoService {
  PhotoService(this._sb);
  final SupabaseClient _sb;

  String get _uid => _sb.auth.currentUser!.id;

  Future<FarmPhoto> upload({required String farmId, required File file}) async {
    final size = await file.length();
    if (size > maxPhotoBytes) throw PhotoTooLarge(size);

    final ext = _extensionFor(file.path);
    final filename = '${DateTime.now().toUtc().millisecondsSinceEpoch}-'
        '${_shortId()}$ext';
    final path = '$_uid/$farmId/$filename';

    await _sb.storage.from(_bucket).upload(
          path,
          file,
          fileOptions: FileOptions(contentType: _contentTypeFor(ext), upsert: false),
        );

    try {
      final row = await _sb.from('farm_photos').insert({
        'user_id': _uid,
        'farm_id': farmId,
        'storage_path': path,
        'taken_at': DateTime.now().toUtc().toIso8601String(),
      }).select().single();
      return FarmPhoto.fromMap(row);
    } catch (e) {
      // DB insert failed after the object was uploaded — remove the orphan so
      // we don't leave storage littered with rows that no table references.
      await _sb.storage.from(_bucket).remove([path]);
      rethrow;
    }
  }

  Future<List<FarmPhoto>> listForFarm(String farmId) async {
    final rows = await _sb
        .from('farm_photos')
        .select()
        .eq('farm_id', farmId)
        .order('taken_at', ascending: false);
    return (rows as List)
        .map((r) => FarmPhoto.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<String> signedUrl(String storagePath, {int expiresInSeconds = 3600}) {
    return _sb.storage.from(_bucket).createSignedUrl(storagePath, expiresInSeconds);
  }

  Future<void> delete(FarmPhoto photo) async {
    await _sb.from('farm_photos').delete().eq('id', photo.id);
    await _sb.storage.from(_bucket).remove([photo.storagePath]);
  }

  String _extensionFor(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    return const ['.jpg', '.jpeg', '.png', '.heic', '.webp'].contains(ext) ? ext : '.jpg';
  }

  String _contentTypeFor(String ext) {
    switch (ext) {
      case '.png': return 'image/png';
      case '.heic': return 'image/heic';
      case '.webp': return 'image/webp';
      default: return 'image/jpeg';
    }
  }

  String _shortId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return now.toRadixString(36);
  }
}
