import 'package:flutter/material.dart';
import 'package:mc_trainer/core/constants/app_colors.dart';
import 'package:mc_trainer/core/constants/app_strings.dart';
import 'package:mc_trainer/features/home/widgets/category_card.dart';
import 'package:mc_trainer/features/home/widgets/quiz_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: Hier Navigationslogik für die Bottom Bar implementieren
  }

  // --- Widgets for the Header Area (unverändert) ---
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

  Widget _buildHeaderContent(BuildContext context) {
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
            AppStrings.homeWelcome,
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
            value: '120',
            label: 'Questions this week',
          ),
          _buildStatCard(
            icon: Icons.watch_later_outlined,
            value: '7 days',
            label: 'Current streak',
          ),
          _buildStatCard(
            icon: Icons.workspace_premium_outlined,
            value: '5/12',
            label: 'Modules completed',
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
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
          QuizCard(
            moduleTitle: 'Advanced Mathematics',
            moduleDescription: 'Module 3: Calculus Fundamentals',
            progress: 0.65,
            onResume: () {},
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
          CategoryCard(
            icon: Icons.stacked_bar_chart,
            title: 'Browse Modules',
            subtitle: '12 modules available',
            iconColor: Theme.of(context).colorScheme.primary,
            onTap: () {},
          ),
          CategoryCard(
            icon: Icons.emoji_events_outlined,
            title: 'Achievements',
            subtitle: 'View your badges and rewards',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // Verwendung eines Stacks, um Bild und Gradient zu überlagern
    return Stack(
      children: [
        // 1. Hintergrundbild
        Positioned.fill(
          child: Image.asset(
            'assets/images/background.jpg', // Dein Asset-Pfad
            fit: BoxFit.cover,
          ),
        ),

        // 2. Transparenter Gradient zur Verbesserung der Lesbarkeit
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(gradient: AppColors.darkOverlayGradient),
          ),
        ),

        // 3. Der eigentliche Scaffold mit transparentem Hintergrund
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,

          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            // ... (AppBar Inhalt unverändert) ...
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
                child: CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 15,
                  child: const Text(
                    'JD',
                    style: TextStyle(
                      color: AppColors.primaryColorDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
                  height:
                      AppBar().preferredSize.height +
                      MediaQuery.of(context).padding.top,
                ),
                const SizedBox(height: 20),
                _buildHeaderContent(context),
                _buildMainContent(context),
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
  }
}
