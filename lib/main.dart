import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/auth/screens/auth_wrapper.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/services/auth_service.dart';
import 'provider/backend_provider.dart' hide HomeScreen;
import 'features/modules/screens/import_modules_screen.dart';

// --- Supabase Verbindung im Hintergrund testen ---
void _testConnectionInBackground() async {
  try {
    final supabase = Supabase.instance.client;
    await supabase.from('modules').select('id').limit(1);
    debugPrint('✅ Supabase connection successful!');
  } catch (e) {
    debugPrint('❌ Supabase connection error: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase initialisieren
  await Supabase.initialize(
    url: 'https://pkcnrzeqsopfxhgorfbj.supabase.co',
    anonKey: 'sb_publishable_ngVhTfl8fNBjt0qV3R3SCA_AK9bbSX0',
  );

  // Verbindung testen
  _testConnectionInBackground();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BackendProvider()..fetchModules(),
        ),
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return MaterialApp(
      title: 'Multi Choice Trainer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: user == null ? '/login' : '/home',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        //'/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/import-modules': (context) => const ImportModulesScreen(),
        // '/achievements': (context) => const AchievementsScreen(),
        // '/quiz': (context) => const QuizScreen(),
      },
    );
  }
}
