import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'core/theme/app_theme.dart';

void _testConnectionInBackground() async {
  try {
    final supabase = Supabase.instance.client;
    await supabase.from('cards').select().limit(1);
    print('✅ Supabase connection successful!');
  } catch (e) {
    print('❌ Supabase connection error: $e');
    // Optional: Crashlytics/Firebase Analytics loggen
  }
}


Future<void> main() async {
// WidgetsBinding initialisieren
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase initialisieren mit Keys
  await Supabase.initialize(
    url: 'https://pkcnrzeqsopfxhgorfbj.supabase.co',
    anonKey: 'sb_publishable_ngVhTfl8fNBjt0qV3R3SCA_AK9bbSX0',
  );


  // Automatisch Verbindung testen (im Hintergrund)
  _testConnectionInBackground();

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi Choice Trainer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        // '/achievements': (context) => const AchievementsScreen(),
        // '/quiz': (context) => const QuizScreen(),
      },


    );
  }
}
