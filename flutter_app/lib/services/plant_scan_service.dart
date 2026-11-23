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

/// A short plain message for the user. Never shows raw error text.
String plantScanErrorMessage(Object error) {
  if (error is PlantScanFailed) {
    switch (error.reason) {
      case 'no_api_key':
        return 'No API key added yet.';
      case 'ai_key_rejected':
        return 'The API key is not valid. Add a working key.';
    }
  }
  return 'Could not complete this request. Check your internet and try again.';
}

class PlantScanService {
  PlantScanService(this._sb);
  final SupabaseClient _sb;

  String get _uid => _sb.auth.currentUser!.id;

  Future<String> uploadScanPhoto({String? farmId, required File file}) async {
    final ext = _extensionFor(file.path);
    final filename = '${DateTime.now().toUtc().millisecondsSinceEpoch}-'
        '${_shortId()}$ext';
    final folder = farmId == null ? _uid : '$_uid/$farmId';
    final path = '$folder/plant-scans/$filename';

    await _sb.storage.from(_bucket).upload(
          path,
          file,
          fileOptions:
              FileOptions(contentType: _contentTypeFor(ext), upsert: false),
        );
    return path;
  }

  Future<PlantScan> analyze(
      {String? farmId, required String storagePath}) async {
    final data = await _invoke('analyze-plant-photo', {
      if (farmId != null) 'farm_id': farmId,
      'storage_path': storagePath,
    });
    return PlantScan.fromMap(data as Map<String, dynamic>);
  }

  Future<String> askFollowUp(
      {required String scanId, required String question}) async {
    final data = await _invoke('plant-scan-followup', {
      'scan_id': scanId,
      'question': question,
    });
    return (data as Map<String, dynamic>)['answer']?.toString() ?? '';
  }

  Future<List<PlantScan>> listMine() async {
    final rows = await _sb
        .from('plant_health_scans')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => PlantScan.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<dynamic> _invoke(String function, Map<String, dynamic> body) async {
    try {
      final res = await _sb.functions.invoke(function, body: body);
      return res.data;
    } on FunctionException catch (e) {
      final details = e.details;
      throw PlantScanFailed(details is Map
          ? (details['error']?.toString() ?? 'unknown_error')
          : 'unknown_error');
    }
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
