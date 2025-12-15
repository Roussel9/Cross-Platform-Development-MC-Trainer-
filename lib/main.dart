import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'provider/backend_provider.dart';
import 'core/theme/app_theme.dart';

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

  await Supabase.initialize(
    url: 'https://pkcnrzeqsopfxhgorfbj.supabase.co',
    anonKey: 'sb_publishable_ngVhTfl8fNBjt0qV3R3SCA_AK9bbSX0',
  );

  _testConnectionInBackground();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BackendProvider()..fetchModules(),
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

      /// 👉 Startseite abhängig vom Login
      initialRoute: user == null ? '/login' : '/home',

      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
