import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/consultation_appointment.dart';
import '../models/consultation_message.dart';
import '../models/expert.dart';
import 'photo_service.dart';

const _bucket = 'farm-media';

class ConsultationService {
  ConsultationService(this._sb);
  final SupabaseClient _sb;

  String get _uid => _sb.auth.currentUser!.id;

  Future<List<Expert>> listExperts() async {
    final rows =
        await _sb.from('experts').select().order('name', ascending: true);
    return (rows as List)
        .map((r) => Expert.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<ConsultationAppointment>> listMyAppointments() async {
    final rows = await _sb
        .from('consultation_appointments')
        .select()
        .order('requested_at', ascending: false);
    return (rows as List)
        .map((r) => ConsultationAppointment.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<ConsultationAppointment> requestAppointment({
    required String expertId,
    String? farmId,
  }) async {
    final row = await _sb
        .from('consultation_appointments')
        .insert({
          'user_id': _uid,
          'expert_id': expertId,
          'farm_id': farmId,
          'status': 'pending',
        })
        .select()
        .single();
    return ConsultationAppointment.fromMap(row);
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _sb
        .from('consultation_appointments')
        .update({'status': 'cancelled'}).eq('id', appointmentId);
  }

  Future<List<ConsultationMessage>> listMessages(String appointmentId) async {
    final rows = await _sb
        .from('consultation_messages')
        .select()
        .eq('appointment_id', appointmentId)
        .order('created_at', ascending: true);
    return (rows as List)
        .map((r) => ConsultationMessage.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<ConsultationMessage> sendMessage({
    required String appointmentId,
    required String body,
  }) async {
    final row = await _sb
        .from('consultation_messages')
        .insert({
          'appointment_id': appointmentId,
          'sender_id': _uid,
          'body': body,
        })
        .select()
        .single();
    return ConsultationMessage.fromMap(row);
  }

  Future<String> uploadDocument({
    required String appointmentId,
    required File file,
  }) async {
    final size = await file.length();
    if (size > maxPhotoBytes) throw PhotoTooLarge(size);

    final ext = _extensionFor(file.path);
    final filename = '${DateTime.now().toUtc().millisecondsSinceEpoch}-'
        '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}$ext';
    final path = '$_uid/consultations/$appointmentId/$filename';

    await _sb.storage.from(_bucket).upload(
          path,
          file,
          fileOptions:
              FileOptions(contentType: _contentTypeFor(ext), upsert: false),
        );

    try {
      await sendMessage(
        appointmentId: appointmentId,
        body: '[document] $filename',
      );
    } catch (e) {
      await _sb.storage.from(_bucket).remove([path]);
      rethrow;
    }
    return path;
  }

  Future<String> signedUrl(String storagePath, {int expiresInSeconds = 3600}) {
    return _sb.storage
        .from(_bucket)
        .createSignedUrl(storagePath, expiresInSeconds);
  }

  String _extensionFor(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1) return '';
    return path.substring(dot).toLowerCase();
  }

  String _contentTypeFor(String ext) {
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
