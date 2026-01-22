import 'package:flutter/material.dart';
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/core/constants/app_strings.dart';
import 'package:mc_trainer_kami/features/home/widgets/category_card.dart';
import 'package:mc_trainer_kami/features/home/widgets/quiz_card.dart';
import 'package:mc_trainer_kami/models/lernen_module.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Extension zur Großschreibung von Strings
extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}

// --- Backend Provider ---
class BackendProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  StreamSubscription<dynamic>? _authSub;

  String userName = '';       // Vollständiger Name des Benutzers
  String userInitials = '';         // Initialen für Avatar
  int questionsThisWeek = 0;          // Anzahl der Fragen diese Woche
  int currentStreak = 0;              // Aktuelle Serie (Streak)
  int modulesCompleted = 0;           // Anzahl abgeschlossener Module

  List<LernenModule> lastModules = [];           // Letzte Module
  Map<String, dynamic>? lastSession;            // Letzte Session
  List<Map<String, dynamic>> achievements = []; // Errungenschaften

  bool isLoading = false;           // Ladezustand
  String? error;                    // Fehlernachricht

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
    return (correct / total).clamp(0.0, 1.0);
  }

  // --- Daten für Home Screen abrufen ---
  Future<void> fetchHomeData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // --- Aktuellen Benutzer abrufen ---
      // --- Aktuellen Benutzer abrufen (Session aktualisieren) ---
      final user = _supabase.auth.currentUser;

      if (user != null) {
        final fullName = user.userMetadata?['full_name'];

        userName = (fullName != null && fullName.isNotEmpty)
            ? fullName
            : user.email?.split('@').first.capitalize() ?? 'User';

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

      // NOTE: Don't load modules here to avoid overwriting the full module list.
      // Modules are loaded via `fetchModules()` to ensure the full set is available.

      // --- Statistiken setzen ---
      questionsThisWeek = lastSession?['total_questions'] ?? 0;
      modulesCompleted = 5; // TODO: aus Datenbank berechnen
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
  // Module separat laden (z.B. für Modules Screen)
  Future<void> fetchModules() async {
    isLoading = true;
    notifyListeners();

    try {
      debugPrint('fetchModules: querying supabase modules table...');
      final modulesData = await _supabase.from('modules').select('*') as List<dynamic>;
      debugPrint('fetchModules: received ${modulesData.length} rows');

      lastModules = modulesData.map((e) {
        final m = e as Map<String, dynamic>;
        final idVal = m['id'];
        final idInt = (idVal is int) ? idVal : (idVal is num ? idVal.toInt() : int.tryParse(idVal?.toString() ?? '0') ?? 0);
        final nameVal = (m['title'] ?? m['name'] ?? '').toString();
        final descVal = (m['description'] ?? '').toString();
        debugPrint('fetchModules: row -> id=$idInt name=$nameVal');
        return LernenModule(
          id: idInt,
          name: nameVal,
          description: descVal,
        );
      }).toList();
    } catch (e) {
      error = 'Konnte Module nicht laden: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Submodule laden ---
  Future<List<Map<String, dynamic>>> fetchSubmodules(dynamic moduleId) async {
    try {
      final subs = await _supabase
          .from('submodules')
          .select('*')
          .eq('modules_id', moduleId) as List<dynamic>;

      return subs.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      error = 'Konnte Submodule nicht laden: $e';
      notifyListeners();
      return [];
    }
  }

  // --- Karten für Submodule + Level laden ---
    Future<List<Map<String, dynamic>>> fetchCardsForSubmoduleLevel(
      dynamic submoduleId, int level) async {
    try {
        debugPrint('fetchCardsForSubmoduleLevel: submoduleId=$submoduleId level=$level');

        final cards = await _supabase
            .from('questions')
            .select('*')
            .eq('submodule_id', submoduleId)
            .eq('level_number', level) as List<dynamic>;

        debugPrint('fetchCardsForSubmoduleLevel: got ${cards.length} rows with level filter');

        if (cards.isEmpty) {
          // Fallback: lade alle Fragen für das Submodule ohne Level-Filter
          debugPrint('fetchCardsForSubmoduleLevel: fallback to submodule-only query');
          final all = await _supabase
              .from('questions')
              .select('*')
              .eq('submodule_id', submoduleId) as List<dynamic>;
          debugPrint('fetchCardsForSubmoduleLevel: got ${all.length} rows without level filter');
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
  Future<List<Map<String, dynamic>>> fetchAllQuestionsForSubmodule(dynamic submoduleId) async {
    try {
      debugPrint('fetchAllQuestionsForSubmodule: submoduleId=$submoduleId');
      
      final questions = await _supabase
          .from('questions')
          .select('*')
          .eq('submodule_id', submoduleId)
          .order('level_number', ascending: true) as List<dynamic>;

      debugPrint('fetchAllQuestionsForSubmodule: received ${questions.length} questions');
      return questions.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('fetchAllQuestionsForSubmodule error: $e');
      return [];
    }
  }

  // --- Optionen für eine Frage laden ---
    Future<List<Map<String, dynamic>>> fetchOptionsForQuestion(dynamic questionId) async {
      try {
        final opts = await _supabase
            .from('options')
            .select('*')
            .eq('question_id', questionId) as List<dynamic>;

        return opts.map((e) => e as Map<String, dynamic>).toList();
      } catch (e) {
        debugPrint('fetchOptionsForQuestion error: $e');
        return [];
      }
    }

  // --- Optionen für mehrere Fragen batch-laden ---
  Future<Map<dynamic, List<Map<String, dynamic>>>> fetchOptionsForQuestions(List<dynamic> questionIds) async {
    try {
      if (questionIds.isEmpty) return {};
      
      final allOptions = await _supabase
          .from('options')
          .select('*')
          .inFilter('question_id', questionIds) as List<dynamic>;

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

      final insert = await _supabase.from('learning_sessions').insert({
        'user_id': user.id,
        'submodule_id': submoduleId,
        'start_time': DateTime.now().toIso8601String(),
        'total_questions': 0,
        'correct_answered': 0,
        'incorrect_answered': 0,
        'status': 'active',
      }).select() as List<dynamic>;

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

  Future<void> finishLearningSession(String sessionId,
      {required int total, required int correct}) async {
    try {
      final incorrect = total - correct;
      final accuracy = total == 0 ? 0 : ((correct / total) * 100).round();

      await _supabase.from('learning_sessions').update({
        'end_time': DateTime.now().toIso8601String(),
        'total_questions': total,
        'correct_answered': correct,
        'incorrect_answered': incorrect,
        'accuracy_percentage': accuracy,
        'status': 'finished',
      }).eq('id', sessionId);

      // Aktualisiere lokale letzte Session
      lastSession = (await _supabase
          .from('learning_sessions')
          .select()
          .eq('id', sessionId) as List<dynamic>)
          .first as Map<String, dynamic>;

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
      final existing = await _supabase
          .from('user_card_progress')
          .select()
          .eq('user_id', user.id)
          .eq('card_id', cardId) as List<dynamic>;

      Map<String, dynamic>? progress =
          existing.isNotEmpty ? existing.first as Map<String, dynamic> : null;

      if (progress == null) {
        // Erstelle neuen Eintrag
        final insert = await _supabase.from('user_card_progress').insert({
          'user_id': user.id,
          'card_id': cardId,
          'correct_count': correct ? 1 : 0,
          'incorrect_count': correct ? 0 : 1,
          'streak_count': correct ? 1 : 0,
          'is_mastered': correct ? (1 >= 6) : false,
          'last_reviewed': DateTime.now().toIso8601String(),
        }).select() as List<dynamic>;

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

        await _supabase.from('user_card_progress').update({
          'streak_count': streak,
          'correct_count': correctCount,
          'incorrect_count': incorrectCount,
          'is_mastered': isMastered,
          'last_reviewed': DateTime.now().toIso8601String(),
        }).eq('id', progress['id']);
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
      String cardId, String userId) async {
    try {
      // Karte laden, um submodule_id und level zu kennen
        final cardList = await _supabase
          .from('questions')
          .select()
          .eq('id', cardId) as List<dynamic>;

      if (cardList.isEmpty) return;
      final card = cardList.first as Map<String, dynamic>;
      final submoduleId = (card['submodule_id'] ?? card['submoduleId']).toString();
      final level = (card['level_number'] ?? card['level']) as int;

      // Anzahl Karten in diesem Submodule-Level
      final allCards = await _supabase
          .from('questions')
          .select('id')
          .eq('submodule_id', submoduleId)
          .eq('level_number', level) as List<dynamic>;

      final total = allCards.length;

      // Anzahl gemeisterter Karten durch Nutzer
        final allCardIds = allCards.map((e) => e['id']).toList();

        final userProgress = await _supabase
          .from('user_card_progress')
          .select('id,card_id,is_mastered')
          .eq('user_id', userId) as List<dynamic>;

        final mastered = userProgress
          .where((p) => (p['is_mastered'] == true) && allCardIds.contains(p['card_id']))
          .toList();

        final masteredCount = mastered.length;
      final percent = total == 0 ? 0.0 : (masteredCount / total) * 100.0;

      // Update or insert progress for this submodule-level
      final existing = await _supabase
          .from('user_submodule_level_progress')
          .select()
          .eq('user_id', userId)
          .eq('submodule_id', submoduleId)
          .eq('level_number', level) as List<dynamic>;

      final unlocked = percent >= 80.0;

      if (existing.isNotEmpty) {
        await _supabase.from('user_submodule_level_progress').update({
          'cards_mastered': masteredCount,
          'cards_answered': await _countAnsweredInList(userId, allCards),
          'is_unlocked': unlocked,
          'updated_at': DateTime.now().toIso8601String(),
          'last_accessed': DateTime.now().toIso8601String(),
        }).eq('id', (existing.first as Map<String, dynamic>)['id']);
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
        final existingNext = await _supabase
            .from('user_submodule_level_progress')
            .select()
            .eq('user_id', userId)
            .eq('submodule_id', submoduleId)
            .eq('level_number', nextLevel) as List<dynamic>;

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

  Future<int> _countAnsweredInList(String userId, List<dynamic> allCards) async {
    if (allCards.isEmpty) return 0;
    try {
        final allCardIds = allCards.map((e) => e['id']).toList();
        final userProgress = await _supabase
          .from('user_card_progress')
          .select('id,card_id')
          .eq('user_id', userId) as List<dynamic>;

        final answered = userProgress.where((p) => allCardIds.contains(p['card_id'])).toList();
        return answered.length;
    } catch (_) {
      return 0;
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
