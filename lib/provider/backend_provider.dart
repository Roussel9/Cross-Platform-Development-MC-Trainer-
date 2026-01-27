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

import 'package:mc_trainer_kami/models/importable_module.dart';

// Extension zur Großschreibung von Strings
extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}

// --- Backend Provider ---
class BackendProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  StreamSubscription<dynamic>? _authSub;

  List<ImportableModule> availableModules = [];

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
  List<LernenModule> lastModules = [];
  Map<String, dynamic>? lastSession;
  List<Achievement> myAchievements = [];
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

    // Beobachte Auth-Status; beim Login/Logout ggf. Module nachladen
    try {
      _authSub = _supabase.auth.onAuthStateChange.listen((data) {
        debugPrint('Auth state changed: $data');
        // Nach Auth-Änderung Module neu laden
        fetchModules();
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

      print('🔍 Lade Profildaten für User: ${user.id}');

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

      print('📊 Profil Response: $profileResponse');

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
        print('⚠️ Kein Profil gefunden, setze Standardwerte');
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

  // NEU: Profil aktualisieren (VERBESSERTE VERSION MIT DEBUGGING)
  // NEU: Profil aktualisieren (MIT AUTH-EMAIL UPDATE)
  // NEU: Profil aktualisieren (OHNE VERIFIZIERUNG - MIT SOFORTIGER EMAIL-ÄNDERUNG)
  // NEU: Profil aktualisieren (DIREKT OHNE VERIFIZIERUNG)
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

      // ✅ WICHTIG: Prüfe ob Email geändert wurde
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

      // 2. WICHTIG: Auth-Email DIREKT aktualisieren (ohne Verifizierung)
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
      final modulesData =
          await _supabase.from('modules').select('*') as List<dynamic>;
      debugPrint('fetchModules: received ${modulesData.length} rows');

      lastModules = modulesData.map((e) {
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

      debugPrint(
        'fetchAllQuestionsForSubmodule: received ${questions.length} questions',
      );
      return questions.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('fetchAllQuestionsForSubmodule error: $e');
      return [];
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

      final insert =
          await _supabase.from('learning_sessions').insert({
                'user_id': user.id,
                'submodule_id': submoduleId,
                'start_time': DateTime.now().toIso8601String(),
                'total_questions': 0,
                'correct_answered': 0,
                'incorrect_answered': 0,
                'status': 'active',
              }).select()
              as List<dynamic>;

      final session = insert.first as Map<String, dynamic>;
      lastSession = session;
      notifyListeners();
      return session['id']?.toString();
    } catch (e) {
      error = 'Konnte Session nicht starten: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> finishLearningSession(
    String sessionId, {
    required int total,
    required int correct,
  }) async {
    try {
      final incorrect = total - correct;
      final accuracy = total == 0 ? 0 : ((correct / total) * 100).round();

      await _supabase
          .from('learning_sessions')
          .update({
            'end_time': DateTime.now().toIso8601String(),
            'total_questions': total,
            'correct_answered': correct,
            'incorrect_answered': incorrect,
            'accuracy_percentage': accuracy,
            'status': 'finished',
          })
          .eq('id', sessionId);

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
                  .eq('card_id', cardId)
              as List<dynamic>;

      Map<String, dynamic>? progress = existing.isNotEmpty
          ? existing.first as Map<String, dynamic>
          : null;

      if (progress == null) {
        // Erstelle neuen Eintrag
        final insert =
            await _supabase.from('user_card_progress').insert({
                  'user_id': user.id,
                  'card_id': cardId,
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
                  .select('id,card_id,is_mastered')
                  .eq('user_id', userId)
              as List<dynamic>;

      final mastered = userProgress
          .where(
            (p) =>
                (p['is_mastered'] == true) && allCardIds.contains(p['card_id']),
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
                  .select('id,card_id')
                  .eq('user_id', userId)
              as List<dynamic>;

      final answered = userProgress
          .where((p) => allCardIds.contains(p['card_id']))
          .toList();
      return answered.length;
    } catch (_) {
      return 0;
    }
  }

  // Optional: Clear-Methode für Logout
  void clearData() {
    reset();
  }
  // In backend_provider.dart - NEUE IMPORT-METHODEN

  Future<void> fetchImportableModules() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      print('🔍 Lade importierbare Module für User: ${user.id}');

      // 1. Module, die dieser User bereits importiert hat
      final importedByUser =
          await _supabase
                  .from('imported_modules')
                  .select('module_id')
                  .eq('user_id', user.id)
              as List<dynamic>;

      final importedModuleIds = importedByUser
          .map((im) => im['module_id'] as int)
          .toList();

      // 2. Default-Module aus der Datenbank (nicht importierbar)
      final defaultModules =
          await _supabase.from('modules').select('title').eq('default', true)
              as List<dynamic>;

      final defaultModuleTitles = defaultModules
          .map((dm) => dm['title'] as String)
          .toList();

      print('📊 Default Module: $defaultModuleTitles');
      print('📊 Bereits importierte Module IDs: $importedModuleIds');

      // 3. Externe Module simulieren
      final externalModules = await _simulateExternalServerCall();

      // 4. Liste aufbauen
      availableModules.clear();

      for (var extMod in externalModules) {
        final extModMap = extMod as Map<String, dynamic>;
        final String title = extModMap['title'] as String;
        final int externalId = extModMap['id'] as int;

        // Prüfe ob es ein Default-Modul ist
        final isDefaultModule = defaultModuleTitles.contains(title);

        if (isDefaultModule) {
          // Default-Module: Prüfe ob der User es "hat" (in imported_modules)
          // Finde die module_id in der modules Tabelle
          final moduleInDb =
              await _supabase
                      .from('modules')
                      .select('id')
                      .eq('title', title)
                      .maybeSingle()
                  as Map<String, dynamic>?;

          bool isImportedByUser = false;
          if (moduleInDb != null) {
            final int dbModuleId = moduleInDb['id'] as int;
            isImportedByUser = importedModuleIds.contains(dbModuleId);
          }

          availableModules.add(
            ImportableModule(
              id: externalId,
              title: title,
              description: extModMap['description'] as String,
              icon: extModMap['icon'] as String,
              color: extModMap['color'] as String,
              isDefault: true,
              isImported: isImportedByUser,
              serverUrl: extModMap['server_url'] as String?,
            ),
          );
        } else {
          // Nicht-Default Module: Prüfe ob es bereits in modules existiert
          final moduleInDb =
              await _supabase
                      .from('modules')
                      .select('id')
                      .eq('title', title)
                      .maybeSingle()
                  as Map<String, dynamic>?;

          bool isImportedByUser = false;
          if (moduleInDb != null) {
            final int dbModuleId = moduleInDb['id'] as int;
            isImportedByUser = importedModuleIds.contains(dbModuleId);
          }

          availableModules.add(
            ImportableModule(
              id: externalId,
              title: title,
              description: extModMap['description'] as String,
              icon: extModMap['icon'] as String,
              color: extModMap['color'] as String,
              isDefault: false,
              isImported: isImportedByUser,
              serverUrl: extModMap['server_url'] as String?,
            ),
          );
        }
      }

      print('✅ ${availableModules.length} importierbare Module geladen');

      // Debug-Ausgabe
      for (var module in availableModules) {
        print(
          '   - ${module.title}: Default=${module.isDefault}, Imported=${module.isImported}',
        );
      }
    } catch (e) {
      error = 'Konnte importierbare Module nicht laden: $e';
      print('❌ Fehler beim Laden importierbarer Module: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Korrigierte importModule Methode:

  Future<bool> importModule(ImportableModule module) async {
    isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ Kein User eingeloggt');
        return false;
      }

      print('🔄 Starte Import von: ${module.title} für User: ${user.id}');

      // 1. Prüfe ob das Modul bereits existiert
      print('🔍 Prüfe ob Modul bereits existiert...');
      final existingModule =
          await _supabase
                  .from('modules')
                  .select('id, default')
                  .eq('title', module.title)
                  .maybeSingle()
              as Map<String, dynamic>?;

      late final dynamic moduleId;
      bool isNewModule = false;

      if (existingModule != null) {
        print('📦 Modul existiert bereits: ${existingModule['id']}');
        moduleId = existingModule['id'];

        // Prüfe ob default bereits false ist
        if ((existingModule['default'] as bool?) == true) {
          print('🔄 Setze default auf false...');
          await _supabase
              .from('modules')
              .update({'default': false})
              .eq('id', moduleId);
        }
      } else {
        // 2. Neues Modul erstellen
        print('📥 Erstelle neues Modul...');
        final moduleData = {
          'title': module.title,
          'description': module.description,
          'icon': module.icon,
          'color': module.color,
          'default': false,
          'created_at': DateTime.now().toIso8601String(),
        };

        final result =
            await _supabase
                    .from('modules')
                    .insert(moduleData)
                    .select('id')
                    .single()
                as Map<String, dynamic>;

        moduleId = result['id'];
        isNewModule = true;
        print('✅ Neues Modul erstellt mit ID: $moduleId');
      }

      // 3. In imported_modules protokollieren (JETZT MIT server_url)
      print('📝 Erstelle imported_modules Eintrag...');

      final importData = {
        'module_id': moduleId,
        'user_id': user.id,
        'imported_at': DateTime.now().toIso8601String(),
        'download_count': 1,
        'server_url':
            module.serverUrl ??
            'https://trainingserver.example.com', // JETZT FUNKTIONIERT DAS!
      };

      // DEBUG: Zeige was gesendet wird
      print('📤 Wird gesendet:');
      importData.forEach((key, value) {
        print('   $key: $value (${value.runtimeType})');
      });

      // Prüfe ob versehentlich ein 'id' Feld existiert
      if (importData.containsKey('id')) {
        print(
          '⚠️ WARNUNG: importData enthält ein "id" Feld! Das wird entfernt...',
        );
        importData.remove('id');
      }

      try {
        final response = await _supabase
            .from('imported_modules')
            .insert(importData)
            .select()
            .single();

        print('✅ Import-Eintrag erfolgreich erstellt: $response');
      } catch (e) {
        print('❌ FEHLER beim INSERT in imported_modules:');
        print('   Error: $e');
        print('   Error Type: ${e.runtimeType}');

        // Teste direkt mit SQL
        print('🔧 Teste mit SQL Query...');
        try {
          final testResult = await _supabase.rpc(
            'debug_insert',
            params: {
              'p_module_id': moduleId,
              'p_user_id': user.id,
              'p_server_url':
                  module.serverUrl ?? 'https://trainingserver.example.com',
            },
          );
          print('SQL Test Result: $testResult');
        } catch (sqlError) {
          print('SQL Test auch fehlgeschlagen: $sqlError');
        }

        rethrow;
      }

      // await _supabase.from('imported_modules').insert(importData);
      print(
        '✅ Import-Eintrag erfolgreich erstellt mit server_url: ${importData['server_url']}',
      );

      // 4. Beispiel-Submodule nur für neue Module
      if (isNewModule) {
        print('📚 Füge Submodule hinzu...');
        await _addSampleSubmodules(moduleId, module);
      }

      // 5. Status aktualisieren
      final index = availableModules.indexWhere((m) => m.title == module.title);
      if (index != -1) {
        availableModules[index] = ImportableModule(
          id: module.id,
          title: module.title,
          description: module.description,
          icon: module.icon,
          color: module.color,
          isDefault: false,
          isImported: true,
          serverUrl: module.serverUrl,
        );
        print(
          '🔄 UI-Status aktualisiert: ${module.title} ist jetzt importiert',
        );
      }

      // 6. Module-Liste neu laden
      await fetchModules();

      // 7. Optional: Debug-Ausgabe
      print('🎉 Import erfolgreich abgeschlossen!');
      return true;
    } catch (e) {
      error = 'Import fehlgeschlagen: $e';
      print('❌ Fehler beim Import: $e');

      // Detaillierte Fehleranalyse
      if (e.toString().contains('server_url')) {
        error = 'Datenbankfehler: Problem mit server_url Spalte. ';
        print(
          '⚠️ Bitte prüfe ob die server_url Spalte in imported_modules existiert',
        );
      }

      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Simulation externer Server-Abfrage ---
  // Korrigierte _simulateExternalServerCall Methode:
  Future<List<Map<String, dynamic>>> _simulateExternalServerCall() async {
    await Future.delayed(const Duration(milliseconds: 800));

    return [
      {
        'id': 101,
        'title': 'Advanced Mathematics',
        'description':
            'Master advanced mathematical concepts and problem-solving',
        'icon': 'calculate',
        'color': '#5E35B1',
        'server_url': 'https://trainingserver.example.com/modules/math',
      },
      {
        'id': 102,
        'title': 'Physics', // ACHTUNG: Dies IST ein default Modul!
        'description': 'Explore the fundamental principles of physics',
        'icon': 'science',
        'color': '#9C27B0',
        'server_url': 'https://trainingserver.example.com/modules/physics',
      },
      {
        'id': 103,
        'title': 'Chemistry',
        'description': 'Learn the core concepts of chemistry',
        'icon': 'biotech',
        'color': '#4CAF50',
        'server_url': 'https://trainingserver.example.com/modules/chemistry',
      },
      {
        'id': 104,
        'title': 'Biology', // ACHTUNG: Dies IST ein default Modul!
        'description': 'Understand the fundamentals of life',
        'icon': 'psychology',
        'color': '#2196F3',
        'server_url': 'https://trainingserver.example.com/modules/biology',
      },
      {
        'id': 105,
        'title': 'Computer Science',
        'description': 'Learn programming and algorithms',
        'icon': 'computer',
        'color': '#FF5722',
        'server_url': 'https://trainingserver.example.com/modules/cs',
      },
      {
        'id': 106,
        'title': 'History',
        'description': 'Explore world history and civilizations',
        'icon': 'history_edu',
        'color': '#795548',
        'server_url': 'https://trainingserver.example.com/modules/history',
      },
      {
        'id': 107,
        'title': 'English', // ACHTUNG: Dies IST ein default Modul!
        'description': 'Learn English language and literature',
        'icon': 'menu_book',
        'color': '#F44336',
        'server_url': 'https://trainingserver.example.com/modules/english',
      },
    ];
  }

  // Methode um zu prüfen, ob ein Modul importierbar ist (nicht default)
  Future<bool> isModuleImportable(String title) async {
    try {
      final result =
          await _supabase
                  .from('modules')
                  .select('default')
                  .eq('title', title)
                  .maybeSingle()
              as Map<String, dynamic>?;

      return result == null || (result['default'] as bool?) == false;
    } catch (e) {
      return true;
    }
  }

  // Methode um User-spezifische importierte Module zu holen
  Future<List<dynamic>> getUserImportedModules() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final imported =
          await _supabase
                  .from('imported_modules')
                  .select('module_id')
                  .eq('user_id', user.id)
              as List<dynamic>;

      return imported;
    } catch (e) {
      return [];
    }
  }

  Future<void> _addSampleSubmodules(
    dynamic moduleId,
    ImportableModule module,
  ) async {
    List<Map<String, dynamic>> submodules = [];

    switch (module.title) {
      case 'Advanced Mathematics':
        submodules = [
          {
            'modules_id': moduleId,
            'title': 'Calculus Basics',
            'description': 'Introduction to differential calculus',
            'level_count': 3,
          },
          {
            'modules_id': moduleId,
            'title': 'Linear Algebra',
            'description': 'Vectors and matrices fundamentals',
            'level_count': 4,
          },
        ];
        break;
      case 'Physics Fundamentals':
        submodules = [
          {
            'modules_id': moduleId,
            'title': 'Mechanics',
            'description': 'Motion and forces',
            'level_count': 3,
          },
          {
            'modules_id': moduleId,
            'title': 'Thermodynamics',
            'description': 'Heat and energy transfer',
            'level_count': 2,
          },
        ];
        break;
      case 'Chemistry Essentials':
        submodules = [
          {
            'modules_id': moduleId,
            'title': 'Atomic Structure',
            'description': 'Basics of atomic theory',
            'level_count': 3,
          },
          {
            'modules_id': moduleId,
            'title': 'Chemical Reactions',
            'description': 'Types of chemical reactions',
            'level_count': 4,
          },
        ];
        break;
      case 'Biology Basics':
        submodules = [
          {
            'modules_id': moduleId,
            'title': 'Cell Biology',
            'description': 'Structure and function of cells',
            'level_count': 3,
          },
          {
            'modules_id': moduleId,
            'title': 'Genetics',
            'description': 'DNA and inheritance',
            'level_count': 4,
          },
        ];
        break;
      default:
        // Generische Submodule für unbekannte Module
        submodules = [
          {
            'modules_id': moduleId,
            'title': 'Introduction',
            'description': 'Introduction to ${module.title}',
            'level_count': 2,
          },
          {
            'modules_id': moduleId,
            'title': 'Advanced Topics',
            'description': 'Advanced concepts in ${module.title}',
            'level_count': 3,
          },
        ];
    }

    for (var submodule in submodules) {
      try {
        await _supabase.from('submodules').insert({
          ...submodule,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('⚠️ Fehler beim Hinzufügen von Submodule: $e');
      }
    }
  }

  // In BackendProvider Klasse, nach den anderen Methoden:

  // Prüft ob ein Modul für den User sichtbar ist (in imported_modules vorhanden)
  // Ersetze diese Methode:
  Future<bool> isModuleAvailableToUser(int moduleId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Prüfe ob der User dieses Modul ÜBERHAUPT sehen kann
      // Das ist der Fall wenn:
      // 1. Es ein Standard-Modul ist ODER
      // 2. Es in imported_modules für diesen User existiert

      // Zuerst: Ist es ein Standard-Modul?
      final module =
          await _supabase
                  .from('modules')
                  .select('default, title')
                  .eq('id', moduleId)
                  .maybeSingle()
              as Map<String, dynamic>?;

      if (module == null) return false; // Modul existiert gar nicht

      final bool isDefault = (module['default'] as bool?) == true;

      if (isDefault) {
        // Standard-Module sind immer verfügbar (können gesehen werden)
        return true;
      } else {
        // Nicht-Standard Module: Prüfe ob importiert
        final imported =
            await _supabase
                    .from('imported_modules')
                    .select('id')
                    .eq('module_id', moduleId)
                    .eq('user_id', user.id)
                    .maybeSingle()
                as Map<String, dynamic>?;

        return imported != null;
      }
    } catch (e) {
      print('Fehler beim Prüfen ob Modul verfügbar: $e');
      return false;
    }
  }

  // Prüft ob ein Modul ein Standard-Modul ist
  Future<bool> isModuleDefault(int moduleId) async {
    try {
      final module =
          await _supabase
                  .from('modules')
                  .select('default')
                  .eq('id', moduleId)
                  .maybeSingle()
              as Map<String, dynamic>?;

      return module != null && (module['default'] as bool?) == true;
    } catch (e) {
      print('Fehler beim Prüfen ob Modul Standard ist: $e');
      return false;
    }
  }

  // Löscht ein Modul (für den aktuellen User)
  Future<bool> deleteModule(int moduleId, String moduleTitle) async {
    isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ Kein User eingeloggt');
        return false;
      }

      print('🗑️ Versuche Modul zu löschen: $moduleTitle (ID: $moduleId)');

      // 1. Hole Modul-Daten um festzustellen ob es Standard ist
      final moduleData =
          await _supabase
                  .from('modules')
                  .select('default, title')
                  .eq('id', moduleId)
                  .maybeSingle()
              as Map<String, dynamic>?;

      if (moduleData == null) {
        print('❌ Modul nicht gefunden');
        error = 'Modul nicht gefunden';
        return false;
      }

      final bool isDefault = (moduleData['default'] as bool?) == true;

      // 2. In deleted_modules Tabelle protokollieren
      print('📝 Logge Löschung in deleted_modules...');
      await _supabase.from('deleted_modules').insert({
        'module_id': moduleId,
        'user_id': user.id,
        'deleted_at': DateTime.now().toIso8601String(),
      });

      if (isDefault) {
        // --- STANDARD MODUL ---
        print('ℹ️ Modul ist ein Standard-Modul');

        // Prüfe ob der User es importiert hat
        final imported =
            await _supabase
                    .from('imported_modules')
                    .select('id')
                    .eq('module_id', moduleId)
                    .eq('user_id', user.id)
                    .maybeSingle()
                as Map<String, dynamic>?;

        if (imported != null) {
          // Aus imported_modules entfernen (wenn vorhanden)
          print('🗑️ Entferne aus imported_modules...');
          await _supabase
              .from('imported_modules')
              .delete()
              .eq('module_id', moduleId)
              .eq('user_id', user.id);
        } else {
          // Noch nie importiert: einfach nur in deleted_modules protokollieren
          print('ℹ️ Modul wurde noch nie importiert, nur protokollieren');
        }

        print('✅ Standard-Modul für diesen User entfernt');
      } else {
        // --- IMPORTIERTES MODUL (nicht Standard) ---
        print('ℹ️ Modul ist ein importiertes Modul');

        // 3. Aus imported_modules entfernen (für diesen User)
        print('🗑️ Entferne aus imported_modules...');
        await _supabase
            .from('imported_modules')
            .delete()
            .eq('module_id', moduleId)
            .eq('user_id', user.id);

        // 4. Prüfe ob es von anderen Usern verwendet wird
        print('🔍 Prüfe ob Modul noch von anderen Usern verwendet wird...');
        final otherUsers =
            await _supabase
                    .from('imported_modules')
                    .select('id')
                    .eq('module_id', moduleId)
                    .neq('user_id', user.id)
                as List<dynamic>;

        if (otherUsers.isEmpty) {
          print(
            '🔴 Modul wird von keinem anderen User verwendet - lösche komplett...',
          );

          // Zuerst abhängige Daten löschen
          await _deleteDependentData(moduleId);

          // Dann das Modul selbst
          await _supabase.from('modules').delete().eq('id', moduleId);

          print('✅ Modul komplett aus der Datenbank gelöscht');
        } else {
          print(
            'ℹ️ Modul wird noch von anderen Usern verwendet - nur für diesen User entfernt',
          );
        }
      }

      // 5. Lokale Module-Liste aktualisieren
      await fetchModules();

      print('✅ Modul erfolgreich entfernt: $moduleTitle');
      return true;
    } catch (e) {
      error = 'Fehler beim Löschen des Moduls: $e';
      print('❌ Fehler beim Löschen: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Hilfsmethode zum Löschen abhängiger Daten (nur für nicht-standard Module)
  Future<void> _deleteDependentData(int moduleId) async {
    try {
      print('🗑️ Lösche abhängige Daten für Modul $moduleId...');

      // 1. Alle Submodules dieses Moduls finden
      final submodules =
          await _supabase
                  .from('submodules')
                  .select('id')
                  .eq('modules_id', moduleId)
              as List<dynamic>;

      final submoduleIds = submodules.map((s) => s['id']).toList();

      if (submoduleIds.isNotEmpty) {
        // 2. Alle Questions für diese Submodules finden
        final questions =
            await _supabase
                    .from('questions')
                    .select('id')
                    .inFilter('submodule_id', submoduleIds)
                as List<dynamic>;

        final questionIds = questions.map((q) => q['id']).toList();

        if (questionIds.isNotEmpty) {
          // 3. Options für diese Questions löschen
          await _supabase
              .from('options')
              .delete()
              .inFilter('question_id', questionIds);

          // 4. User card progress für diese Questions löschen
          await _supabase
              .from('user_card_progress')
              .delete()
              .inFilter('card_id', questionIds);

          // 5. Questions löschen
          await _supabase
              .from('questions')
              .delete()
              .inFilter('id', questionIds);
        }

        // 6. User submodule level progress löschen
        await _supabase
            .from('user_submodule_level_progress')
            .delete()
            .inFilter('submodule_id', submoduleIds);

        // 7. Submodules löschen
        await _supabase.from('submodules').delete().eq('modules_id', moduleId);
      }

      // 8. Learning sessions für dieses Modul löschen
      final submoduleIdsForSessions = submoduleIds.isNotEmpty
          ? submoduleIds
          : [0];
      await _supabase
          .from('learning_sessions')
          .delete()
          .inFilter('submodule_id', submoduleIdsForSessions);

      print('✅ Abhängige Daten gelöscht');
    } catch (e) {
      print('⚠️ Fehler beim Löschen abhängiger Daten: $e');
      // Wir fahren trotzdem fort
    }
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
