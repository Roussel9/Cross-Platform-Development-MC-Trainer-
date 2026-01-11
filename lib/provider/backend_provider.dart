import 'package:flutter/foundation.dart';  // Fügt kDebugMode hinzu
import 'package:flutter/material.dart';
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/core/constants/app_strings.dart';
import 'package:mc_trainer_kami/features/home/widgets/category_card.dart';
import 'package:mc_trainer_kami/features/home/widgets/quiz_card.dart';
import 'package:mc_trainer_kami/models/lernen_module.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../provider/backend_provider.dart';

// Extension zur Großschreibung von Strings
extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}

// --- Backend Provider ---
class BackendProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  String userName = '';       // Vollständiger Name des Benutzers
  String userInitials = '';         // Initialen für Avatar
  int questionsThisWeek = 0;          // Anzahl der Fragen diese Woche
  int currentStreak = 0;              // Aktuelle Serie (Streak)
  int modulesCompleted = 0;           // Anzahl abgeschlossener Module

  List<LernenModule> lastModules = [];           // Letzte Module
  Map<String, dynamic>? lastSession;            // Letzte Session
  List<Map<String, dynamic>> achievements = []; // Errungenschaften

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

  bool isLoading = false;           // Ladezustand
  String? error;                    // Fehlernachricht

  // Konstruktor lädt direkt die Home-Daten
  BackendProvider() {
    fetchHomeData();
  }

  // Berechnung des Fortschritts einer Session
  double calculateProgress(Map<String, dynamic>? session) {
    if (session == null) return 0.0;
    final total = session['total_questions'] ?? 1;
    final correct = session['correct_answered'] ?? 0;
    return (correct / total).clamp(0.0, 1.0);
  }

  // --- Daten für Home Screen abrufen ---
  Future<void> fetchHomeData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;

      if (user != null) {
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

        userInitials = userName
            .split(' ')
            .where((e) => e.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase();
      }

      // --- Letzte Session abrufen ---
      final sessions = await _supabase
          .from('learning_sessions')
          .select()
          .order('created_at', ascending: false)
          .limit(1) as List<dynamic>;

      if (sessions.isNotEmpty) {
        lastSession = sessions.first as Map<String, dynamic>;
      }

      // --- Letzte Module abrufen ---
      final modules = await _supabase
          .from('modules')
          .select('*')
          .limit(3) as List<dynamic>;

      lastModules = modules
          .map((e) => LernenModule.fromJson(e as Map<String, dynamic>))
          .toList();

      // --- Statistiken setzen ---
      questionsThisWeek = lastSession?['total_questions'] ?? 0;
      // Module aus user_statistics berechnen
      await _calculateUserStatistics();
      //modulesCompleted = 5; // TODO: aus Datenbank berechnen
      currentStreak = 7;    // TODO: aus Datenbank berechnen

      // --- Errungenschaften setzen ---
      achievements = [
        {'title': 'First Step', 'earned': true},
        {'title': 'Quiz Master', 'earned': false},
      ];
    } catch (e) {
      error = 'Konnte Home-Daten nicht laden: $e';
      print(error);
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
            profileCreatedAt = 'Mitglied seit ${date.day}.${date.month}.${date.year}';
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

  // NEU: Statistiken für Profilseite berechnen
  // NEU: Statistiken für Profilseite berechnen
  // NEU: Statistiken für Profilseite berechnen
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
          final durationMinutes = (session['timer_duration_minutes'] as int?) ?? 0;
          totalDuration += durationMinutes * 60; // Minuten zu Sekunden umrechnen
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
          modulesCompleted = (statisticsResponse['modules_completed'] as int?) ?? 0;
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
            .select('modules_completed, questions_answered_this_week, current_streak')
            .eq('user_id', user.id)
            .single();

        if (statisticsResponse != null) {
          modulesCompleted = (statisticsResponse['modules_completed'] as int?) ?? 0;
          questionsThisWeek = (statisticsResponse['questions_answered_this_week'] as int?) ?? 0;
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
          await _supabase.auth.updateUser(
            UserAttributes(email: email),
          );
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
          ? name.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase()
          : 'U';

      // 4. Benachrichtigen
      notifyListeners();

      // 5. Erfolgreiche Aktualisierung melden
      print('✅ UpdateProfile erfolgreich abgeschlossen');
      print(emailChanged
          ? '📧 Email wurde SOFORT geändert auf: $email'
          : '✅ Nur Name/Username aktualisiert');

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
      final modules = await _supabase
          .from('modules')
          .select('*') as List<dynamic>;

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

  // In BackendProvider Klasse fügen Sie diese Methoden hinzu:

// Reset-Methode
  void reset() {
    userName = '';
    userInitials = '';
    questionsThisWeek = 0;
    currentStreak = 0;
    modulesCompleted = 0;
    lastModules = [];
    lastSession = null;
    achievements = [];

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

// Optional: Clear-Methode für Logout
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
            return Scaffold(
              body: Center(child: Text(provider.error!)),
            );
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
                        Text('Welcome back, ${provider.userName}!',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
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
                        const Text('Continue where you left off',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 8),
                        for (var module in provider.lastModules)
                          QuizCard(
                            moduleTitle: module.name,
                            moduleDescription: module.description ?? '',
                            progress:
                            provider.calculateProgress(provider.lastSession),
                            onResume: () {},
                          ),
                        const SizedBox(height: 24),
                        const Text('Quick Actions',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
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
