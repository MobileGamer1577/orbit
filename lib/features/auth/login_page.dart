import 'package:flutter/material.dart';
import '../core/supabase_client.dart';
import 'auth_repository.dart';
import '../widgets/loading_indicator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;

  void _loginWithDiscord() async {
    setState(() => _loading = true);
    final success = await AuthRepository.loginWithDiscord();
    setState(() => _loading = false);

    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login fehlgeschlagen!')));
    }
    // Wenn erfolgreich, Main App zeigt HomeScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const LoadingIndicator()
          : Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Mit Discord anmelden'),
                onPressed: _loginWithDiscord,
              ),
            ),
    );
  }
}
