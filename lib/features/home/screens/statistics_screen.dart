import 'package:flutter/material.dart';
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/models/statistics.dart'; // Pfad prüfen

class StatisticsOverviewScreen extends StatelessWidget {
  final List<Statistics> allStats;

  const StatisticsOverviewScreen({super.key, required this.allStats});

  @override
  Widget build(BuildContext context) {
    // 1. Berechnungen für die Gesamtübersicht
    final int totalQ = allStats.fold(
      0,
      (sum, item) => sum + item.total_questions,
    );
    final int totalC = allStats.fold(
      0,
      (sum, item) => sum + item.correct_answered,
    );
    final double totalAccuracy = totalQ > 0 ? (totalC / totalQ) * 100 : 0;

    return Scaffold(
      body: Stack(
        children: [
          // Hintergrund-Konsistenz
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.darkOverlayGradient,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Back Button & Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Header: Gesamt-Performance
                _buildTotalSummaryHeader(totalQ, totalAccuracy),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "Recent Sessions",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Scrollbare Liste der einzelnen Sessions
                Expanded(
                  child: allStats.isEmpty
                      ? const Center(
                          child: Text(
                            "No data yet",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: allStats.length,
                          itemBuilder: (context, index) {
                            // Wir zeigen die neusten Sessions oben an (reversed)
                            final session = allStats.reversed.toList()[index];
                            return _buildSessionTile(session, index);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI KOMPONENTEN ---

  Widget _buildTotalSummaryHeader(int totalQuestions, double accuracy) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.appHeaderBackgroundGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Questions",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                "$totalQuestions",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Overall Accuracy",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                "${accuracy.toStringAsFixed(1)}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(Statistics session, int index) {
    final double sessionAccuracy = session.total_questions > 0
        ? (session.correct_answered / session.total_questions) * 100
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: session.session_success
                ? Colors.green.withOpacity(0.2)
                : Colors.orange.withOpacity(0.2),
            child: Icon(
              session.session_success ? Icons.check : Icons.trending_flat,
              color: session.session_success
                  ? Colors.greenAccent
                  : Colors.orangeAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Session ${allStats.length - index}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${session.correct_answered}/${session.total_questions} correct",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            "${sessionAccuracy.toStringAsFixed(0)}%",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
