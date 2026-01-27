import 'package:flutter/foundation.dart'; // Fügt kDebugMode und KisWeb hinzu
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Extension zur Großschreibung von Strings
extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}

// --- Backend Provider ---
class HomeProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  // Statistiken
  int questionsThisWeek = 0;
  int currentStreak = 0;
  int submodulesCompleted = 0;
  int submodulesTotal = 0;

  bool isLoading = false; // Ladezustand
  String? error; // Fehlernachricht
  // Konstruktor lädt direkt die Home-Daten
  HomeProvider() {
    fetchCompletedModules();
    fetchQuestionsCount();
    fetchTotalSubmodules();
  }

  Future<void> fetchCompletedModules() async {
    isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      debugPrint('fetchCompletedModules: querying supabase modules table...');
      final res = await _supabase
          .from('learning_sessions')
          .select('submodules_id')
          .eq('user_id', user.id)
          .neq('iscompleted', false);

      print('completed: $res');
      submodulesCompleted = res
          .map((e) => e['submodules_id'])
          .whereType<int>()
          .toSet()
          .toList()
          .length;
    } catch (e) {
      error = 'Konnte Module nicht laden: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTotalSubmodules() async {
    isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      List<dynamic> modules;
      List<dynamic> imported_modules;
      List<dynamic> deleted_modules;
      debugPrint('fetchCompletedModules: querying supabase modules table...');
      // imported Modules holen
      final res1 =
          await _supabase
                  .from('imported_modules')
                  .select('module_id')
                  .eq('user_id', user.id)
              as List<dynamic>;
      print('completed1: $res1');
      imported_modules = res1;

      final List<int> imported_modules_ids = imported_modules
          .map((e) => e['module_id'] as int)
          .toList();
      print('completed13: $imported_modules_ids');
      // deleted Modules holen
      final res2 =
          await _supabase
                  .from('deleted_modules')
                  .select('module_id')
                  .eq('user_id', user.id)
              as List<dynamic>;
      print('completed2: $res2');
      deleted_modules = res2;
      final List<int> deleted_modules_ids;
      if (deleted_modules.isNotEmpty) {
        deleted_modules_ids = deleted_modules
            .map((e) => e['module_id'] as int)
            .toList();
      } else {
        deleted_modules_ids = [];
      }
      // default Modules holen
      final res3 =
          await _supabase.from('modules').select('id').eq('default', true)
              as List<dynamic>;
      print('completed3: $res3');
      modules = res3;
      final List<int> modules_ids = modules.map((e) => e['id'] as int).toList();
      // submodules for Current user
      final List<int> final_modules_ids = (modules_ids + imported_modules_ids)
          .toSet()
          .toList();

      print('Completed11: $deleted_modules_ids :$final_modules_ids');

      if (deleted_modules.isNotEmpty) {
        final res = await _supabase
            .from('submodules')
            .select('id')
            .filter('modules_id', 'in', final_modules_ids)
            .count(CountOption.exact);
        print('completed4: $res');
        submodulesTotal = res.count;
      } else {
        final res = await _supabase
            .from('submodules')
            .select('id')
            .not('modules_id', 'in', deleted_modules_ids)
            .filter('modules_id', 'in', final_modules_ids)
            .count(CountOption.exact);
        print('completed4: $res');
        submodulesTotal = res.count;
      }
    } catch (e) {
      error = 'Konnte Module nicht laden: $e';
      print('Konnte Submodules: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchQuestionsCount() async {
    isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      debugPrint('fetchQuestionsCount: querying supabase modules table...');
      final now = DateTime.now();

      // Montag = 1, Sonntag = 7
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day - (now.weekday - 1),
      );

      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      final res =
          await _supabase
                  .from('learning_sessions')
                  .select('total_questions')
                  .eq('user_id', user.id)
                  .gte('created_at', startOfWeek.toIso8601String())
                  .lt('created_at', endOfWeek.toIso8601String())
              as List<dynamic>;

      questionsThisWeek = res
          .map((e) => e['total_questions'] as int)
          .fold(0, (a, b) => a + b);
      debugPrint('TESTAT: $questionsThisWeek');

      final res1 =
          await _supabase
                  .from('learning_sessions')
                  .select('total_questions')
                  .eq('user_id', user.id)
              as List<dynamic>;
      currentStreak = res1.length;
    } catch (e) {
      error = 'Konnte Module nicht laden: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
