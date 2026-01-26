import 'dart:io';
import 'package:flutter/foundation.dart'; // Fügt kDebugMode hinzu
import 'package:flutter/material.dart';
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/core/constants/app_strings.dart';
import 'package:mc_trainer_kami/features/home/widgets/category_card.dart';
import 'package:mc_trainer_kami/features/home/widgets/quiz_card.dart';
import 'package:mc_trainer_kami/models/lernen_module.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Avatar hochladen
import 'package:flutter/foundation.dart'; // Für kIsWeb
import 'package:mc_trainer_kami/models/achievement_data.dart';
import 'dart:async';

// Extension zur Großschreibung von Strings
extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}

class AppNotification {
  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.title,
    required this.message,
    DateTime? createdAt,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now();
}

// --- Backend Provider ---
class BackendProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  StreamSubscription<dynamic>? _authSub;

  String userName = ''; // Vollständiger Name des Benutzers
  String userInitials = ''; // Initialen für Avatar
  String? avatarUrl = '';
  File? selectedImageFile; // Lokale Datei für den Upload
  String fullName = '';
  String email = '';
  int achievedPoint = 1;

  // Statistiken
  int questionsThisWeek = 0;
  int currentStreak = 0;
  int modulesCompleted = 0;

  // Listen & Status
  List<LernenModule> allModules = []; // pour Modules page
  List<LernenModule> lastModule = []; // pour Home page
  Map<String, dynamic>? lastSession;
  List<Achievement> myAchievements = [];
  List<AppNotification> notifications = [];
  // NEU: Profil Daten
  String profileName = '';
  String profileEmail = '';
  String profileUsername = '';
  String? profileAvatarUrl;
  String profileCreatedAt = ''; // Mitglied seit Datum
  // NEU: Profil Statistiken
  int learnedHours = 0;
  double averageScore = 0.0;
  int totalQuestions = 0;

  bool isLoading = false; // Ladezustand
  String? error; // Fehlernachricht

  int get unreadNotificationsCount =>
      notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final rows = await _supabase
          .from('user_notifications')
          .select('title,message,created_at,is_read')
          .eq('user_id', user.id)
          .order('created_at', ascending: false) as List<dynamic>;

      notifications = rows.map((row) {
        final data = row as Map<String, dynamic>;
        return AppNotification(
          title: data['title']?.toString() ?? '',
          message: data['message']?.toString() ?? '',
          createdAt: DateTime.tryParse(data['created_at']?.toString() ?? ''),
          isRead: data['is_read'] == true,
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('fetchNotifications error: $e');
    }
  }

  Future<void> addNotification(String title, String message) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('user_notifications').insert({
        'user_id': user.id,
        'title': title,
        'message': message,
        'is_read': false,
        'created_at': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      });

      await fetchNotifications();
    } catch (e) {
      debugPrint('addNotification error: $e');
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('user_notifications')
          .update({'is_read': true})
          .eq('user_id', user.id);

      for (final n in notifications) {
        n.isRead = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('markAllNotificationsRead error: $e');
    }
  }

  // Icons und Farben für Achievements
  List<IconData> achievementsIcon = [
    Icons.bolt,
    Icons.calendar_today,
    Icons.star,
    Icons.auto_awesome,
    Icons.wb_sunny,
  ];
  List<Color> achievementsColor = [
    Colors.amber,
    Colors.blue,
    Colors.purple,
    Colors.green,
    Colors.orange,
  ];
  // Konstruktor lädt direkt die Home-Daten
  BackendProvider() {
    // Lade initiale Home-Daten (falls möglich)
    fetchHomeData();
    fetchNotifications();

    // Beobachte Auth-Status; beim Login/Logout  Module nachladen
    try {
      _authSub = _supabase.auth.onAuthStateChange.listen((data) {
        debugPrint('Auth state changed: $data');
        // Nach Auth-Änderung Module neu laden
        fetchModules();
        fetchNotifications();
      });
    } catch (e) {
      // manche Supabase-Versionen haben andere Signaturen; nur debug
      debugPrint('Auth listener nicht registriert: $e');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // Berechnung des Fortschritts einer Session
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
        print('🔍 Lade Home-Daten für User: ${user.id}');

        // ✅ ERST aus user_profiles laden
        try {
          final profileResponse = await _supabase
              .from('user_profiles')
              .select('name, email, username')
              .eq('id', user.id)
              .maybeSingle();

          print('📊 Home Profil Response: $profileResponse');

          if (profileResponse != null && profileResponse['name'] != null) {
            // Verwende Daten aus user_profiles
            userName = profileResponse['name'] as String? ?? '';
            profileName = userName;
            profileEmail = profileResponse['email'] as String? ?? '';
            profileUsername = profileResponse['username'] as String? ?? '';

            print('✅ Home-Daten aus user_profiles geladen: $userName');
          } else {
            // Fallback auf Auth-Metadaten
            final fullName = user.userMetadata?['full_name'];
            userName = (fullName != null && fullName.isNotEmpty)
                ? fullName
                : user.email?.split('@').first.capitalize() ?? 'User';

            print('⚠️ Home-Daten aus Auth-Metadaten geladen: $userName');
          }
        } catch (e) {
          print('❌ Fehler beim Laden aus user_profiles: $e');
          // Fallback auf Auth-Metadaten
          final fullName = user.userMetadata?['full_name'];
          userName = (fullName != null && fullName.isNotEmpty)
              ? fullName
              : user.email?.split('@').first.capitalize() ?? 'User';
        }

        fullName = myFullName;
        email = user.email ?? '@user';

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

      // --- Letzte Session abrufen ---
      final sessions =
          await _supabase
                  .from('learning_sessions')
                  .select()
                  .order('created_at', ascending: false)
                  .limit(1)
              as List<dynamic>;

      if (sessions.isNotEmpty) {
        lastSession = sessions.first as Map<String, dynamic>;
      }

      // NOTE: Don't load modules here to avoid overwriting the full module list.
      // Modules are loaded via `fetchModules()` to ensure the full set is available.

      // --- Statistiken setzen ---
      questionsThisWeek = lastSession?['total_questions'] ?? 0;
      // Module aus user_statistics berechnen
      //modulesCompleted = 5; // TODO: aus Datenbank berechnen
      currentStreak = 7; // TODO: aus Datenbank berechnen
      // Dummy-Daten (müssen später durch echte Abfragen ersetzt werden)
      currentStreak = 7;
    } catch (e) {
      error = 'Daten konnten nicht geladen werden.$e';
      print('Fehler: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
    fetchAchievementsData();
    fetchNotifications();
  }

  Future<void> fetchAchievementsData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;

      // Letzte Module
      final achievements = await _supabase
          .from('achievements')
          .select()
          .order('id', ascending: true);

      final achieved = await _supabase
          .from('user_achievements')
          .select('achievement_id, unlocked_at')
          .eq('user_id', user!.id)
          .order('id', ascending: true);

      final achievedMap = {
        for (final a in achieved)
          a['achievement_id'] as int: a['unlocked_at'] != null
              ? DateTime.parse(a['unlocked_at'])
              : null,
      };

      myAchievements.clear();

      achievements.forEach((e) {
        final achievementId = e['id'] as int;
        final unlockedDate = achievedMap[achievementId];

        myAchievements.add(
          Achievement(
            id: e['id'],
            title: e['title'],
            description: e['description'],
            icon: achievementsIcon[achievementId - 1],
            color: achievementsColor[achievementId - 1],
            isUnlocked: unlockedDate != null,
            unlockedDate: unlockedDate,
            points: e['awarded_points'],
          ),
        );
      });

      print('test 2:' + myAchievements.length.toString());
    } catch (e) {
      error = 'Diese Daten konnten nicht geladen werden.';
      print('Fehler: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // NEU: Profil Daten abrufen
  // NEU: Profil Daten abrufen
  Future<void> fetchProfileData() async {
    isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      print(' Lade Profildaten für User: ${user.id}');

      // 1. Benutzerdaten aus user_profiles Tabelle
      final profileResponse = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle()
          .catchError((e) {
            print('⚠️ Kein Profil in user_profiles gefunden: $e');
            return null;
          });

      print('Profil Response: $profileResponse');

      if (profileResponse != null) {
        profileName = profileResponse['name'] as String? ?? '';
        profileEmail = profileResponse['email'] as String? ?? '';
        profileUsername = profileResponse['username'] as String? ?? '';
        profileAvatarUrl = profileResponse['avatar_url'] as String?;

        // Mitglied seit Datum
        final createdAt = profileResponse['created_at'] as String?;
        if (createdAt != null) {
          final date = DateTime.tryParse(createdAt);
          if (date != null) {
            profileCreatedAt =
                'Mitglied seit ${date.day}.${date.month}.${date.year}';
          }
        }

        print('📝 Geladene Profildaten:');
        print('   - Name: $profileName');
        print('   - Email: $profileEmail');
        print('   - Username: $profileUsername');
        print('   - Mitglied seit: $profileCreatedAt');

        // Falls name leer ist, verwende den aus user_metadata
        if (profileName.isEmpty) {
          final fullName = user.userMetadata?['full_name'];
          profileName = (fullName != null && fullName.isNotEmpty)
              ? fullName
              : user.email?.split('@').first.capitalize() ?? 'User';
        }
      } else {
        print(' Kein Profil gefunden, setze Standardwerte');
        // Fallback auf User Metadata
        final fullName = user.userMetadata?['full_name'];
        profileName = (fullName != null && fullName.isNotEmpty)
            ? fullName
            : user.email?.split('@').first.capitalize() ?? 'User';
        profileEmail = user.email ?? '';
        profileUsername = user.userMetadata?['username'] ?? '';
        profileCreatedAt = 'Mitglied seit heute';
      }

      // 2. Statistiken für Profilseite berechnen
      await _calculateProfileStatistics(user.id);

      print('✅ Profildaten erfolgreich geladen');
    } catch (e) {
      print('❌ FEHLER beim Laden der Profildaten: $e');
      print('Stacktrace: ${e.toString()}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _calculateProfileStatistics(String userId) async {
    try {
      // Aus learning_sessions: Gelernte Stunden und Fragen
      final sessionsResponse = await _supabase
          .from('learning_sessions')
          .select('total_questions, correct_answered, timer_duration_minutes')
          .eq('user_id', userId);

      if (sessionsResponse.isNotEmpty) {
        int totalQuestions = 0;
        int correctAnswers = 0;
        int totalDuration = 0;

        for (var session in sessionsResponse) {
          totalQuestions += (session['total_questions'] as int?) ?? 0;
          correctAnswers += (session['correct_answered'] as int?) ?? 0;
          final durationMinutes =
              (session['timer_duration_minutes'] as int?) ?? 0;
          totalDuration +=
              durationMinutes * 60; // Minuten zu Sekunden umrechnen
        }

        this.totalQuestions = totalQuestions;
        learnedHours = (totalDuration / 3600).round(); // Sekunden zu Stunden
        averageScore = totalQuestions > 0
            ? (correctAnswers / totalQuestions * 100)
            : 0.0;
      }

      // Abgeschlossene Module aus user_statistics
      try {
        final statisticsResponse = await _supabase
            .from('user_statistics')
            .select('modules_completed')
            .eq('user_id', userId)
            .single();

        if (statisticsResponse != null) {
          modulesCompleted =
              (statisticsResponse['modules_completed'] as int?) ?? 0;
        }
      } catch (e) {
        print('Keine user_statistics für User $userId gefunden: $e');
        modulesCompleted = 0;
      }
    } catch (e) {
      print('Fehler beim Berechnen der Profil-Statistiken: $e');
    }
  }

  // NEU: Statistiken für HomeScreen berechnen
  Future<void> _calculateUserStatistics() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Aus user_statistics Tabelle
      try {
        final statisticsResponse = await _supabase
            .from('user_statistics')
            .select(
              'modules_completed, questions_answered_this_week, current_streak',
            )
            .eq('user_id', user.id)
            .single();

        if (statisticsResponse != null) {
          modulesCompleted =
              (statisticsResponse['modules_completed'] as int?) ?? 0;
          questionsThisWeek =
              (statisticsResponse['questions_answered_this_week'] as int?) ?? 0;
          currentStreak = (statisticsResponse['current_streak'] as int?) ?? 0;
        }
      } catch (e) {
        print('Keine user_statistics gefunden: $e');
        modulesCompleted = 0;
        questionsThisWeek = 0;
        currentStreak = 0;
      }
    } catch (e) {
      print('Fehler beim Berechnen der User-Statistiken: $e');
    }
  }

   //  Profil aktualisieren
  Future<bool> updateProfile({
    required String name,
    required String email,
    required String username,
  }) async {
    try {
      print('=== START updateProfile ===');
      final user = _supabase.auth.currentUser;

      if (user == null) {
        print('❌ FEHLER: Kein eingeloggter User');
        return false;
      }

      print('✅ User gefunden: ${user.id}, ${user.email}');

      //  Prüfe ob Email geändert wurde
      final originalAuthEmail = user.email ?? '';
      bool emailChanged = email != originalAuthEmail;

      // 1. UPDATE in user_profiles Tabelle
      try {
        final updateData = {
          'name': name,
          'email': email,
          'username': username,
          'updated_at': DateTime.now().toIso8601String(),
        };

        print('🔄 Versuche UPDATE in user_profiles...');
        final updateResult = await _supabase
            .from('user_profiles')
            .update(updateData)
            .eq('id', user.id)
            .select()
            .single();

        print('✅ UPDATE erfolgreich: $updateResult');
      } catch (updateError) {
        print('⚠️ UPDATE fehlgeschlagen: $updateError');

        // Fallback: INSERT versuchen
        try {
          final insertData = {
            'id': user.id,
            'name': name,
            'email': email,
            'username': username,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };

          print('🔄 Versuche INSERT...');
          final insertResult = await _supabase
              .from('user_profiles')
              .insert(insertData)
              .select()
              .single();

          print('✅ INSERT erfolgreich: $insertResult');
        } catch (insertError) {
          print('❌ INSERT auch fehlgeschlagen: $insertError');
          return false;
        }
      }

      // 2.  Auth-Email DIREKT aktualisieren (ohne Verifizierung)
      if (emailChanged) {
        print('🔄 Aktualisiere Auth-Email von $originalAuthEmail zu $email');
        try {
          // Direkte Email-Änderung (funktioniert weil "Confirm email change" OFF ist)
          await _supabase.auth.updateUser(UserAttributes(email: email));
          print('✅ Auth-Email SOFORT geändert auf: $email');

          // Keine Verifizierungs-Email wird gesendet!
        } catch (authError) {
          print('⚠️ Auth-Email Update fehlgeschlagen: $authError');

          // Fehler-Handling
          if (authError.toString().contains('already in use')) {
            print('⚠️ Diese Email wird bereits verwendet');
          } else {
            print('⚠️ Unbekannter Fehler: $authError');
          }

          // Auch bei Fehler weiter machen, da user_profiles schon aktualisiert
        }
      }

      // 3. Lokale Daten aktualisieren
      profileName = name;
      profileEmail = email; // Lokal die neue Email setzen
      profileUsername = username;
      userName = name;
      userInitials = name.isNotEmpty
          ? name
                .split(' ')
                .where((e) => e.isNotEmpty)
                .map((e) => e[0])
                .take(2)
                .join()
                .toUpperCase()
          : 'U';

      // 4. Benachrichtigen
      notifyListeners();

      // 5. Erfolgreiche Aktualisierung melden
      print('✅ UpdateProfile erfolgreich abgeschlossen');
      print(
        emailChanged
            ? '📧 Email wurde SOFORT geändert auf: $email'
            : '✅ Nur Name/Username aktualisiert',
      );

      return true;
    } catch (e) {
      print('❌ UNBEKANNTER FEHLER: $e');
      print('Stacktrace: ${e.toString()}');
      return false;
    }
  }

  // Module separat laden (z.B. für Modules Screen)
  Future<void> fetchModules() async {
    isLoading = true;
    notifyListeners();

    try {
      debugPrint('fetchModules: querying supabase modules table...');
      final user = _supabase.auth.currentUser;

      final defaultModules = await _supabase
          .from('modules')
          .select('*')
          .eq('default', true) as List<dynamic>;

      List<dynamic> importedModules = [];
      if (user != null) {
        final imported = await _supabase
            .from('imported_modules')
            .select('module_id')
            .eq('user_id', user.id) as List<dynamic>;

        final importedIds = imported
            .map((row) => row['module_id'])
            .whereType<int>()
            .toList();

        if (importedIds.isNotEmpty) {
          importedModules = await _supabase
              .from('modules')
              .select('*')
              .inFilter('id', importedIds) as List<dynamic>;
        }
      }

      final combined = <int, Map<String, dynamic>>{};
      for (final e in [...defaultModules, ...importedModules]) {
        final m = e as Map<String, dynamic>;
        final idVal = m['id'];
        final idInt = (idVal is int)
            ? idVal
            : (idVal is num
                ? idVal.toInt()
                : int.tryParse(idVal?.toString() ?? '0') ?? 0);
        combined[idInt] = m;
      }

      debugPrint(
        'fetchModules: received ${combined.length} rows (default + imported)',
      );

      lastModules = combined.values.map((e) {
        final m = e as Map<String, dynamic>;
        final idVal = m['id'];
        final idInt = (idVal is int)
            ? idVal
            : (idVal is num
                  ? idVal.toInt()
                  : int.tryParse(idVal?.toString() ?? '0') ?? 0);
        final nameVal = (m['title'] ?? m['name'] ?? '').toString();
        final descVal = (m['description'] ?? '').toString();
        debugPrint('fetchModules: row -> id=$idInt name=$nameVal');
        return LernenModule(id: idInt, name: nameVal, description: descVal);
      }).toList();
    } catch (e) {
      error = 'Konnte Module nicht laden: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Fortschritte aus Supabase laden und Module/Submodule aktualisieren ---

  /// Berechnet den Fortschritt eines Moduls basierend auf seinen Submodulen
  /// Gibt Fortschritt zwischen 0.0 und 1.0 zurück
  Future<double> calculateModuleProgress(dynamic moduleId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0.0;

      // Lade alle Submodule des Moduls
      final submodules = await fetchSubmodules(moduleId);
      if (submodules.isEmpty) return 0.0;

      int completedSubmodules = 0;

      // Prüfe für jedes Submodule, ob es completed ist
      for (var submodule in submodules) {
        final submoduleId = submodule['id'];
        final isCompleted = await isSubmoduleCompleted(submoduleId);
        if (isCompleted) {
          completedSubmodules++;
        }
      }

      // Berechne Fortschritt als Prozentsatz
      final progress = (completedSubmodules / submodules.length);
      debugPrint(
        '📊 Module $moduleId: $completedSubmodules/${submodules.length} submodules completed = ${(progress * 100).toStringAsFixed(1)}%',
      );

      return progress;
    } catch (e) {
      debugPrint('❌ Error calculating module progress: $e');
      return 0.0;
    }
  }

/// Berechnet den Fortschritt eines Submoduls basierend auf den Karten (Level)
/// Gibt Fortschritt zwischen 0.0 und 1.0 zurück
Future<double> calculateSubmoduleProgress(dynamic submoduleId) async {
  try {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0.0;

    // Wenn Submodule bereits als completed markiert ist, zeige 100%
    final submoduleCheck = await _supabase
        .from('submodules')
        .select('iscompleted')
        .eq('id', submoduleId) as List<dynamic>;

    if (submoduleCheck.isNotEmpty) {
      final isCompleted = submoduleCheck.first['iscompleted'] as bool?;
      if (isCompleted == true) {
        return 1.0;
      }
    }

    // 1. Verwende die beste Session-Accuracy (damit sich die Note nicht verschlechtert)
    final bestSession = await _supabase
        .from('learning_sessions')
        .select('accuracy_percentage')
        .eq('user_id', user.id)
        .eq('submodules_id', submoduleId)
        .order('accuracy_percentage', ascending: false)
        .limit(1)
        .maybeSingle() as Map<String, dynamic>?;

    if (bestSession != null && bestSession['accuracy_percentage'] != null) {
      final accuracy = (bestSession['accuracy_percentage'] as num).toDouble();
      final progress = (accuracy / 100.0).clamp(0.0, 1.0);
      debugPrint(
        '📊 Submodule $submoduleId: best accuracy = ${accuracy.toStringAsFixed(1)}%',
      );
      return progress;
    }

    // 2. Versuche Fortschritt aus Level-Tabelle zu berechnen (cards_answered)
    final levelProgressList = await _supabase
        .from('user_submodule_level_progress')
        .select('total_cards_in_level,cards_answered,cards_mastered')
        .eq('user_id', user.id)
        .eq('submodule_id', submoduleId) as List<dynamic>;

    if (levelProgressList.isNotEmpty) {
      int totalCards = 0;
      int answeredCards = 0;

      for (final level in levelProgressList) {
        final total = (level['total_cards_in_level'] as int?) ?? 0;
        if (total <= 0) continue;
        totalCards += total;
        final answered = (level['cards_answered'] as int?) ??
            (level['cards_mastered'] as int?) ??
            0;
        answeredCards += answered;
      }

      if (totalCards > 0) {
        final progress = (answeredCards / totalCards).clamp(0.0, 1.0);
        debugPrint(
          '📊 Submodule $submoduleId: $answeredCards/$totalCards answered = ${(progress * 100).toStringAsFixed(1)}%',
        );
        return progress;
      }
    }

    // 3. Fallback: Fortschritt anhand beantworteter Fragen berechnen
    final questionsResponse = await _supabase
        .from('questions')
        .select('id')
        .eq('submodule_id', submoduleId) as List<dynamic>;

    if (questionsResponse.isEmpty) return 0.0;

    final questionIds = questionsResponse.map((c) => c['id']).toList();
    debugPrint('📊 Submodule $submoduleId: ${questionIds.length} total questions');

    final userProgressResponse = await _supabase
        .from('user_card_progress')
        .select('question_id')
        .eq('user_id', user.id) as List<dynamic>;

    final answeredCount = userProgressResponse
        .where((p) => questionIds.contains(p['question_id']))
        .length;

    final progress = answeredCount / questionIds.length;
    debugPrint(
      '📊 Submodule $submoduleId: $answeredCount/${questionIds.length} answered = ${(progress * 100).toStringAsFixed(1)}%',
    );

    return progress;
  } catch (e) {
    debugPrint('❌ Error calculating submodule progress: $e');
    return 0.0;
  }
}


  /// Berechnet den Fortschritt eines Levels basierend auf gemeisterten Karten
  /// Gibt Fortschritt zwischen 0.0 und 1.0 zurück
  Future<double> calculateLevelProgress(
    dynamic submoduleId,
    int levelNumber,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0.0;

      // Lade den Level-Fortschritt
      final levelProgress = await _supabase
          .from('user_submodule_level_progress')
          .select('*')
          .eq('user_id', user.id)
          .eq('submodule_id', submoduleId)
          .eq('level_number', levelNumber)
          .maybeSingle() as Map<String, dynamic>?;

      if (levelProgress == null) return 0.0;

      final totalCards = (levelProgress['total_cards_in_level'] as int?) ?? 1;
      final masteredCards = (levelProgress['cards_mastered'] as int?) ?? 0;

      final progress = (masteredCards / totalCards).clamp(0.0, 1.0);
      debugPrint(
        '📊 Level $levelNumber: $masteredCards/$totalCards cards mastered = ${(progress * 100).toStringAsFixed(1)}%',
      );

      return progress;
    } catch (e) {
      debugPrint('❌ Error calculating level progress: $e');
      return 0.0;
    }
  }

  /// Lädt alle Fortschritts-Daten aus Supabase und aktualisiert sie in der lokalen Liste
  /// Dies ist die Haupt-Methode, die aufgerufen werden sollte, um alle Fortschritte zu aktualisieren
  Future<Map<int, Map<String, dynamic>>> loadUserProgressForModules(
    List<LernenModule> modules,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {};

      debugPrint('🔄 Lade Fortschritte für ${modules.length} Module...');

      final Map<int, Map<String, dynamic>> moduleProgressMap = {};

      for (var module in modules) {
        final moduleId = module.id;

        // Berechne Fortschritt für dieses Modul
        final progress = await calculateModuleProgress(moduleId);

        // Lade Submodule und deren Fortschritte
        final submodules = await fetchSubmodules(moduleId);
        final Map<int, Map<String, dynamic>> submoduleProgressMap = {};

        for (var submodule in submodules) {
          final submoduleId = submodule['id'];
          final submoduleProgress = await calculateSubmoduleProgress(submoduleId);
          final isCompleted = await isSubmoduleCompleted(submoduleId);

          // Lade Level-Fortschritte
          final levelProgressList = await _supabase
              .from('user_submodule_level_progress')
              .select('*')
              .eq('user_id', user.id)
              .eq('submodule_id', submoduleId)
              .order('level_number', ascending: true) as List<dynamic>;

          submoduleProgressMap[submoduleId as int] = {
            'progress': submoduleProgress,
            'is_completed': isCompleted,
            'levels': levelProgressList,
          };
        }

        moduleProgressMap[moduleId] = {
          'progress': progress,
          'submodules': submoduleProgressMap,
        };

        debugPrint(
          '✅ Module $moduleId geladen: ${(progress * 100).toStringAsFixed(1)}% Fortschritt',
        );
      }

      debugPrint('✅ Alle Fortschritte geladen!');
      return moduleProgressMap;
    } catch (e) {
      debugPrint('❌ Error loading user progress: $e');
      error = 'Konnte Fortschritte nicht laden: $e';
      notifyListeners();
      return {};
    }
  }

  /// Aktualisiert ein einzelnes Modul mit seinem Fortschritt aus der Datenbank
  Future<void> updateModuleProgress(dynamic moduleId) async {
    try {
      debugPrint('🔄 Aktualisiere Fortschritt für Modul $moduleId...');
      final progress = await calculateModuleProgress(moduleId);
      debugPrint('✅ Modul $moduleId: ${(progress * 100).toStringAsFixed(1)}% Fortschritt');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating module progress: $e');
    }
  }

  /// Aktualisiert ein einzelnes Submodul mit seinem Fortschritt aus der Datenbank
  Future<void> updateSubmoduleProgress(dynamic submoduleId) async {
    try {
      debugPrint('🔄 Aktualisiere Fortschritt für Submodul $submoduleId...');
      final progress = await calculateSubmoduleProgress(submoduleId);
      debugPrint('✅ Submodul $submoduleId: ${(progress * 100).toStringAsFixed(1)}% Fortschritt');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating submodule progress: $e');
    }
  }

  /// Lädt alle Fortschritte neu aus der Datenbank (nach Benutzeraktion)
  Future<void> refreshAllProgress() async {
    try {
      debugPrint('🔄 Aktualisiere alle Fortschritte...');
      await loadUserProgressForModules(lastModules);
      debugPrint('✅ Alle Fortschritte aktualisiert');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing progress: $e');
      error = 'Konnte Fortschritte nicht aktualisieren: $e';
      notifyListeners();
    }
  }

  /// Gibt eine detaillierte Fortschritts-Zusammenfassung für ein Submodule zurück
  Future<Map<String, dynamic>> getSubmoduleProgressSummary(dynamic submoduleId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {};

      final progress = await calculateSubmoduleProgress(submoduleId);
      final isCompleted = await isSubmoduleCompleted(submoduleId);

      // Lade Level-Details
      final levelProgressList = await _supabase
          .from('user_submodule_level_progress')
          .select('*')
          .eq('user_id', user.id)
          .eq('submodule_id', submoduleId)
          .order('level_number', ascending: true) as List<dynamic>;

      int totalLevels = levelProgressList.length;
      int unlockedLevels = 0;
      int masteredCards = 0;
      int totalCards = 0;

      for (var levelProgress in levelProgressList) {
        if (levelProgress['is_unlocked'] == true) {
          unlockedLevels++;
        }
        masteredCards += (levelProgress['cards_mastered'] as int?) ?? 0;
        totalCards += (levelProgress['total_cards_in_level'] as int?) ?? 0;
      }

      return {
        'submodule_id': submoduleId,
        'progress': progress,
        'is_completed': isCompleted,
        'total_levels': totalLevels,
        'unlocked_levels': unlockedLevels,
        'total_cards': totalCards,
        'mastered_cards': masteredCards,
        'level_details': levelProgressList,
      };
    } catch (e) {
      debugPrint('❌ Error getting submodule progress summary: $e');
      return {};
    }
  }

  /// Gibt eine detaillierte Fortschritts-Zusammenfassung für ein Modul zurück
  Future<Map<String, dynamic>> getModuleProgressSummary(dynamic moduleId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {};

      final progress = await calculateModuleProgress(moduleId);
      final submodules = await fetchSubmodules(moduleId);

      Map<int, Map<String, dynamic>> submoduleSummaries = {};
      int completedSubmodules = 0;

      for (var submodule in submodules) {
        final subId = submodule['id'] as int;
        final summary = await getSubmoduleProgressSummary(subId);
        submoduleSummaries[subId] = summary;

        if (summary['is_completed'] == true) {
          completedSubmodules++;
        }
      }

      return {
        'module_id': moduleId,
        'progress': progress,
        'total_submodules': submodules.length,
        'completed_submodules': completedSubmodules,
        'submodule_summaries': submoduleSummaries,
      };
    } catch (e) {
      debugPrint('❌ Error getting module progress summary: $e');
      return {};
    }
  }

  // In BackendProvider Klasse fügen Sie diese Methoden hinzu:

  // Reset-Methode
  void reset() {
    userName = '';
    userInitials = '';
    questionsThisWeek = 0;
    currentStreak = 0;

    // Profil Daten
    profileName = '';
    profileEmail = '';
    profileUsername = '';
    profileAvatarUrl = null;
    profileCreatedAt = '';
    learnedHours = 0;
    averageScore = 0.0;
    totalQuestions = 0;

    isLoading = false;
    error = null;

    notifyListeners();
  }

  // --- Submodule laden ---
  Future<List<Map<String, dynamic>>> fetchSubmodules(dynamic moduleId) async {
    try {
      final subs =
          await _supabase
                  .from('submodules')
                  .select('*')
                  .eq('modules_id', moduleId)
              as List<dynamic>;

      return subs.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      error = 'Konnte Submodule nicht laden: $e';
      notifyListeners();
      return [];
    }
  }

  Future<void> deleteModules(List<int> moduleIds) async {
    if (moduleIds.isEmpty) return;
    try {
      for (final id in moduleIds) {
        await _supabase.from('modules').delete().eq('id', id);
      }
      await fetchModules();
    } catch (e) {
      debugPrint('deleteModules error: $e');
    }
  }

  Future<void> deleteSubmodules(List<int> submoduleIds) async {
    if (submoduleIds.isEmpty) return;
    try {
      for (final id in submoduleIds) {
        await _supabase.from('submodules').delete().eq('id', id);
      }
    } catch (e) {
      debugPrint('deleteSubmodules error: $e');
    }
  }

  // NEU: Prüfe ob ein Submodule abgeschlossen ist (alle Cards gemeistert ODER iscompleted=true)
  Future<bool> isSubmoduleCompleted(dynamic submoduleId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Zuerst prüfe ob `iscompleted` in der Datenbank true ist
      final submoduleCheck = await _supabase
          .from('submodules')
          .select('iscompleted')
          .eq('id', submoduleId) as List<dynamic>;

      if (submoduleCheck.isNotEmpty) {
        final isCompleted = submoduleCheck.first['iscompleted'] as bool?;
        if (isCompleted == true) {
          debugPrint('✅ Submodule $submoduleId: Bereits als completed markiert');
          return true;
        }
      }

      // Prüfe beste Session-Accuracy
      final bestSession = await _supabase
          .from('learning_sessions')
          .select('accuracy_percentage')
          .eq('user_id', user.id)
          .eq('submodules_id', submoduleId)
          .order('accuracy_percentage', ascending: false)
          .limit(1)
          .maybeSingle() as Map<String, dynamic>?;

      if (bestSession != null && bestSession['accuracy_percentage'] != null) {
        final accuracy = (bestSession['accuracy_percentage'] as num).toDouble();
        if (accuracy >= 80.0) {
          debugPrint('✅ Submodule $submoduleId: best accuracy ${accuracy.toStringAsFixed(1)}%');
          return true;
        }
      }

      // Lade alle Cards für dieses Submodule
      final cards = await _supabase
          .from('questions')
          .select('id')
          .eq('submodule_id', submoduleId) as List<dynamic>;

      if (cards.isEmpty) return true;

      final cardIds = cards.map((c) => c['id']).toList();

      // Prüfe wie viele Cards der Nutzer gemeistert hat
        final userProgress = await _supabase
          .from('user_card_progress')
          .select('question_id,is_mastered')
          .eq('user_id', user.id) as List<dynamic>;

        final masteredCount = userProgress
          .where((p) =>
            (p['is_mastered'] == true) &&
            cardIds.contains(p['question_id']))
          .length;

      // Completed wenn mindestens 80% gemeistert
      final completion = (masteredCount / cardIds.length) * 100;
      debugPrint('✅ Submodule $submoduleId: $masteredCount/${cardIds.length} mastered = ${completion.toStringAsFixed(1)}%');
      return completion >= 80.0;
    } catch (e) {
      debugPrint('❌ Error checking submodule completion: $e');
      return false;
    }
  }

  // Markiere Submodule als completed in der Datenbank
  Future<void> markSubmoduleAsCompleted(dynamic submoduleId) async {
    try {
      debugPrint('📌 Markiere Submodule $submoduleId als completed...');
      await _supabase
          .from('submodules')
          .update({'iscompleted': true})
          .eq('id', submoduleId);
      debugPrint('✅ Submodule $submoduleId erfolgreich als completed markiert');
    } catch (e) {
      debugPrint('❌ Error marking submodule as completed: $e');
    }
  }

  // --- Karten für Submodule + Level laden ---
  Future<List<Map<String, dynamic>>> fetchCardsForSubmoduleLevel(
    dynamic submoduleId,
    int level,
  ) async {
    try {
      debugPrint(
        'fetchCardsForSubmoduleLevel: submoduleId=$submoduleId level=$level',
      );

      final cards =
          await _supabase
                  .from('questions')
                  .select('*')
                  .eq('submodule_id', submoduleId)
                  .eq('level_number', level)
              as List<dynamic>;

      debugPrint(
        'fetchCardsForSubmoduleLevel: got ${cards.length} rows with level filter',
      );

      if (cards.isEmpty) {
        // Fallback: lade alle Fragen für das Submodule ohne Level-Filter
        debugPrint(
          'fetchCardsForSubmoduleLevel: fallback to submodule-only query',
        );
        final all =
            await _supabase
                    .from('questions')
                    .select('*')
                    .eq('submodule_id', submoduleId)
                as List<dynamic>;
        debugPrint(
          'fetchCardsForSubmoduleLevel: got ${all.length} rows without level filter',
        );
        return all.map((e) => e as Map<String, dynamic>).toList();
      }

      return cards.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      error = 'Konnte Karten nicht laden: $e';
      notifyListeners();
      return [];
    }
  }

  // --- ALLE Fragen eines Submoduls laden (für Quiz-Session) ---
  Future<List<Map<String, dynamic>>> fetchAllQuestionsForSubmodule(
    dynamic submoduleId,
  ) async {
    try {
      debugPrint('fetchAllQuestionsForSubmodule: submoduleId=$submoduleId');

      final questions =
          await _supabase
                  .from('questions')
                  .select('*')
                  .eq('submodule_id', submoduleId)
                  .order('level_number', ascending: true)
              as List<dynamic>;

      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint(
          'fetchAllQuestionsForSubmodule: received ${questions.length} questions',
        );
        return questions.map((e) => e as Map<String, dynamic>).toList();
      }

      // Entferne Karten, die bereits 6x in Folge richtig beantwortet wurden
      final mastered = await _supabase
          .from('user_card_progress')
          .select('question_id')
          .eq('user_id', user.id)
          .eq('is_mastered', true) as List<dynamic>;

      final masteredIds = mastered.map((m) => m['question_id']).toSet();
      final filtered = questions
          .map((e) => e as Map<String, dynamic>)
          .where((q) => !masteredIds.contains(q['id']))
          .toList();

      debugPrint(
        'fetchAllQuestionsForSubmodule: received ${questions.length} questions, filtered to ${filtered.length} (mastered removed)',
      );
      return filtered;
    } catch (e) {
      debugPrint('fetchAllQuestionsForSubmodule error: $e');
      return [];
    }
  }

  // --- Mastered Questions (6er-Streak) für Submodul laden ---
  Future<Set<int>> getMasteredQuestionIdsForSubmodule(dynamic submoduleId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {};

      final questions = await _supabase
          .from('questions')
          .select('id')
          .eq('submodule_id', submoduleId) as List<dynamic>;

      if (questions.isEmpty) return {};

      final questionIds = questions.map((q) => q['id']).toSet();

      final mastered = await _supabase
          .from('user_card_progress')
          .select('question_id')
          .eq('user_id', user.id)
          .eq('is_mastered', true) as List<dynamic>;

      final masteredIds = mastered.map((m) => m['question_id']).toSet();

      return questionIds.intersection(masteredIds).cast<int>();
    } catch (e) {
      debugPrint('getMasteredQuestionIdsForSubmodule error: $e');
      return {};
    }
  }

  // --- Optionen für eine Frage laden ---
  Future<List<Map<String, dynamic>>> fetchOptionsForQuestion(
    dynamic questionId,
  ) async {
    try {
      final opts =
          await _supabase
                  .from('options')
                  .select('*')
                  .eq('question_id', questionId)
              as List<dynamic>;

      return opts.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('fetchOptionsForQuestion error: $e');
      return [];
    }
  }

  // --- Optionen für mehrere Fragen batch-laden ---
  Future<Map<dynamic, List<Map<String, dynamic>>>> fetchOptionsForQuestions(
    List<dynamic> questionIds,
  ) async {
    try {
      if (questionIds.isEmpty) return {};

      final allOptions =
          await _supabase
                  .from('options')
                  .select('*')
                  .inFilter('question_id', questionIds)
              as List<dynamic>;

      // Gruppiere nach question_id
      final Map<dynamic, List<Map<String, dynamic>>> grouped = {};
      for (var opt in allOptions) {
        final opt_map = opt as Map<String, dynamic>;
        final qId = opt_map['question_id'];
        if (!grouped.containsKey(qId)) {
          grouped[qId] = [];
        }
        grouped[qId]!.add(opt_map);
      }
      return grouped;
    } catch (e) {
      debugPrint('fetchOptionsForQuestions error: $e');
      return {};
    }
  }

  // --- Learning Session starten ---
  Future<String?> startLearningSession(dynamic submoduleId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      debugPrint('📌 Starte Learning Session für Submodule: $submoduleId (Type: ${submoduleId.runtimeType})');

      // Erstelle Learning Session OHNE submodule_id (diese kommt in submodules_per_session)
      final insert = await _supabase
          .from('learning_sessions')
          .insert({
            'user_id': user.id,
            'start_time': DateTime.now().add(const Duration(hours: 1)).toIso8601String() ,
            'total_questions': 0,
            'correct_answered': 0,
            'incorrect_answered': 0,
            'accuracy_percentage': 0,
            'status': 'active',
            'timer_duration_minutes': 0,
            'submodules_id': int.parse(submoduleId.toString()),
          })
          .select() as List<dynamic>;

      final session = insert.first as Map<String, dynamic>;
      final sessionId = session['id']?.toString();

      debugPrint('✅ Learning Session erstellt: $sessionId');

      // Speichere Link zwischen Session und Submodule
      if (sessionId != null) {
        await _supabase.from('submodules_per_session').insert({
          'session_id': sessionId,
          'submodule_id': int.parse(submoduleId.toString()),
        });
        debugPrint('✅ Learning Session erstellt: $sessionId');
        debugPrint('✅ Submodule Link gespeichert: Session=$sessionId, Submodule=$submoduleId');
      }

      lastSession = session;
      notifyListeners();
      return sessionId;
    } catch (e) {
      error = 'Konnte Session nicht starten: $e';
      debugPrint('❌ Error starting session: $e');
      notifyListeners();
      return null;
    }
  }

  Future<void> finishLearningSession(
    String sessionId, {
    required int total,
    required int correct,
    required dynamic submoduleId, //  Submodule ID um am Ende zu markieren
    int durationMinutes = 0, //  Dauer in Minuten
  }) async {
    try {
      final incorrect = total - correct;
      final accuracy = total == 0 ? 0 : ((correct / total) * 100).round();

      final wasCompleted = await isSubmoduleCompleted(submoduleId);

      debugPrint('✅ finishLearningSession: sessionId=$sessionId, total=$total, correct=$correct, duration=${durationMinutes}min, accuracy=$accuracy%');

      await _supabase
          .from('learning_sessions')
          .update({
            'end_time': DateTime.now().toIso8601String(),
            'total_questions': total,
            'correct_answered': correct,
            'incorrect_answered': incorrect,
            'accuracy_percentage': accuracy,
            'status': 'finished',
            'timer_duration_minutes': durationMinutes, // Speichere die Zeit
            'iscompleted': accuracy == 100,
          })
          .eq('id', sessionId);

      debugPrint('✅ Session saved to database with duration: $durationMinutes minutes');


      if (accuracy >= 80) {
        await markSubmoduleAsCompleted(submoduleId);
        debugPrint('🎉 Submodule $submoduleId erfolgreich als completed markiert!');

        if (!wasCompleted) {
          await addNotification(
            'Glückwunsch! 🎉',
            'Du hast ein Submodul abgeschlossen (${accuracy}%).',
          );
        } else {
          await addNotification(
            'Bestanden ✅',
            'Du hast das Submodul erneut bestanden (${accuracy}%).',
          );
        }
      } else {
        debugPrint('⚠️ Nur $accuracy% erreicht - Submodule nicht als completed markiert (benötigt 80%)');
      }

      //  Setze is_completed in user_submodule_level_progress bei 100%
      if (accuracy == 100) {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          await _supabase
              .from('user_submodule_level_progress')
              .update({
                'is_completed': true,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', user.id)
              .eq('submodule_id', submoduleId);
        }
      }

      // Aktualisiere lokale letzte Session
      lastSession =
          (await _supabase
                          .from('learning_sessions')
                          .select()
                          .eq('id', sessionId)
                      as List<dynamic>)
                  .first
              as Map<String, dynamic>;

      notifyListeners();
    } catch (e) {
      error = 'Konnte Session nicht beenden: $e';
      debugPrint('❌ finishLearningSession error: $e');
      notifyListeners();
    }
  }

  // --- Antwort verarbeiten & 6x-Mastery Logik ---
  Future<void> recordAnswer(String cardId, bool correct) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // hole bestehenden Fortschritt
        final existing =
          await _supabase
              .from('user_card_progress')
              .select()
              .eq('user_id', user.id)
              .eq('question_id', cardId)
            as List<dynamic>;

      Map<String, dynamic>? progress = existing.isNotEmpty
          ? existing.first as Map<String, dynamic>
          : null;

      if (progress == null) {
        // Erstelle neuen Eintrag
        final insert =
            await _supabase.from('user_card_progress').insert({
                  'user_id': user.id,
                  'question_id': cardId,
                  'correct_count': correct ? 1 : 0,
                  'incorrect_count': correct ? 0 : 1,
                  'streak_count': correct ? 1 : 0,
                  'is_mastered': correct ? (1 >= 6) : false,
                  'last_reviewed': DateTime.now().toIso8601String(),
                }).select()
                as List<dynamic>;

        progress = insert.first as Map<String, dynamic>;
      } else {
        // Update
        int streak = (progress['streak_count'] ?? 0) as int;
        int correctCount = (progress['correct_count'] ?? 0) as int;
        int incorrectCount = (progress['incorrect_count'] ?? 0) as int;

        if (correct) {
          streak += 1;
          correctCount += 1;
        } else {
          streak = 0;
          incorrectCount += 1;
        }

        final isMastered = streak >= 6;

        await _supabase
            .from('user_card_progress')
            .update({
              'streak_count': streak,
              'correct_count': correctCount,
              'incorrect_count': incorrectCount,
              'is_mastered': isMastered,
              'last_reviewed': DateTime.now().toIso8601String(),
            })
            .eq('id', progress['id']);
      }

      // Nach Update: berechne Level-Fortschritt und evtl. freischalten
      await _recalculateSubmoduleLevelProgressForCard(cardId, user.id);
      notifyListeners();
    } catch (e) {
      error = 'Konnte Antwort nicht speichern: $e';
      notifyListeners();
    }
  }

  // --- Hilfsfunktion: Level-Fortschritt neu berechnen und ggf. freischalten ---
  Future<void> _recalculateSubmoduleLevelProgressForCard(
    String cardId,
    String userId,
  ) async {
    try {
      // Karte laden, um submodule_id und level zu kennen
      final cardList =
          await _supabase.from('questions').select().eq('id', cardId)
              as List<dynamic>;

      if (cardList.isEmpty) return;
      final card = cardList.first as Map<String, dynamic>;
      final submoduleId = (card['submodule_id'] ?? card['submoduleId'])
          .toString();
      final level = (card['level_number'] ?? card['level']) as int;

      // Anzahl Karten in diesem Submodule-Level
      final allCards =
          await _supabase
                  .from('questions')
                  .select('id')
                  .eq('submodule_id', submoduleId)
                  .eq('level_number', level)
              as List<dynamic>;

      final total = allCards.length;

      // Anzahl gemeisterter Karten durch Nutzer
      final allCardIds = allCards.map((e) => e['id']).toList();

        final userProgress =
          await _supabase
              .from('user_card_progress')
              .select('id,question_id,is_mastered')
              .eq('user_id', userId)
            as List<dynamic>;

        final mastered = userProgress
          .where(
          (p) =>
            (p['is_mastered'] == true) &&
            allCardIds.contains(p['question_id']),
          )
          .toList();

      final masteredCount = mastered.length;
      final percent = total == 0 ? 0.0 : (masteredCount / total) * 100.0;

      // Update or insert progress for this submodule-level
      final existing =
          await _supabase
                  .from('user_submodule_level_progress')
                  .select()
                  .eq('user_id', userId)
                  .eq('submodule_id', submoduleId)
                  .eq('level_number', level)
              as List<dynamic>;

      final unlocked = percent >= 80.0;

      if (existing.isNotEmpty) {
        await _supabase
            .from('user_submodule_level_progress')
            .update({
              'total_cards_in_level': total,
              'cards_mastered': masteredCount,
              'cards_answered': await _countAnsweredInList(userId, allCards),
              'is_unlocked': unlocked,
              'updated_at': DateTime.now().toIso8601String(),
              'last_accessed': DateTime.now().toIso8601String(),
            })
            .eq('id', (existing.first as Map<String, dynamic>)['id']);
      } else {
        await _supabase.from('user_submodule_level_progress').insert({
          'user_id': userId,
          'submodule_id': submoduleId,
          'level_number': level,
          'total_cards_in_level': total,
          'cards_mastered': masteredCount,
          'cards_answered': await _countAnsweredInList(userId, allCards),
          'is_unlocked': unlocked,
          'unlocked_at': unlocked ? DateTime.now().toIso8601String() : null,
        });
      }

      // Wenn freigeschaltet: evtl. nächsten Level-Eintrag sicherstellen
      if (unlocked) {
        final nextLevel = level + 1;
        final existingNext =
            await _supabase
                    .from('user_submodule_level_progress')
                    .select()
                    .eq('user_id', userId)
                    .eq('submodule_id', submoduleId)
                    .eq('level_number', nextLevel)
                as List<dynamic>;

        if (existingNext.isEmpty) {
          await _supabase.from('user_submodule_level_progress').insert({
            'user_id': userId,
            'submodule_id': submoduleId,
            'level_number': nextLevel,
            'total_cards_in_level': 0,
            'cards_mastered': 0,
            'cards_answered': 0,
            'is_unlocked': false,
          });
        }
      }
    } catch (e) {
      // Nicht fatal: nur melden
      print('Fehler beim Neuberechnen des Level-Fortschritts: $e');
    }
  }

  Future<int> _countAnsweredInList(
    String userId,
    List<dynamic> allCards,
  ) async {
    if (allCards.isEmpty) return 0;
    try {
      final allCardIds = allCards.map((e) => e['id']).toList();
        final userProgress =
          await _supabase
              .from('user_card_progress')
              .select('id,question_id')
              .eq('user_id', userId)
            as List<dynamic>;

        final answered = userProgress
          .where((p) => allCardIds.contains(p['question_id']))
          .toList();
      return answered.length;
    } catch (_) {
      return 0;
    }
  }

  //  Clear-Methode für Logout
  void clearData() {
    reset();
  }
}

