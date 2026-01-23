import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:mc_trainer_kami/features/home/screens/home_screen.dart' as home_screen; // Alias
import 'package:mc_trainer_kami/provider/backend_provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<AuthState>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final authState = snapshot.data!;
          final session = authState.session;

          if (session != null) {
            // BEI JEDEM LOGIN: Provider Daten zurücksetzen und neu laden
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final provider = Provider.of<BackendProvider>(context, listen: false);
              provider.reset();
              provider.fetchHomeData();
            });

            return const home_screen.HomeScreen(); // Hier den Alias verwenden!
          } else {
            return const LoginScreen();
          }
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}