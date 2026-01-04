import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =========================
  // REGISTRIERUNG
  // =========================
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,

        // ✅ User Metadata (wird korrekt gespeichert)
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'full_name': '$firstName $lastName',
          'username': username,
        },

        // ✅ Redirect nach Bestätigung
        emailRedirectTo: kIsWeb
            ? 'http://localhost:3000'
            : 'mctrainer://login-callback',
      );

      if (response.user != null) {
        await _createUserProfile(
          userId: response.user!.id,
          email: email,
          firstName: firstName,
          lastName: lastName,
          username: username,
        );

        // Automatischer Login
        await signIn(identifier: email, password: password);
      }

      return response;
    } catch (e) {
      debugPrint('SignUp Error: $e');
      rethrow;
    }
  }

  // =========================
  // LOGIN (Email oder Username)
  // =========================
  Future<AuthResponse> signIn({
    required String identifier, // Umbenannt von email zu identifier
    required String password,
  }) async {
    try {
      String identify = identifier.trim();

      // Prüfen, ob es sich um einen Usernamen handelt (kein '@' Zeichen)
      if (!identify.contains('@')) {
        // Suche in der 'profiles' Tabelle nach der E-Mail, die zum Usernamen gehört
        // In deiner signIn Methode:
        final response = await _supabase
            .from('user_profiles')
            .select('email')
            .eq('username', identify)
            .maybeSingle();

        // Debugging:
        debugPrint('Gefundene Daten für $identify: $response');

        if (response == null) {
          throw const AuthException(
            'Username nicht gefunden oder Zugriff verweigert <(RLS).',
          );
        }

        identify = response['email'];
      }

      // Login mit der (gefundenen) E-Mail ausführen
      return await _supabase.auth.signInWithPassword(
        email: identify,
        password: password,
      );
    } on AuthException catch (e) {
      debugPrint('Auth Error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected SignIn Error: $e');
      rethrow;
    }
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // =========================
  // AKTUELLER USER
  // =========================
  User? get currentUser => _supabase.auth.currentUser;

  // =========================
  // AUTH STATE ÄNDERUNGEN
  // =========================
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // =========================
  // USER-PROFIL TABELLE
  // =========================
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    try {
      await _supabase.from('user_profiles').insert({
        'id': userId,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
  }

  // =========================
  // PASSWORT ZURÜCKSETZEN
  // =========================
  Future<void> resetPassword(String email) async {
    final redirectUrl = kIsWeb
        ? 'https://mc-trainer-kami-k00che7pl-danielle-noelle-kami-tenis-projects.vercel.app/reset-password'
        : 'mc-trainer-kami://reset-password';

    await _supabase.auth.resetPasswordForEmail(email, redirectTo: redirectUrl);
  }
}
