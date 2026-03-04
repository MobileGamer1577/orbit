import 'package:flutter/material.dart';
import '../core/supabase_client.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await SupabaseClientManager.client.auth.signOut();
        // Danach App neu starten oder Login Flow zeigen
      },
      child: const Text('Logout'),
    );
  }
}
