import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class AuthRepository {
  /// Login via Discord OAuth
  static Future<bool> loginWithDiscord() async {
    try {
      final response = await SupabaseClientManager.client.auth.signInWithOAuth(
        OAuthProvider.discord,
      );

      return response.session != null;
    } catch (e) {
      print('Discord Login Fehler: $e');
      return false;
    }
  }

  /// Logout
  static Future<void> logout() async {
    await SupabaseClientManager.client.auth.signOut();
  }

  /// Aktuelle Session prüfen
  static Session? currentSession() {
    return SupabaseClientManager.client.auth.currentSession;
  }
}
