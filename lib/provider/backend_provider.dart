import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/core/constants/app_strings.dart';
import 'package:mc_trainer_kami/features/home/widgets/category_card.dart';
import 'package:mc_trainer_kami/features/home/widgets/quiz_card.dart';
import 'package:mc_trainer_kami/models/lernen_module.dart';
import 'package:mc_trainer_kami/models/statistics.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Avatar hochladen
import 'package:flutter/foundation.dart'; 
import 'package:mc_trainer_kami/models/achievement_data.dart';
import 'dart:async';

import '../models/app_notifications.dart';

import 'package:mc_trainer_kami/models/importable_module.dart';

class ResumeTarget {
  final int moduleId;
  final int submoduleId;
  final String moduleTitle;
  final String moduleDescription;
  final String submoduleTitle;

  ResumeTarget({
    required this.moduleId,
    required this.submoduleId,
    required this.moduleTitle,
    required this.moduleDescription,
    required this.submoduleTitle,
  });
}


extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}


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
  List<Statistics> userStatistics = [];

  // Listen & Status
  List<LernenModule> allModules = []; 
  List<LernenModule> lastModules = [];
  Map<String, dynamic>? lastSession;
  List<Achievement> myAchievements = [];
  List<AppNotification> notifications = [];
  //  Profil Daten
  String profileName = '';
  String profileEmail = '';
  String profileUsername = '';
  String? profileAvatarUrl;
  String profileCreatedAt = ''; // Mitglied seit Datum
  // Profil Statistiken
  int learnedHours = 0;
  int learnedMinutes = 0;
  double averageScore = 0.0;
  int totalQuestions = 0;

  bool isLoading = false; // Ladezustand
  String? error; // Fehlernachricht

  // Cache fuer Fortschritt und Submodule
  final Map<int, Map<String, dynamic>> _moduleProgressCache = {};
  DateTime? _moduleProgressCacheAt;
  String? _moduleProgressCacheUserId;
  final Duration _moduleProgressCacheTtl = const Duration(minutes: 10);
  final Map<int, List<Map<String, dynamic>>> _submodulesCache = {};
  final Map<int, double> _moduleProgressValueCache = {};
  final Map<int, DateTime> _moduleProgressValueCacheAt = {};
  final Map<int, double> _submoduleProgressCache = {};
  final Map<int, DateTime> _submoduleProgressCacheAt = {};
  final Map<int, bool> _submoduleCompletedCache = {};
  final Map<int, DateTime> _submoduleCompletedCacheAt = {};
  final Duration _progressValueCacheTtl = const Duration(minutes: 10);

  int get unreadNotificationsCount =>
      notifications.where((n) => !n.isRead).length;

  void _clearProgressCache() {
    _moduleProgressCache.clear();
    _moduleProgressCacheAt = null;
    _moduleProgressCacheUserId = null;
    _submodulesCache.clear();
    _moduleProgressValueCache.clear();
    _moduleProgressValueCacheAt.clear();
    _submoduleProgressCache.clear();
    _submoduleProgressCacheAt.clear();
    _submoduleCompletedCache.clear();
    _submoduleCompletedCacheAt.clear();
  }

  void invalidateProgressCache() {
    _clearProgressCache();
    notifyListeners();
  }

  bool _isCacheFresh(DateTime? cachedAt, Duration ttl) {
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt) < ttl;
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
    //  initiale Home-Daten laden
    fetchHomeData();
    fetchPoints();
    fetchNotifications();
    fetchAchievementsData();
    fetchUserStats();

    //  Auth-Status; beim Login/Logout ggf. Module nachladen
    try {
      _authSub = _supabase.auth.onAuthStateChange.listen((data) {
        debugPrint('Auth state changed: $data');
        // Nach Auth-Änderung Module neu laden
        fetchModules();
        fetchNotifications();
      });
    } catch (e) {
     
      debugPrint('Auth listener nicht registriert: $e');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future fetchUserStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final res =
          await _supabase
                  .from('learning_sessions')
                  .select(
                    'total_questions, correct_answered, incorrect_answered, iscompleted',
                  )
                  .eq('user_id', user.id)
              as List<dynamic>;

      if (res.isEmpty) return;

      userStatistics = res.map((row) {
        final data = row as Map<String, dynamic>;
        return Statistics(
          total_questions: data['total_questions'],
          correct_answered: data['correct_answered'],
          incorrect_answered: data['incorrect_answered'],
          session_success: data['iscompleted'],
        );
      }).toList();
    } catch (e) {
      debugPrint('User Statistics Error: $e');
    }
  }

  Future<void> addAchievementFirstVisit() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final sessions =
          await _supabase
                  .from('learning_sessions')
                  .select('id')
                  .eq('user_id', user.id)
                  .eq('iscompleted', true)
                  .limit(1)
              as List<dynamic>;

      if (sessions.isEmpty) return;

      final res = addAchievement(1);
      if (await res) {
        addNotification(
          'New Gift',
          'Congratulation: you won a new Price <First Visit>; You also upgraded your score',
        );
        fetchAchievementsData();
      }
    } catch (e) {
      debugPrint('addAchievementFirstVisit error: $e');
    }
  }

  Future<void> addAchievementWeekWarrior() async {
    final res = addAchievement(2);
    if (await res) {
      addNotification(
        'New Gift',
        'Congratulation: you won a new Price <Warrior>; You also upgraded your score',
      );
      fetchAchievementsData();
    }
  }

  Future<void> addAchievementPerfectScore() async {
    final res = addAchievement(3);
    if (await res) {
      addNotification(
        'New Gift',
        'Congratulation: you won a new Price <Perfect Score>; You also upgraded your score',
      );
      fetchAchievementsData();
    }
  }

  Future<void> addAchievementModuleMaster() async {
    final res = addAchievement(4);
    if (await res) {
      addNotification(
        'New Gift',
        'Congratulation: you won a new Price <Module Master>; You also upgraded your score',
      );
      fetchAchievementsData();
    }
  }

  Future<void> addAchievementTopOfClass() async {
    final res = addAchievement(5);
    if (await res) {
      addNotification(
        'New Gift',
        'Congratulation: you won a new Price <Top Of Class>; You also upgraded your score',
      );
      fetchAchievementsData();
    }
  }

  Future<bool> addAchievement(int achievementId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final res =
          await _supabase
                  .from('user_achievements')
                  .select('achievement_id')
                  .eq('user_id', user.id)
                  .eq('achievement_id', achievementId)
              as List<dynamic>;

      print('Achive--res: $res');
      if (res.isNotEmpty) {
        return false;
      } else {
        await _supabase
            .from('user_profiles')
            .update({'achieved_points': achievedPoint + (achievementId * 250)})
            .eq('id', user.id);

        await _supabase.from('user_achievements').insert({
          'user_id': user.id,
          //'unlocked_at': DateTime.now().toIso8601String(),
          'achievement_id': achievementId,
        });
      }
      await fetchPoints();
      await fetchNotifications();
    } catch (e) {
      debugPrint('addNotification error: $e');
    }
    return true;
  }

  Future<void> fetchNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final rows =
          await _supabase
                  .from('user_notifications')
                  .select('*')
                  .eq('user_id', user.id)
                  .order('created_at', ascending: false)
              as List<dynamic>;

      notifications = rows.map((row) {
        final data = row as Map<String, dynamic>;
        return AppNotification(
          id: data['id'],
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
        'created_at': DateTime.now().toIso8601String(),
      });

      await fetchNotifications();
    } catch (e) {
      debugPrint('addNotification error: $e');
    }
  }

  //setNotificationToRead
  Future<void> setNotificationToRead(int noteId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('user_notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('id', noteId);

      await fetchNotifications();
      notifyListeners();
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

  Future<void> clearAllNotification() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('user_notifications')
          .delete()
          .eq('user_id', user.id);

      for (final n in notifications) {
        n.isRead = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('delete All Notifification error: $e');
    }
  }

  //deleteNotification
  Future<void> deleteNotification(int noteId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('user_notifications').delete().eq('id', noteId);

      for (final n in notifications) {
        n.isRead = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('delete All Notifification error: $e');
    }
  }

  Future<void> fetchPoints() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final res = await _supabase
          .from('user_profiles')
          .select('achieved_points')
          .eq('id', user.id);

      achievedPoint = res[0]['achieved_points'] as int;
      notifyListeners();
    } catch (e) {
      debugPrint('delete All Notifification error: $e');
    }
  }

  
  double calculateProgress(Map<String, dynamic>? session) {
    if (session == null) return 0.0;
    final total = session['total_questions'] ?? 1;
    final correct = session['correct_answered'] ?? 0;
    return (correct / (total == 0 ? 1 : total)).clamp(0.0, 1.0);
  }

  

  Future<void> uploadAvatar(dynamic fileInput) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final userId = user.id;
      final filePath = 'user_$userId/avatar.png';

      if (kIsWeb) {
        
        await _supabase.storage
            .from('avatar_profile')
            .uploadBinary(
              filePath,
              fileInput as Uint8List,
              fileOptions: const FileOptions(upsert: true),
            );
      } else {
       
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
      
        avatarUrl = '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      print('Fehler beim Laden des Avatars: $e');
    }
    notifyListeners();
  }

  Future<void> deletePicture() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final userId = user.id;
      final filePath = 'user_$userId/avatar.png';

      try {
        await _supabase.storage.from('avatar_profile').remove([filePath]);
      } catch (storageError) {
        print('Storage Info: Datei existierte evtl. nicht mehr: $storageError');
      }

    
      await _supabase
          .from('user_profiles')
          .update({'avatar_url': null})
          .eq('id', userId);

      
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

        //  ERST aus user_profiles laden
        try {
          final profileResponse = await _supabase
              .from('user_profiles')
              .select('name, email, username')
              .eq('id', user.id)
              .maybeSingle();

          print('📊 Home Profil Response: $profileResponse');

          if (profileResponse != null && profileResponse['name'] != null) {
            //  Daten aus user_profiles
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
        await fetchModules();
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

     
      // --- Statistiken setzen ---
      questionsThisWeek = lastSession?['total_questions'] ?? 0;
     currentStreak = 7; 
       currentStreak = 7;
    } catch (e) {
      error = 'Daten konnten nicht geladen werden.$e';
      print('Fehler: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
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

        String title = e['title']?.toString() ?? '';
        String description = e['description']?.toString() ?? '';

        switch (achievementId) {
          case 1:
            title = 'Erster Start';
            description = 'Starte deine erste Lernrunde in mc‑Trainer';
            break;
          case 2:
            title = 'Krieger';
            description = 'Schließe 10 Lektionen ab';
            break;
          case 3:
            title = 'Perfekte Punktzahl';
            description = 'Erreiche 100% in einem Quiz';
            break;
          case 4:
            title = 'Meister';
            description = 'Beantworte 30 Fragen';
            break;
          case 5:
            title = 'Spitzenklasse';
            description = 'Erreiche 1500 Punkte';
            break;
        }

        final iconIndex = achievementId - 1;
        final icon = (iconIndex >= 0 && iconIndex < achievementsIcon.length)
            ? achievementsIcon[iconIndex]
            : Icons.emoji_events;
        final color = (iconIndex >= 0 && iconIndex < achievementsColor.length)
            ? achievementsColor[iconIndex]
            : Colors.amber;

        myAchievements.add(
          Achievement(
            id: e['id'],
            title: title,
            description: description,
            icon: icon,
            color: color,
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

  
  //  Profil Daten abrufen
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

        
        if (profileName.isEmpty) {
          final fullName = user.userMetadata?['full_name'];
          profileName = (fullName != null && fullName.isNotEmpty)
              ? fullName
              : user.email?.split('@').first.capitalize() ?? 'User';
        }
      } else {
        print(' Kein Profil gefunden, setze Standardwerte');
        
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
        int totalDurationMinutes = 0;

        for (var session in sessionsResponse) {
          totalQuestions += (session['total_questions'] as int?) ?? 0;
          correctAnswers += (session['correct_answered'] as int?) ?? 0;
          final durationMinutes =
              (session['timer_duration_minutes'] as int?) ?? 0;
          totalDurationMinutes += durationMinutes;
        }

        this.totalQuestions = totalQuestions;
        learnedMinutes = totalDurationMinutes;
        learnedHours = (totalDurationMinutes / 60).floor();
        averageScore = totalQuestions > 0
            ? (correctAnswers / totalQuestions * 100)
            : 0.0;
      }

         try {
        final completedSessions = await _supabase
            .from('learning_sessions')
            .select('submodules_id')
            .eq('user_id', userId)
            .eq('iscompleted', true);

        final completedIds = completedSessions
            .map((row) => row['submodules_id'])
            .whereType<int>()
            .toSet();

        modulesCompleted = completedIds.length;
      } catch (e) {
        print('Keine completed sessions für User $userId gefunden: $e');
        modulesCompleted = 0;
      }
    } catch (e) {
      print('Fehler beim Berechnen der Profil-Statistiken: $e');
    }
  }

  //  Statistiken für HomeScreen berechnen
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

      //  ob Email geändert wurde
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

  
  Future<void> fetchModules() async {
    isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;

       if (user == null) {
        final defaultModules =
            await _supabase.from('modules').select('*').eq('default', true)
                as List<dynamic>;

        lastModules = defaultModules.map((e) {
          final m = e as Map<String, dynamic>;
          return LernenModule(
            id: m['id'] as int,
            name: (m['title'] ?? '').toString(),
            description: (m['description'] ?? '').toString(),
          );
        }).toList();

        return;
      }

      final deletedModules =
          await _supabase
                  .from('deleted_modules')
                  .select('module_id')
                  .eq('user_id', user.id)
              as List<dynamic>;

      final deletedIds = deletedModules
          .map((dm) => dm['module_id'] as int)
          .toSet();

      
      final importedModules =
          await _supabase
                  .from('imported_modules')
                  .select('module_id')
                  .eq('user_id', user.id)
                  .eq('is_deleted', false)
              as List<dynamic>;

      final importedIds = importedModules
          .map((im) => im['module_id'] as int)
          .toSet();

      
      final defaultModules =
          await _supabase.from('modules').select('*').eq('default', true)
              as List<dynamic>;

      
      List<dynamic> importedModulesData = [];
      if (importedIds.isNotEmpty) {
        importedModulesData =
            await _supabase
                    .from('modules')
                    .select('*')
                    .inFilter('id', importedIds.toList())
                as List<dynamic>;
      }

      
      final combined = <int, Map<String, dynamic>>{};

      
      for (final e in defaultModules) {
        final m = e as Map<String, dynamic>;
        final id = m['id'] as int;
        if (!deletedIds.contains(id)) {
          combined[id] = m;
        }
      }

      
      for (final e in importedModulesData) {
        final m = e as Map<String, dynamic>;
        final id = m['id'] as int;
        combined[id] = m;
      }

      
      lastModules = combined.values.map((e) {
        final m = e as Map<String, dynamic>;
        return LernenModule(
          id: m['id'] as int,
          name: (m['title'] ?? '').toString(),
          description: (m['description'] ?? '').toString(),
        );
      }).toList();

      debugPrint(
        '✅ Module geladen: ${lastModules.map((m) => m.name).toList()}',
      );
      debugPrint('📊 Statistik: ${lastModules.length} Module total');
      debugPrint('   - Default Module: ${defaultModules.length}');
      debugPrint('   - Importierte Module: ${importedModulesData.length}');
      debugPrint('   - Gelöschte IDs: ${deletedIds.length}');
    } catch (e) {
      error = 'Konnte Module nicht laden: $e';
      print('❌ Fehler in fetchModules: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reImportModule(int moduleId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      
      await _supabase
          .from('deleted_modules')
          .delete()
          .eq('user_id', user.id)
          .eq('module_id', moduleId);

      
      await _supabase
          .from('imported_modules')
          .update({'is_deleted': false, 'deleted_at': null})
          .eq('user_id', user.id)
          .eq('module_id', moduleId);

   
      await fetchModules();
      await fetchImportableModules();

      return true;
    } catch (e) {
      print('❌ Re-Import Fehler: $e');
      return false;
    }
  }

    Future<double> calculateModuleProgress(dynamic moduleId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0.0;

      if (_moduleProgressCacheUserId != user.id) {
        _clearProgressCache();
        _moduleProgressCacheUserId = user.id;
      }

      if (moduleId is int) {
        final cachedAt = _moduleProgressValueCacheAt[moduleId];
        if (_moduleProgressValueCache.containsKey(moduleId) &&
            _isCacheFresh(cachedAt, _progressValueCacheTtl)) {
          return _moduleProgressValueCache[moduleId]!;
        }
      }

      
      final submodules = await fetchSubmodules(moduleId);
      if (submodules.isEmpty) return 0.0;

      int completedSubmodules = 0;

      
      for (var submodule in submodules) {
        final submoduleId = submodule['id'];
        final isCompleted = await isSubmoduleCompleted(submoduleId);
        if (isCompleted) {
          completedSubmodules++;
        }
      }

      
      final progress = (completedSubmodules / submodules.length);
      debugPrint(
        '📊 Module $moduleId: $completedSubmodules/${submodules.length} submodules completed = ${(progress * 100).toStringAsFixed(1)}%',
      );

      if (moduleId is int) {
        _moduleProgressValueCache[moduleId] = progress;
        _moduleProgressValueCacheAt[moduleId] = DateTime.now();
      }

      return progress;
    } catch (e) {
      debugPrint('❌ Error calculating module progress: $e');
      return 0.0;
    }
  }
 Future<double> calculateSubmoduleProgress(dynamic submoduleId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0.0;

     
      final questionsResponse =
          await _supabase
                  .from('questions')
                  .select('id')
                  .eq('submodule_id', submoduleId)
              as List<dynamic>;

      if (questionsResponse.isEmpty) return 0.0;

      if (_moduleProgressCacheUserId != user.id) {
        _clearProgressCache();
        _moduleProgressCacheUserId = user.id;
      }

      if (submoduleId is int) {
        final cachedAt = _submoduleProgressCacheAt[submoduleId];
        if (_submoduleProgressCache.containsKey(submoduleId) &&
            _isCacheFresh(cachedAt, _progressValueCacheTtl)) {
          return _submoduleProgressCache[submoduleId]!;
        }
      }

      
      final submoduleCheck =
          await _supabase
                  .from('submodules')
                  .select('iscompleted')
                  .eq('id', submoduleId)
              as List<dynamic>;

      if (submoduleCheck.isNotEmpty) {
        final isCompleted = submoduleCheck.first['iscompleted'] as bool?;
        if (isCompleted == true) {
          if (submoduleId is int) {
            _submoduleProgressCache[submoduleId] = 1.0;
            _submoduleProgressCacheAt[submoduleId] = DateTime.now();
          }
          return 1.0;
        }
      }

    
      final bestSession =
          await _supabase
                  .from('learning_sessions')
                  .select('accuracy_percentage')
                  .eq('user_id', user.id)
                  .eq('submodules_id', submoduleId)
                  .order('accuracy_percentage', ascending: false)
                  .limit(1)
                  .maybeSingle()
              as Map<String, dynamic>?;

      if (bestSession != null && bestSession['accuracy_percentage'] != null) {
        final accuracy = (bestSession['accuracy_percentage'] as num).toDouble();
        final progress = (accuracy / 100.0).clamp(0.0, 1.0);
        debugPrint(
          '📊 Submodule $submoduleId: best accuracy = ${accuracy.toStringAsFixed(1)}%',
        );
        if (submoduleId is int) {
          _submoduleProgressCache[submoduleId] = progress;
          _submoduleProgressCacheAt[submoduleId] = DateTime.now();
        }
        return progress;
      }

      
      final levelProgressList =
          await _supabase
                  .from('user_submodule_level_progress')
                  .select('total_cards_in_level,cards_answered,cards_mastered')
                  .eq('user_id', user.id)
                  .eq('submodule_id', submoduleId)
              as List<dynamic>;

      if (levelProgressList.isNotEmpty) {
        int totalCards = 0;
        int answeredCards = 0;

        for (final level in levelProgressList) {
          final total = (level['total_cards_in_level'] as int?) ?? 0;
          if (total <= 0) continue;
          totalCards += total;
          final answered =
              (level['cards_answered'] as int?) ??
              (level['cards_mastered'] as int?) ??
              0;
          answeredCards += answered;
        }

        if (totalCards > 0) {
          final progress = (answeredCards / totalCards).clamp(0.0, 1.0);
          debugPrint(
            '📊 Submodule $submoduleId: $answeredCards/$totalCards answered = ${(progress * 100).toStringAsFixed(1)}%',
          );
          if (submoduleId is int) {
            _submoduleProgressCache[submoduleId] = progress;
            _submoduleProgressCacheAt[submoduleId] = DateTime.now();
          }
          return progress;
        }
      }

        
        final questionIds = questionsResponse.map((c) => c['id']).toList();
      debugPrint(
        '📊 Submodule $submoduleId: ${questionIds.length} total questions',
      );

      final userProgressResponse =
          await _supabase
                  .from('user_card_progress')
                  .select('question_id')
                  .eq('user_id', user.id)
              as List<dynamic>;

      final answeredCount = userProgressResponse
          .where((p) => questionIds.contains(p['question_id']))
          .length;

      final progress = answeredCount / questionIds.length;
      debugPrint(
        '📊 Submodule $submoduleId: $answeredCount/${questionIds.length} answered = ${(progress * 100).toStringAsFixed(1)}%',
      );

      if (submoduleId is int) {
        _submoduleProgressCache[submoduleId] = progress;
        _submoduleProgressCacheAt[submoduleId] = DateTime.now();
      }
      return progress;
    } catch (e) {
      debugPrint('❌ Error calculating submodule progress: $e');
      return 0.0;
    }
  }

  
  Future<double> calculateLevelProgress(
    dynamic submoduleId,
    int levelNumber,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0.0;

      
      final levelProgress =
          await _supabase
                  .from('user_submodule_level_progress')
                  .select('*')
                  .eq('user_id', user.id)
                  .eq('submodule_id', submoduleId)
                  .eq('level_number', levelNumber)
                  .maybeSingle()
              as Map<String, dynamic>?;

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

  Future<Map<int, Map<String, dynamic>>> loadUserProgressForModules(
    List<LernenModule> modules,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {};

      if (_moduleProgressCacheUserId != user.id) {
        _clearProgressCache();
        _moduleProgressCacheUserId = user.id;
      }

      final moduleIds = modules.map((m) => m.id).whereType<int>().toList();
      final cacheFresh = _isCacheFresh(
        _moduleProgressCacheAt,
        _moduleProgressCacheTtl,
      );
      if (cacheFresh &&
          _moduleProgressCache.keys.toSet().containsAll(moduleIds)) {
        return {for (final id in moduleIds) id: _moduleProgressCache[id]!};
      }

      debugPrint('🔄 Lade Fortschritte für ${modules.length} Module...');

      final Map<int, Map<String, dynamic>> moduleProgressMap = {};

      final List<LernenModule> missingModules = [];
      if (cacheFresh) {
        for (final module in modules) {
          final moduleId = module.id;
          if (moduleId is int && _moduleProgressCache.containsKey(moduleId)) {
            moduleProgressMap[moduleId] = _moduleProgressCache[moduleId]!;
          } else if (moduleId is int) {
            missingModules.add(module);
          }
        }
      } else {
        missingModules.addAll(modules.where((m) => m.id is int));
      }

      if (missingModules.isNotEmpty) {
        final results = await Future.wait(
          missingModules.map((module) async {
            final moduleId = module.id as int;

            final submodules = await fetchSubmodules(moduleId);
            final submoduleEntries = await Future.wait(
              submodules.map((submodule) async {
                final submoduleId = submodule['id'];
                final submoduleProgress =
                    await calculateSubmoduleProgress(submoduleId);
                final isCompleted =
                    await isSubmoduleCompleted(submoduleId);

                final levelProgressList =
                    await _supabase
                            .from('user_submodule_level_progress')
                            .select('*')
                            .eq('user_id', user.id)
                            .eq('submodule_id', submoduleId)
                            .order('level_number', ascending: true)
                        as List<dynamic>;

                return MapEntry<int, Map<String, dynamic>>(
                  submoduleId as int,
                  {
                    'progress': submoduleProgress,
                    'is_completed': isCompleted,
                    'levels': levelProgressList,
                  },
                );
              }).toList(),
            );

            final submoduleProgressMap =
                Map<int, Map<String, dynamic>>.fromEntries(submoduleEntries);

            final completedCount = submoduleProgressMap.values
              .where((entry) => entry['is_completed'] == true)
              .length;
            final progress = submodules.isEmpty
              ? 0.0
              : (completedCount / submodules.length).clamp(0.0, 1.0);

            _moduleProgressValueCache[moduleId] = progress;
            _moduleProgressValueCacheAt[moduleId] = DateTime.now();

            debugPrint(
              '✅ Module $moduleId geladen: ${(progress * 100).toStringAsFixed(1)}% Fortschritt',
            );

            return MapEntry<int, Map<String, dynamic>>(
              moduleId,
              {
                'progress': progress,
                'submodules': submoduleProgressMap,
              },
            );
          }).toList(),
        );

        for (final entry in results) {
          moduleProgressMap[entry.key] = entry.value;
        }
      }

      debugPrint('✅ Alle Fortschritte geladen!');
      _moduleProgressCache
        ..clear()
        ..addAll(moduleProgressMap);
      _moduleProgressCacheAt = DateTime.now();
      _moduleProgressCacheUserId = user.id;
      return moduleProgressMap;
    } catch (e) {
      debugPrint('❌ Error loading user progress: $e');
      error = 'Konnte Fortschritte nicht laden: $e';
      notifyListeners();
      return {};
    }
  }

  
  Future<void> updateModuleProgress(dynamic moduleId) async {
    try {
      debugPrint('🔄 Aktualisiere Fortschritt für Modul $moduleId...');
      if (moduleId is int) {
        _moduleProgressValueCache.remove(moduleId);
        _moduleProgressValueCacheAt.remove(moduleId);
        _moduleProgressCache.remove(moduleId);
      }
      final progress = await calculateModuleProgress(moduleId);
      debugPrint(
        '✅ Modul $moduleId: ${(progress * 100).toStringAsFixed(1)}% Fortschritt',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating module progress: $e');
    }
  }

  /// Aktualisiert ein einzelnes Submodul mit seinem Fortschritt aus der Datenbank
  Future<void> updateSubmoduleProgress(dynamic submoduleId) async {
    try {
      debugPrint('🔄 Aktualisiere Fortschritt für Submodul $submoduleId...');
      if (submoduleId is int) {
        _submoduleProgressCache.remove(submoduleId);
        _submoduleProgressCacheAt.remove(submoduleId);
        _submoduleCompletedCache.remove(submoduleId);
        _submoduleCompletedCacheAt.remove(submoduleId);
      }
      final progress = await calculateSubmoduleProgress(submoduleId);
      debugPrint(
        '✅ Submodul $submoduleId: ${(progress * 100).toStringAsFixed(1)}% Fortschritt',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating submodule progress: $e');
    }
  }

  /// Lädt alle Fortschritte neu aus der Datenbank (nach Benutzeraktion)
  Future<void> refreshAllProgress() async {
    try {
      debugPrint('🔄 Aktualisiere alle Fortschritte...');
      _clearProgressCache();
      await loadUserProgressForModules(lastModules);
      debugPrint('✅ Alle Fortschritte aktualisiert');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing progress: $e');
      error = 'Konnte Fortschritte nicht aktualisieren: $e';
      notifyListeners();
    }
  }

  Future<int?> _getNextSubmoduleId(int moduleId, int currentSubmoduleId) async {
    try {
      final subs =
          await _supabase
                  .from('submodules')
                  .select('id, level')
                  .eq('modules_id', moduleId)
                    .order('level', ascending: true)
                  .order('id', ascending: true)
              as List<dynamic>;

      final ids = subs.map((e) => e['id'] as int).toList();
      final idx = ids.indexOf(currentSubmoduleId);
      if (idx == -1) return null;
      if (idx + 1 >= ids.length) return null;
      return ids[idx + 1];
    } catch (e) {
      debugPrint('Fehler beim Ermitteln des nächsten Submodules: $e');
      return null;
    }
  }

  Future<ResumeTarget?> getResumeTarget() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final sessions =
          await _supabase
                  .from('learning_sessions')
                  .select('submodules_id, start_time, end_time')
                  .eq('user_id', user.id)
                    .order('end_time', ascending: false)
                  .order('start_time', ascending: false)
                  .limit(1)
              as List<dynamic>;

      if (sessions.isEmpty) return null;
      final session = sessions.first as Map<String, dynamic>;
      final submoduleId = session['submodules_id'] as int?;
      if (submoduleId == null) return null;

        final submodule =
          await _supabase
              .from('submodules')
              .select('id, modules_id')
              .eq('id', submoduleId)
              .maybeSingle()
            as Map<String, dynamic>?;
      if (submodule == null) return null;

      final moduleId = submodule['modules_id'] as int?;
      if (moduleId == null) return null;

      var resumeSubmoduleId = submoduleId;
      final progress = await calculateSubmoduleProgress(submoduleId);
      if (progress >= 0.8) {
        final nextId = await _getNextSubmoduleId(moduleId, submoduleId);
        if (nextId != null) {
          resumeSubmoduleId = nextId;
        }
      }

      final resumeSubmodule =
          await _supabase
                  .from('submodules')
                  .select('id, title')
                  .eq('id', resumeSubmoduleId)
                  .maybeSingle()
              as Map<String, dynamic>?;
      if (resumeSubmodule == null) return null;

      final module =
          await _supabase
                  .from('modules')
                  .select('id, title, description')
                  .eq('id', moduleId)
                  .maybeSingle()
              as Map<String, dynamic>?;
      if (module == null) return null;

      return ResumeTarget(
        moduleId: moduleId,
        submoduleId: resumeSubmoduleId,
        moduleTitle: (module['title'] ?? '').toString(),
        moduleDescription: (module['description'] ?? '').toString(),
        submoduleTitle: (resumeSubmodule['title'] ?? '').toString(),
      );
    } catch (e) {
      debugPrint('Fehler beim Laden des Resume-Targets: $e');
      return null;
    }
  }

  /// Gibt eine detaillierte Fortschritts-Zusammenfassung für ein Submodule zurück
  Future<Map<String, dynamic>> getSubmoduleProgressSummary(
    dynamic submoduleId,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {};

      final progress = await calculateSubmoduleProgress(submoduleId);
      final isCompleted = await isSubmoduleCompleted(submoduleId);

      // Lade Level-Details
      final levelProgressList =
          await _supabase
                  .from('user_submodule_level_progress')
                  .select('*')
                  .eq('user_id', user.id)
                  .eq('submodule_id', submoduleId)
                  .order('level_number', ascending: true)
              as List<dynamic>;

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
  Future<Map<String, dynamic>> getModuleProgressSummary(
    dynamic moduleId,
  ) async {
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
    learnedMinutes = 0;
    averageScore = 0.0;
    totalQuestions = 0;

    isLoading = false;
    error = null;
    _clearProgressCache();

    notifyListeners();
  }

  // --- Submodule laden ---
  Future<List<Map<String, dynamic>>> fetchSubmodules(dynamic moduleId) async {
    try {
      final moduleKey = moduleId is int ? moduleId : int.tryParse(moduleId.toString() ?? '');
      if (moduleKey != null) {
        final cached = _submodulesCache[moduleKey];
        if (cached != null) return cached;
      }

      final subs =
          await _supabase
                  .from('submodules')
                  .select('*')
                  .eq('modules_id', moduleId)
              as List<dynamic>;
      final result = subs.map((e) => e as Map<String, dynamic>).toList();
      if (moduleKey != null) {
        _submodulesCache[moduleKey] = result;
      }
      return result;
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
      _clearProgressCache();
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
      _clearProgressCache();
    } catch (e) {
      debugPrint('deleteSubmodules error: $e');
    }
  }

  Future<bool> isSubmoduleCompleted(dynamic submoduleId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final questions =
          await _supabase
                  .from('questions')
                  .select('id')
                  .eq('submodule_id', submoduleId)
              as List<dynamic>;
      if (questions.isEmpty) return false;

      if (_moduleProgressCacheUserId != user.id) {
        _clearProgressCache();
        _moduleProgressCacheUserId = user.id;
      }

      if (submoduleId is int) {
        final cachedAt = _submoduleCompletedCacheAt[submoduleId];
        if (_submoduleCompletedCache.containsKey(submoduleId) &&
            _isCacheFresh(cachedAt, _progressValueCacheTtl)) {
          return _submoduleCompletedCache[submoduleId]!;
        }
      }

    
      final submoduleCheck =
          await _supabase
                  .from('submodules')
                  .select('iscompleted')
                  .eq('id', submoduleId)
              as List<dynamic>;

      if (submoduleCheck.isNotEmpty) {
        final isCompleted = submoduleCheck.first['iscompleted'] as bool?;
        if (isCompleted == true) {
          debugPrint(
            '✅ Submodule $submoduleId: Bereits als completed markiert',
          );
          if (submoduleId is int) {
            _submoduleCompletedCache[submoduleId] = true;
            _submoduleCompletedCacheAt[submoduleId] = DateTime.now();
          }
          return true;
        }
      }

      // Prüfe beste Session-Accuracy
      final bestSession =
          await _supabase
                  .from('learning_sessions')
                  .select('accuracy_percentage')
                  .eq('user_id', user.id)
                  .eq('submodules_id', submoduleId)
                  .order('accuracy_percentage', ascending: false)
                  .limit(1)
                  .maybeSingle()
              as Map<String, dynamic>?;

      if (bestSession != null && bestSession['accuracy_percentage'] != null) {
        final accuracy = (bestSession['accuracy_percentage'] as num).toDouble();
        if (accuracy >= 80.0) {
          debugPrint(
            '✅ Submodule $submoduleId: best accuracy ${accuracy.toStringAsFixed(1)}%',
          );
          if (submoduleId is int) {
            _submoduleCompletedCache[submoduleId] = true;
            _submoduleCompletedCacheAt[submoduleId] = DateTime.now();
          }
          return true;
        }
      }

    
      final cards =
          await _supabase
                  .from('questions')
                  .select('id')
                  .eq('submodule_id', submoduleId)
              as List<dynamic>;

      if (cards.isEmpty) return true;

      final cardIds = cards.map((c) => c['id']).toList();

      
      final userProgress =
          await _supabase
                  .from('user_card_progress')
                  .select('question_id,is_mastered')
                  .eq('user_id', user.id)
              as List<dynamic>;

      final masteredCount = userProgress
          .where(
            (p) =>
                (p['is_mastered'] == true) &&
                cardIds.contains(p['question_id']),
          )
          .length;

      
      final completion = (masteredCount / cardIds.length) * 100;
      debugPrint(
        '✅ Submodule $submoduleId: $masteredCount/${cardIds.length} mastered = ${completion.toStringAsFixed(1)}%',
      );
      final completed = completion >= 80.0;
      if (submoduleId is int) {
        _submoduleCompletedCache[submoduleId] = completed;
        _submoduleCompletedCacheAt[submoduleId] = DateTime.now();
      }
      return completed;
    } catch (e) {
      debugPrint('❌ Error checking submodule completion: $e');
      return false;
    }
  }

 
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

      
      final mastered =
          await _supabase
                  .from('user_card_progress')
                  .select('question_id')
                  .eq('user_id', user.id)
                  .eq('is_mastered', true)
              as List<dynamic>;

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
  Future<Set<int>> getMasteredQuestionIdsForSubmodule(
    dynamic submoduleId,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {};

      final questions =
          await _supabase
                  .from('questions')
                  .select('id')
                  .eq('submodule_id', submoduleId)
              as List<dynamic>;

      if (questions.isEmpty) return {};

      final questionIds = questions.map((q) => q['id']).toSet();

      final mastered =
          await _supabase
                  .from('user_card_progress')
                  .select('question_id')
                  .eq('user_id', user.id)
                  .eq('is_mastered', true)
              as List<dynamic>;

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

      final insert =
          await _supabase.from('learning_sessions').insert({
                'user_id': user.id,
                'start_time': DateTime.now()
                    .add(const Duration(hours: 1))
                    .toIso8601String(),
                'total_questions': 0,
                'correct_answered': 0,
                'incorrect_answered': 0,
                'accuracy_percentage': 0,
                'status': 'active',
                'timer_duration_minutes': 0,
                'submodules_id': int.parse(submoduleId.toString()),
              }).select()
              as List<dynamic>;

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
        debugPrint(
          '✅ Submodule Link gespeichert: Session=$sessionId, Submodule=$submoduleId',
        );
      }

      lastSession = session;
      await addAchievement(1); // First Visit: beim Start der ersten Lernrunde
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

      debugPrint(
        '✅ finishLearningSession: sessionId=$sessionId, total=$total, correct=$correct, duration=${durationMinutes}min, accuracy=$accuracy%',
      );

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

      debugPrint(
        '✅ Session saved to database with duration: $durationMinutes minutes',
      );

      if (accuracy >= 80) {
        await markSubmoduleAsCompleted(submoduleId);

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
        debugPrint(
          '⚠️ Nur $accuracy% erreicht - Submodule nicht als completed markiert (benötigt 80%)',
        );
      }

      await _checkAndUnlockAchievements(accuracy: accuracy);

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

  Future<void> _checkAndUnlockAchievements({required int accuracy}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final sessions = await _supabase
          .from('learning_sessions')
          .select('total_questions, iscompleted, submodules_id')
          .eq('user_id', user.id) as List<dynamic>;

      int totalQuestions = 0;
      final completedSubmodules = <int>{};
      for (final s in sessions) {
        totalQuestions += (s['total_questions'] as int?) ?? 0;
        if (s['iscompleted'] == true) {
          final subId = s['submodules_id'];
          if (subId is int) completedSubmodules.add(subId);
        }
      }

      if (accuracy == 100) {
        await addAchievement(3); // Perfect Score
      }

      if (completedSubmodules.length >= 10) {
        await addAchievement(2); // Warrior
      }

      if (totalQuestions >= 30) {
        await addAchievement(4); // Master
      }

      final profile = await _supabase
          .from('user_profiles')
          .select('achieved_points')
          .eq('id', user.id)
          .maybeSingle();
      final currentPoints = (profile?['achieved_points'] as int?) ?? 0;
      if (currentPoints >= 1500) {
        await addAchievement(5); // Top of Class
      }
    } catch (e) {
      debugPrint('_checkAndUnlockAchievements error: $e');
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

      // berechnen Level-Fortschritt und evtl. freischalten
      await _recalculateSubmoduleLevelProgressForCard(cardId, user.id);
      notifyListeners();
    } catch (e) {
      error = 'Konnte Antwort nicht speichern: $e';
      notifyListeners();
    }
  }

  //  Hilfsfunktion: Level-Fortschritt neu berechnen und ggf. freischalten
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

  // Clear-Methode für Logout
  void clearData() {
    reset();
  }
  
  

  Future<void> fetchImportableModules() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      print('🔍 Lade importierbare Module für User: ${user.id}');

      
      final allNonDefaultModules =
          await _supabase.from('modules').select('*').eq('default', false)
              as List<dynamic>;

     
      final importedEntries =
          await _supabase
                  .from('imported_modules')
                  .select('module_id, is_deleted, server_url, download_count')
                  .eq('user_id', user.id)
              as List<dynamic>;

     
      final importStatus = <int, Map<String, dynamic>>{};
      for (var entry in importedEntries) {
        final e = entry as Map<String, dynamic>;
        final moduleId = e['module_id'] as int;
        importStatus[moduleId] = {
          'is_imported': true,
          'is_deleted': (e['is_deleted'] as bool?) ?? false,
          'server_url': e['server_url'] as String?,
          'download_count': e['download_count'] as int? ?? 1,
        };
      }

     
      availableModules.clear();

      for (var dbModule in allNonDefaultModules) {
        final moduleMap = dbModule as Map<String, dynamic>;
        final int moduleId = moduleMap['id'] as int;
        final String title = moduleMap['title'] as String;
        final String description = moduleMap['description'] as String? ?? '';
        final String icon = moduleMap['icon'] as String? ?? 'book';
        final String color = moduleMap['color'] as String? ?? '#4285F4';

        final status = importStatus[moduleId];
        final bool isImported = status != null;
        final bool isDeleted = status?['is_deleted'] == true;

        availableModules.add(
          ImportableModule(
            id: moduleId,
            title: title,
            description: description,
            icon: icon,
            color: color,
            isDefault: false,
            isImported:
                isImported &&
                !isDeleted, // Gelöschte zählen nicht als importiert
            isDeleted: isDeleted,
            serverUrl:
                status?['server_url'] as String? ??
                'https://trainingserver.example.com',
          ),
        );
      }

      // Sortierung
      availableModules.sort((a, b) {
        if (a.isDeleted != b.isDeleted) return a.isDeleted ? 1 : -1;
        if (a.isImported != b.isImported) return a.isImported ? 1 : -1;
        return a.title.compareTo(b.title);
      });

      print('✅ ${availableModules.length} importierbare Module geladen');
    } catch (e) {
      error = 'Konnte importierbare Module nicht laden: $e';
      print('❌ Fehler: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

 
  Future<bool> importModule(ImportableModule module) async {
    isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      print('🔄 Importiere Modul: ${module.title}');

      // Prüfe ob bereits ein Import-Eintrag existiert
      final existingImport =
          await _supabase
                  .from('imported_modules')
                  .select('id, is_deleted, download_count')
                  .eq('user_id', user.id)
                  .eq('module_id', module.id)
                  .maybeSingle()
              as Map<String, dynamic>?;

      if (existingImport == null) {
        // Neuen Import erstellen
        await _supabase.from('imported_modules').insert({
          'module_id': module.id,
          'user_id': user.id,
          'server_url': module.serverUrl,
          'download_count': 1,
          'is_deleted': false,
          'imported_at': DateTime.now().toIso8601String(),
        });
        print('✅ Neuer Import erstellt');
      } else {
        // Bestehenden Import aktualisieren
        final isCurrentlyDeleted =
            (existingImport['is_deleted'] as bool?) == true;
        final currentCount = (existingImport['download_count'] as int?) ?? 0;

        if (isCurrentlyDeleted) {
          // Re-Import eines gelöschten Moduls
          await _supabase
              .from('imported_modules')
              .update({
                'is_deleted': false,
                'deleted_at': null,
                'download_count': currentCount + 1,
                'imported_at': DateTime.now().toIso8601String(),
              })
              .eq('id', existingImport['id']);
          print('✅ Gelöschtes Modul re-importiert');
        } else {
          
          await _supabase
              .from('imported_modules')
              .update({
                'download_count': currentCount + 1,
                'imported_at': DateTime.now().toIso8601String(),
              })
              .eq('id', existingImport['id']);
          print('✅ Download-Count erhöht');
        }
      }

      // Module-Listen aktualisieren
      await fetchImportableModules();
      await fetchModules();

      return true;
    } catch (e) {
      error = 'Import fehlgeschlagen: $e';
      print('❌ Import-Fehler: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

 
  Future<List<Map<String, dynamic>>> _simulateExternalServerCall() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [];
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

  

  Future<bool> isModuleAvailableToUser(int moduleId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      
      final deleted =
          await _supabase
                  .from('deleted_modules')
                  .select('id')
                  .eq('module_id', moduleId)
                  .eq('user_id', user.id)
                  .maybeSingle()
              as Map<String, dynamic>?;

      if (deleted != null) {
        print(
          '⚠️ Modul $moduleId wurde von diesem User gelöscht - nicht verfügbar',
        );
        return false;
      }

      
      final module =
          await _supabase
                  .from('modules')
                  .select('default, title')
                  .eq('id', moduleId)
                  .maybeSingle()
              as Map<String, dynamic>?;

      if (module == null) return false;

      final bool isDefault = (module['default'] as bool?) == true;

      if (isDefault) {
        
        return true;
      } else {
        
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

  
  Future<bool> deleteModule(int moduleId, String moduleTitle) async {
    isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      print('🗑️ Lösche Modul: $moduleTitle');

         final isDefault = await isModuleDefault(moduleId);

      if (isDefault) {
       
        await _supabase.from('deleted_modules').insert({
          'module_id': moduleId,
          'user_id': user.id,
          'deleted_at': DateTime.now().toIso8601String(),
        });
        print('✅ Standard-Modul für User versteckt');
      } else {
       
        final importEntry =
            await _supabase
                    .from('imported_modules')
                    .select('id')
                    .eq('user_id', user.id)
                    .eq('module_id', moduleId)
                    .maybeSingle()
                as Map<String, dynamic>?;

        if (importEntry != null) {
          await _supabase
              .from('imported_modules')
              .update({
                'is_deleted': true,
                'deleted_at': DateTime.now().toIso8601String(),
              })
              .eq('id', importEntry['id']);
          print('✅ Importiertes Modul soft-gelöscht');
        }
      }

      // Listen aktualisieren
      await fetchModules();
      await fetchImportableModules();

      return true;
    } catch (e) {
      error = 'Löschen fehlgeschlagen: $e';
      print('❌ Lösch-Fehler: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
