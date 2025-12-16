import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/core/constants/app_strings.dart';
import 'package:mc_trainer_kami/features/home/widgets/category_card.dart';
import 'package:mc_trainer_kami/features/home/widgets/quiz_card.dart';
import 'package:mc_trainer_kami/provider/backend_provider.dart';
import 'package:mc_trainer_kami/provider/home_backend_provider.dart';
import 'package:mc_trainer_kami/features/modules/screens/module_list_screen.dart';
import '../../../main.dart';
import 'package:mc_trainer_kami/features/home/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final DateTime? unlockedDate;
  final int points;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    this.unlockedDate,
    required this.points,
  });
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _showAchievementsDetails = false;
  List<Achievement> _achievements = [];

  @override
  void initState() {
    super.initState();
    _loadAchievements();
    // Home-Daten laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackendProvider>().fetchHomeData();
    });
  }

  void _loadAchievements() {
    _achievements = [
      Achievement(
        id: '1',
        title: 'Speed Learner',
        description: 'Completed 5 lessons in one day',
        icon: Icons.bolt,
        color: Colors.amber,
        isUnlocked: true,
        unlockedDate: DateTime.now().subtract(const Duration(days: 2)),
        points: 50,
      ),
      Achievement(
        id: '2',
        title: 'Week Warrior',
        description: 'Maintained 7-day streak',
        icon: Icons.calendar_today,
        color: Colors.blue,
        isUnlocked: true,
        unlockedDate: DateTime.now(),
        points: 100,
      ),
      Achievement(
        id: '3',
        title: 'Perfect Score',
        description: 'Got 100% on a quiz',
        icon: Icons.star,
        color: Colors.purple,
        isUnlocked: true,
        unlockedDate: DateTime.now().subtract(const Duration(days: 3)),
        points: 75,
      ),
      Achievement(
        id: '4',
        title: 'Module Master',
        description: 'Complete all modules in a category',
        icon: Icons.auto_awesome,
        color: Colors.green,
        isUnlocked: false,
        points: 150,
      ),
      Achievement(
        id: '5',
        title: 'Early Bird',
        description: 'Complete a lesson before 8 AM',
        icon: Icons.wb_sunny,
        color: Colors.orange,
        isUnlocked: false,
        points: 25,
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigationslogik für die Bottom Bar
    switch (index) {
      case 0: // Home
      // Bereits auf Home, nichts tun oder zurückscrollen
        break;
      case 1: // Modules
      // TODO: Hier ModuleScreen Navigation implementieren
      // Navigator.push(context, MaterialPageRoute(builder: (context) => ModulesScreen()));
        break;
      case 2: // Profile
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(),
          ),
        );
        // Setze den Index zurück auf Home nach der Navigation
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _selectedIndex = 0;
            });
          }
        });
        break;
    }
  }

  void _toggleAchievementsDetails() {
    setState(() {
      _showAchievementsDetails = !_showAchievementsDetails;
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  // --- Widgets for the Header Area ---
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

  Widget _buildHeaderContent(BuildContext context, BackendProvider backend) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppColors.appHeaderBackgroundGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColorDark.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${backend.userName}!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.homeQuote,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          _buildStatCard(
            icon: Icons.my_location_outlined,
            value: backend.questionsThisWeek.toString(),
            label: 'Questions this week',
          ),
          _buildStatCard(
            icon: Icons.watch_later_outlined,
            value: '${backend.currentStreak} days',
            label: 'Current streak',
          ),
          _buildStatCard(
            icon: Icons.workspace_premium_outlined,
            value: '${backend.modulesCompleted}/${backend.lastModules.length}',
            label: 'Modules completed',
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: achievement.isUnlocked
            ? achievement.color.withOpacity(0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: achievement.isUnlocked
              ? achievement.color.withOpacity(0.3)
              : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? achievement.color
                  : Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              achievement.icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Text-Inhalt
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      achievement.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: achievement.isUnlocked
                            ? achievement.color
                            : Colors.grey[600],
                      ),
                    ),
                    if (achievement.isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: achievement.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${achievement.points} pts',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: achievement.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: achievement.isUnlocked
                        ? Colors.black87
                        : Colors.grey[600],
                  ),
                ),
                if (achievement.isUnlocked && achievement.unlockedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Unlocked: ${_formatDate(achievement.unlockedDate!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (!achievement.isUnlocked)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Not yet unlocked',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, BackendProvider backend) {
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    final totalCount = _achievements.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
            child: Text(
              AppStrings.continueLearning,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
          // Letzte Module anzeigen
          ...backend.lastModules.map(
                (module) => QuizCard(
              moduleTitle: module.name,
              moduleDescription: module.description ?? '',
              progress: 0.65,
              onResume: () {},
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              AppStrings.quickActions,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),

          // Browse Modules Karte
          CategoryCard(
            icon: Icons.stacked_bar_chart,
            title: 'Browse Modules',
            subtitle: '${backend.lastModules.length} modules available',
            iconColor: Theme.of(context).colorScheme.primary,
            onTap: () {},
            showArrow: true, // "Go" anzeigen
          ),

          // Achievements Karte (mit expandierbaren Details)
          Column(
            children: [
              // Die eigentliche Achievements-Karte
              CategoryCard(
                icon: Icons.emoji_events_outlined,
                title: 'Achievements',
                subtitle: 'View your badges and rewards ($unlockedCount/$totalCount)',
                iconColor: Theme.of(context).colorScheme.secondary,
                onTap: _toggleAchievementsDetails,
                showArrow: false, // KEIN "Go" - stattdessen expand/collapse
                trailing: Icon(
                  _showAchievementsDetails ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primaryColorLight,
                  size: 24,
                ),
              ),

              // Achievements Details (nur wenn geöffnet)
              if (_showAchievementsDetails) ...[
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ..._achievements.map((achievement) {
                        return _buildAchievementItem(achievement);
                      }).toList(),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Optional: Zur vollständigen Achievements-Seite navigieren
                          },
                          child: const Text(
                            'View All →',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // Statistics Karte (wird nach unten verschoben wenn Achievements geöffnet sind)
          CategoryCard(
            icon: Icons.trending_up,
            title: 'Statistics',
            subtitle: 'Track your progress',
            iconColor: Colors.green.shade700,
            onTap: () {
              // Navigation zur Profilseite (wo die Statistiken sind)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            showArrow: true, // "Go" anzeigen
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BackendProvider>(
      builder: (context, backend, child) {
        if (backend.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (backend.error != null) {
          return Scaffold(
            body: Center(child: Text(backend.error!)),
          );
        }

        return Stack(
          children: [
            // 1. Hintergrundbild
            Positioned.fill(
              child: Image.asset(
                'assets/images/background.jpg',
                fit: BoxFit.cover,
              ),
            ),
            // 2. Transparenter Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(gradient: AppColors.darkOverlayGradient),
              ),
            ),
            // 3. Scaffold mit Inhalt
            Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: AppColors.appHeaderBackgroundGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.appTitle,
                      style: TextStyle(
                        color: Colors.blue.shade500,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.black,
                        ),
                        onPressed: () {},
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: const Text(
                            '3',
                            style: TextStyle(color: Colors.white, fontSize: 8),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        // Zur Profilseite navigieren
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.grey,
                        radius: 15,
                        child: Text(
                          backend.userInitials,
                          style: const TextStyle(
                            color: AppColors.primaryColorDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    // Abstand für die transparente AppBar
                    SizedBox(
                      height: AppBar().preferredSize.height +
                          MediaQuery.of(context).padding.top,
                    ),
                    const SizedBox(height: 20),
<<<<<<< lib/features/home/screens/home_screen.dart
                    // Header Statistiken
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: AppColors.appHeaderBackgroundGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColorDark.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                            'Welcome back, ${backend.userName}!',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 22,
                            ),
                            ),


                          const SizedBox(height: 4),
                          Text(
                            AppStrings.homeQuote,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildStatCard(
                            icon: Icons.my_location_outlined,
                            value: backend.questionsThisWeek.toString(),
                            label: 'Questions this week',
                          ),
                          _buildStatCard(
                            icon: Icons.watch_later_outlined,
                            value: '${backend.currentStreak} days',
                            label: 'Current streak',
                          ),
                          _buildStatCard(
                            icon: Icons.workspace_premium_outlined,
                            value: '${backend.modulesCompleted}/${backend.lastModules.length}',
                            label: 'Modules completed',
                          ),
                        ],
                      ),
                    ),
                    // Main Content
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.continueLearning,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Letzte Module anzeigen
                          ...backend.lastModules.map(
                                (module) => QuizCard(
                              moduleTitle: module.name,
                              moduleDescription: module.description ?? '',
                              progress: 0.65, // Hier ggf. Fortschritt aus DB berechnen
                              onResume: () {},
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            AppStrings.quickActions,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CategoryCard(
                            icon: Icons.stacked_bar_chart,
                            title: 'Browse Modules',
                            subtitle: '${backend.lastModules.length} modules available',
                            iconColor: Theme.of(context).colorScheme.primary,
                                      onTap: () {
              // Navigiere zum neuen Modul-Listen-Screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModuleListScreen(),
                ),
              );
            },

                          ),
                          CategoryCard(
                            icon: Icons.emoji_events_outlined,
                            title: 'Achievements',
                            subtitle: '${backend.achievements.where((a) => a['earned'] == true).length} badges earned',
                            iconColor: Theme.of(context).colorScheme.secondary,
                            onTap: () {},
                          ),
                          CategoryCard(
                            icon: Icons.trending_up,
                            title: 'Statistics',
                            subtitle: 'Track your progress',
                            iconColor: Colors.green.shade700,
                            onTap: () {},
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
=======
                    // Header Content mit Provider-Daten
                    _buildHeaderContent(context, backend),
                    // Main Content mit Provider-Daten
                    _buildMainContent(context, backend),
>>>>>>> lib/features/home/screens/home_screen.dart
                  ],
                ),
              ),
              bottomNavigationBar: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.library_books),
                    label: 'Modules',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Colors.grey.shade600,
                onTap: _onItemTapped,
                backgroundColor: Colors.white,
                elevation: 10,
              ),
            ),
          ],
        );
      },
    );
  }
}