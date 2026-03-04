import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';

class SupabaseClientManager {
  static final SupabaseClient client = SupabaseClient(
    SUPABASE_URL,
    SUPABASE_ANON_KEY,
  );

  static Future<void> init() async {
    await Supabase.initialize(url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY);
  }
}
