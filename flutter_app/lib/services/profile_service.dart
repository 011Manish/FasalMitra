import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class ProfileService {
  ProfileService(this._sb);
  final SupabaseClient _sb;

  User get _user => _sb.auth.currentUser!;

  /// Email lives in the login system, not in `profiles`, so it is read-only here.
  String? get email => _user.email;

  Future<UserProfile> fetch() async {
    final row = await _sb.from('profiles').select().eq('id', _user.id).single();
    return UserProfile.fromMap(row);
  }

  /// Throws when no row was updated, so the screen never reports a save that
  /// did not happen.
  Future<void> save(UserProfile profile) async {
    await _sb
        .from('profiles')
        .update(profile.toUpdate())
        .eq('id', _user.id)
        .select()
        .single();
  }
}