// --- Home Screen ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --- StatCard Widget ---
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppColors.appHeaderBackgroundGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColorDark.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BackendProvider(),
      child: Consumer<BackendProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (provider.error != null) {
            return Scaffold(body: Center(child: Text(provider.error!)));
          }

          return Scaffold(
            backgroundColor: Colors.black,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Begrüßung mit vollständigem Namen ---
                        Text(
                          'Welcome back, ${provider.userName}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Education is the passport to the future!',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        _buildStatCard(
                          icon: Icons.my_location_outlined,
                          value: provider.questionsThisWeek.toString(),
                          label: 'Questions this week',
                        ),
                        _buildStatCard(
                          icon: Icons.watch_later_outlined,
                          value: '${provider.currentStreak} days',
                          label: 'Current streak',
                        ),
                        _buildStatCard(
                          icon: Icons.workspace_premium_outlined,
                          value: '${provider.modulesCompleted}/12',
                          label: 'Modules completed',
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Continue where you left off',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (var module in provider.lastModules)
                          QuizCard(
                            moduleTitle: module.name,
                            moduleDescription: module.description ?? '',
                            progress: provider.calculateProgress(
                              provider.lastSession,
                            ),
                            onResume: () {},
                          ),
                        const SizedBox(height: 24),
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CategoryCard(
                          icon: Icons.stacked_bar_chart,
                          title: 'Browse Modules',
                          subtitle: 'View all modules',
                          iconColor: Colors.blue,
                          onTap: () {
                            Navigator.pushNamed(context, '/modules');
                          },
                        ),
                        CategoryCard(
                          icon: Icons.emoji_events_outlined,
                          title: 'Achievements',
                          subtitle: 'View your badges and rewards',
                          iconColor: Colors.orange,
                          onTap: () {},
                        ),
                        CategoryCard(
                          icon: Icons.trending_up,
                          title: 'Statistics',
                          subtitle: 'Track your progress',
                          iconColor: Colors.green,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
