import 'package:flutter/material.dart';
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/core/constants/app_strings.dart';
import 'package:mc_trainer_kami/features/home/widgets/category_card.dart';
import 'package:mc_trainer_kami/features/home/widgets/quiz_card.dart';
import 'package:mc_trainer_kami/models/lernen_module.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Extension zur Großschreibung von Strings
extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}

// --- Backend Provider ---
class BackendProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  String userName = ''; //  Username des Benutzers
  String fullName = ''; // Vollständiger Name des Benutzers
  String userInitials = ''; // Initialen für Avatar
  int questionsThisWeek = 0; // Anzahl der Fragen diese Woche
  int currentStreak = 0; // Aktuelle Serie (Streak)
  int modulesCompleted = 0; // Anzahl abgeschlossener Module

  List<LernenModule> lastModules = []; // Letzte Module
  Map<String, dynamic>? lastSession; // Letzte Session
  List<Map<String, dynamic>> achievements = []; // Errungenschaften

  bool isLoading = false; // Ladezustand
  String? error; // Fehlernachricht

  // Konstruktor lädt direkt die Home-Daten
  HomeBackendProvider() {
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
      // --- Aktuellen Benutzer abrufen ---
      // --- Aktuellen Benutzer abrufen (Session aktualisieren) ---
      final user = _supabase.auth.currentUser;

      if (user != null) {
        final myFullName = user.userMetadata?['full_name'];
        final myname = user.userMetadata?['username'];

        userName = (myname != null && myname.isNotEmpty)
            ? myname
            : user.email?.split('@').first.capitalize() ?? 'User';

        fullName = myFullName;

        userInitials = fullName
            .split(' ')
            .where((e) => e.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join()
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

      // --- Letzte Module abrufen ---
      final modules =
          await _supabase.from('modules').select('*').limit(3) as List<dynamic>;

      lastModules = modules
          .map((e) => LernenModule.fromJson(e as Map<String, dynamic>))
          .toList();

      // --- Statistiken setzen ---
      questionsThisWeek = lastSession?['total_questions'] ?? 0;
      modulesCompleted = 5; // TODO: aus Datenbank berechnen
      currentStreak = 7; // TODO: aus Datenbank berechnen

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
                          'Welcome, ${provider.userName}!',
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
