import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lernen_module.dart';

class BackendProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool isLoading = false;
  String? error;

  // Startseite Daten
  List<LernenModule> lastModules = [];
  int questionsThisWeek = 0;
  int modulesCompleted = 0;
  int currentStreak = 0;
  List<Map<String, dynamic>> achievements = [];

  Future<void> fetchHomeData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Letzte Session
      final sessions = await _supabase
          .from('learning_sessions')
          .select()
          .order('created_at', ascending: false)
          .limit(1) as List<dynamic>;

      Map<String, dynamic>? lastSession;
      if (sessions.isNotEmpty) {
        lastSession = sessions.first as Map<String, dynamic>;
      }

      // Letzte 3 Module
      final modules = await _supabase
          .from('modules')
          .select('*')
          .limit(3) as List<dynamic>;

      lastModules =
          modules.map((e) => LernenModule.fromJson(e as Map<String, dynamic>)).toList();

      // Statistik Beispielwerte
      questionsThisWeek = lastSession?['total_questions'] ?? 0;
      modulesCompleted = 5; // ggf. berechnen
      currentStreak = 7;    // ggf. berechnen

      // Achievements
      achievements = [
        {'title': 'First Step', 'earned': true},
        {'title': 'Quiz Master', 'earned': false},
      ];

    } catch (e) {
      error = 'Konnte Home-Daten nicht laden: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchModules() async {
    try {
      final modules = await _supabase.from('modules').select('*') as List<dynamic>;
      lastModules =
          modules.map((e) => LernenModule.fromJson(e as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (e) {
      error = 'Konnte Module nicht laden: $e';
      notifyListeners();
    }
  }
}
