import 'dart:io';
import 'package:mc_trainer_kami/models/lernen_module.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Avatar hochladen
import 'package:flutter/foundation.dart'; // Für kIsWeb

// Extension zur Großschreibung von Strings
extension StringCasingExtension on String {
  String capitalize() =>
      isEmpty ? "" : '${this[0].toUpperCase()}${substring(1)}';
}

class BackendProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // Profil-Daten
  String? avatarUrl = '';
  File? selectedImageFile; // Lokale Datei für den Upload
  String userName = '';
  String fullName = '';
  String email = '';
  String userInitials = '';

  // Statistiken
  int questionsThisWeek = 0;
  int currentStreak = 0;
  int modulesCompleted = 0;

  // Listen & Status
  List<LernenModule> lastModules = [];
  Map<String, dynamic>? lastSession;
  List<Map<String, dynamic>> achievements = [];

  bool isLoading = false;
  String? error;

  // Korrigierter Konstruktor
  BackendProvider() {
    fetchHomeData();
  }

  // Berechnung des Fortschritts
  double calculateProgress(Map<String, dynamic>? session) {
    if (session == null) return 0.0;
    final total = session['total_questions'] ?? 1;
    final correct = session['correct_answered'] ?? 0;
    return (correct / (total == 0 ? 1 : total)).clamp(0.0, 1.0);
  }

  // ... innerhalb deiner BackendProvider Klasse ...

  Future<void> uploadAvatar(dynamic fileInput) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final userId = user.id;
      final filePath = 'user_$userId/avatar.png';

      if (kIsWeb) {
        // WEB: fileInput MUSS Uint8List sein
        await _supabase.storage
            .from('avatar_profile')
            .uploadBinary(
              filePath,
              fileInput as Uint8List,
              fileOptions: const FileOptions(upsert: true),
            );
      } else {
        // MOBILE: fileInput MUSS File sein
        await _supabase.storage
            .from('avatar_profile')
            .upload(
              filePath,
              fileInput as File,
              fileOptions: const FileOptions(upsert: true),
            );
      }

      final publicUrl = _supabase.storage
          .from('avatar_profile')
          .getPublicUrl(filePath);

      await _supabase
          .from('user_profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);

      avatarUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      // selectedImageFile setzen wir nur auf Mobile für die Vorschau
      if (!kIsWeb) selectedImageFile = fileInput as File;

      error = null;
    } catch (e) {
      error = 'Upload fehlgeschlagen: $e';
      print(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Avatar-URL abrufen
  Future<void> fetchAvatarUrl() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await _supabase
          .from('user_profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (res != null && res['avatar_url'] != null) {
        avatarUrl = res['avatar_url'];
        // Nutze dies:
        avatarUrl = '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      print('Fehler beim Laden des Avatars: $e');
    }
    notifyListeners();
  }

  // --- Datei löschen ---
  Future<void> deletePicture() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final userId = user.id;
      final filePath = 'user_$userId/avatar.png';

      // 1. Datei aus dem Supabase Storage entfernen
      // Wir ignorieren Fehler hier bewusst, falls die Datei bereits gelöscht wurde
      try {
        await _supabase.storage.from('avatar_profile').remove([filePath]);
      } catch (storageError) {
        print('Storage Info: Datei existierte evtl. nicht mehr: $storageError');
      }

      // 2. Den Eintrag in der Datenbank auf null setzen
      await _supabase
          .from('user_profiles')
          .update({'avatar_url': null})
          .eq('id', userId);

      // 3. Lokale States zurücksetzen
      avatarUrl = null;
      selectedImageFile = null;
    } catch (e) {
      error = 'Fehler beim Löschen des Avatars: $e';
      print(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Home Daten laden
  Future<void> fetchHomeData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final myFullName = user.userMetadata?['full_name'] ?? '';
        final myName = user.userMetadata?['username'];

        userName = (myName != null && myName.isNotEmpty)
            ? myName
            : user.email?.split('@').first.capitalize() ?? 'User';

        fullName = myFullName;
        email = user.email ?? '';

        userInitials = fullName.isNotEmpty
            ? fullName
                  .split(' ')
                  .where((e) => e.isNotEmpty)
                  .map((e) => e[0])
                  .take(2)
                  .join()
                  .toUpperCase()
            : userName
                  .substring(0, (userName.length >= 2 ? 2 : userName.length))
                  .toUpperCase();
      }

      // Letzte Session
      final sessions = await _supabase
          .from('learning_sessions')
          .select()
          .order('created_at', ascending: false)
          .limit(1);

      if (sessions is List && sessions.isNotEmpty) {
        lastSession = sessions.first as Map<String, dynamic>;
        questionsThisWeek = lastSession?['total_questions'] ?? 0;
      }

      // Letzte Module
      final modules =
          await _supabase.from('modules').select('*').limit(3) as List<dynamic>;

      lastModules = modules
          .map((e) => LernenModule.fromJson(e as Map<String, dynamic>))
          .toList();

      // Dummy-Daten (müssen später durch echte Abfragen ersetzt werden)
      modulesCompleted = 5;
      currentStreak = 7;
      achievements = [
        {'title': 'First Step', 'earned': true},
        {'title': 'Quiz Master', 'earned': false},
      ];
    } catch (e) {
      error = 'Daten konnten nicht geladen werden.';
      print('Fehler: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Module separat laden (z.B. für Modules Screen)
  Future<void> fetchModules() async {
    isLoading = true;
    notifyListeners();

    try {
      final modules =
          await _supabase.from('modules').select('*') as List<dynamic>;

      lastModules = modules
          .map((e) => LernenModule.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      error = 'Konnte Module nicht laden: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
