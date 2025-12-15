import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // REGISTRIERUNG
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
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
          'full_name': '$firstName $lastName',
        },
        
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
         await signIn(email: email, password: password);
      }
      
      return response;
    } catch (e) {
      print('SignUp Error: $e');
      rethrow;
    }
  }
  
  // LOGIN
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('SignIn Error: $e');
      rethrow;
    }
  }
  
  // LOGOUT
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  // AKTUELLER USER
  User? get currentUser => _supabase.auth.currentUser;
  
  // AUTH STATE ÄNDERUNGEN
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  // USER PROFIL TABELLE ERSTELLEN 
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
      print('Error creating user profile: $e');
    }
  }
  
  // PASSWORT ZURÜCKSETZEN
  Future<void> resetPassword(String email) async {
    // Für Flutter Web: redirectTo muss auf die URL deiner Web-App zeigen
     final redirectUrl = kIsWeb
      ? 'https://mc-trainer-kami-k00che7pl-danielle-noelle-kami-tenis-projects.vercel.app/reset-password'
      : 'mc-trainer-kami://reset-password';
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectUrl,
    );
  }
}
