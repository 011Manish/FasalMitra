import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification.dart';

class NotificationService {
  NotificationService(this._sb);
  final SupabaseClient _sb;

  String get _uid => _sb.auth.currentUser!.id;

  /// Newest first, and updates live as notifications arrive or are read.
  Stream<List<AppNotification>> watch() => _sb
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', _uid)
      .order('created_at', ascending: false)
      .map((rows) => rows.map(AppNotification.fromMap).toList());

  Stream<int> watchUnreadCount() =>
      watch().map((items) => items.where((n) => !n.isRead).length);

  Future<void> markRead(String id) async {
    await _sb.from('notifications').update({'read_at': _now()}).eq('id', id);
  }

  Future<void> markAllRead() async {
    await _sb
        .from('notifications')
        .update({'read_at': _now()})
        .eq('user_id', _uid)
        .filter('read_at', 'is', null);
  }

  Future<void> delete(String id) async {
    await _sb.from('notifications').delete().eq('id', id);
  }

  String _now() => DateTime.now().toUtc().toIso8601String();
}
