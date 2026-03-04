import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class AuthRepository {
  static Future<bool> loginWithDiscord() async {
    try {
      final res = await SupabaseClientManager.client.auth.signInWithOAuth(
        OAuthProvider.discord,
      );
      return res.session != null;
    } catch (e) {
      print('Discord Login Fehler: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    await SupabaseClientManager.client.auth.signOut();
  }

  static Session? currentSession() {
    return SupabaseClientManager.client.auth.currentSession;
  }
}
