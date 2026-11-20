import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/plant_scan.dart';

const _bucket = 'farm-media';

class PlantScanFailed implements Exception {
  const PlantScanFailed(this.reason);
  final String reason;
  @override
  String toString() => 'Plant health analysis failed: $reason';
}

class PlantScanService {
  PlantScanService(this._sb);
  final SupabaseClient _sb;

  String get _uid => _sb.auth.currentUser!.id;

  Future<String> uploadScanPhoto(
      {required String farmId, required File file}) async {
    final ext = _extensionFor(file.path);
    final filename = '${DateTime.now().toUtc().millisecondsSinceEpoch}-'
        '${_shortId()}$ext';
    final path = '$_uid/$farmId/plant-scans/$filename';

    await _sb.storage.from(_bucket).upload(
          path,
          file,
          fileOptions:
              FileOptions(contentType: _contentTypeFor(ext), upsert: false),
        );
    return path;
  }

  Future<PlantScan> analyze(
      {required String farmId, required String storagePath}) async {
    final res = await _sb.functions.invoke('analyze-plant-photo', body: {
      'farm_id': farmId,
      'storage_path': storagePath,
    });

    if (res.status != 200) {
      final data = res.data;
      final reason = data is Map
          ? (data['error']?.toString() ?? 'unknown_error')
          : 'unknown_error';
      throw PlantScanFailed(reason);
    }
    return PlantScan.fromMap(res.data as Map<String, dynamic>);
  }

  Future<List<PlantScan>> listForFarm(String farmId) async {
    final rows = await _sb
        .from('plant_health_scans')
        .select()
        .eq('farm_id', farmId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => PlantScan.fromMap(r as Map<String, dynamic>))
        .toList();
  }

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

  String _shortId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return now.toRadixString(36);
  }
}
