// features/modules/screens/lesson_list_screen.dart

import 'package:flutter/material.dart';
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/core/widgets/custom_app_appbar.dart';
import 'package:mc_trainer_kami/core/widgets/app_bar_actions.dart';
import 'package:mc_trainer_kami/models/module_data.dart';
import 'package:provider/provider.dart';
import 'package:mc_trainer_kami/provider/backend_provider.dart';
import 'quiz_screen.dart'; // NEU: Import für den QuizScreen

// Widget für eine einzelne Lektion (JETZT ALS KARTE)
class LessonCard extends StatelessWidget {
  final Module module; // HINZUGEFÜGT für die Navigation
  final Lesson lesson;
  final VoidCallback? onTap;

  const LessonCard({super.key, required this.module, required this.lesson, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Bestimmen des linken Icons basierend auf dem Status
    IconData leadingIcon;
    Color iconColor;

    if (lesson.isLocked) {
      leadingIcon = Icons.lock_outline;
      iconColor = Colors.grey.shade400;
    } else if (lesson.isCompleted) {
      leadingIcon = Icons.check_circle;
      iconColor = Colors.green.shade600;
    } else {
      leadingIcon = Icons.circle_outlined;
      iconColor = Theme.of(context).colorScheme.primary;
    }

    final bool isDimmed = lesson.isLocked;

    // InkWell für Tipp-Feedback und Navigation
    return InkWell(
      onTap: lesson.isLocked ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 16,
        ), // Abstand zwischen den Karten
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, // Weißer Hintergrund
          borderRadius: BorderRadius.circular(20), // Abgerundete Ecken
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Leichter Schatten
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. STATUS ICON (Links)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(leadingIcon, size: 24, color: iconColor),
            ),

            // 2. TITEL & METADATEN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titel
                  Text(
                    lesson.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDimmed ? Colors.grey.shade500 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Metadaten: Dauer und Fragen
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lesson.duration,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.quiz_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${lesson.questions} questions',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Pfeil-Icon nur für zugängliche Lektionen
            if (!isDimmed)
              const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class LessonListScreen extends StatelessWidget {
  final Module module;

  const LessonListScreen({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final Color moduleColor = module.iconColor;

    // Wiederverwendung des Stack-Musters für den Hintergrund
    return Stack(
      children: [
        // 1. Hintergrund (Bleibt gleich)
        Positioned.fill(
          child: Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(gradient: AppColors.darkOverlayGradient),
          ),
        ),

        // 2. Der eigentliche Scaffold
        Scaffold(
          backgroundColor: Colors.transparent,

          appBar: CustomAppBar(
            title: module.title,
            subtitle: module.description,
            showBackButton: true,
            backgroundColor: Colors.white,
            actions: [AppBarActions(iconColor: Colors.black)],
          ),

          // 3. Body
          body: SingleChildScrollView(
            // Setzt den hellgrauen Hintergrund für den Body-Inhalt
            child: Container(
              color:Colors.transparent, // Setze den hellgrauen Hintergrund
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modul-Header (Fortschrittsanzeige) - Behält den weißen Hintergrund
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: moduleColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            module.icon,
                            color: moduleColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${module.completedLessons}/${module.totalLessons} Lessons Completed',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: MediaQuery.of(context).size.width - 120,
                              child: LinearProgressIndicator(
                                value: module.progress,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  module.progress == 1.0
                                      ? Colors.green
                                      : moduleColor,
                                ),
                                borderRadius: BorderRadius.circular(5),
                                minHeight: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Lektionen-Liste (lade Submodules aus Supabase)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: Provider.of<BackendProvider>(context, listen: false)
                          .fetchSubmodules(module.id ?? 0),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Fehler beim Laden der Lektionen: ${snapshot.error}'),
                          );
                        }

                        final subs = snapshot.data ?? [];
                        if (subs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No lessons (submodules) found.'),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: subs.map<Widget>((s) {
                            final subId = s['id'];
                            final levelNum = (s['level'] is int) ? s['level'] as int : (int.tryParse(s['level']?.toString() ?? '1') ?? 1);

                            // NEU: Für jedes Submodul die Fragen-Anzahl async laden
                            return FutureBuilder<List<Map<String, dynamic>>>(
                              future: Provider.of<BackendProvider>(context, listen: false)
                                  .fetchAllQuestionsForSubmodule(subId),
                              builder: (context, questionSnapshot) {
                                final questionsCount = questionSnapshot.data?.length ?? 0;

                                final lesson = Lesson(
                                  title: s['title']?.toString() ?? 'Untitled',
                                  duration: '${s['estimate_duration'] ?? '-'} min',
                                  questions: questionsCount, // NEU: Echte Anzahl
                                  isLocked: false,
                                );

                                return LessonCard(
                                  module: module,
                                  lesson: lesson,
                                  onTap: questionSnapshot.data == null
                                      ? null // Noch beim Laden
                                      : () async {
                                    if (questionSnapshot.data!.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keine Fragen in diesem Submodul.')));
                                      return;
                                    }

                                    final provider = Provider.of<BackendProvider>(context, listen: false);
                                    final questionsData = questionSnapshot.data!;

                                    // Lade Optionen für alle Fragen batch-weise
                                    final questionIds = questionsData.map((q) => q['id']).toList();
                                    final optionsMap = await provider.fetchOptionsForQuestions(questionIds);

                                    final List<Question> quizQuestions = [];
                                    for (var q in questionsData) {
                                      final qMap = q as Map<String, dynamic>;
                                      final qId = qMap['id'];
                                      final opts = optionsMap[qId] ?? [];
                                      
                                      final options = opts.map((o) => Option(
                                            text: o['text']?.toString() ?? '',
                                            label: o['label']?.toString() ?? '',
                                            isCorrect: (o['is_correct'] == true),
                                          )).toList();

                                      int correctIndex = 0;
                                      for (int i = 0; i < options.length; i++) {
                                        if (options[i].isCorrect) { correctIndex = i; break; }
                                      }

                                      quizQuestions.add(Question(
                                        id: qMap['id'], // NEU: Speichere Question ID
                                        questionText: qMap['questionText']?.toString() ?? qMap['question_text']?.toString() ?? '',
                                        options: options,
                                        correctOptionIndex: correctIndex,
                                        explanation: qMap['explanation']?.toString(),
                                      ));
                                    }

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuizScreen(
                                          module: module,
                                          lesson: Lesson(
                                            title: lesson.title,
                                            duration: lesson.duration,
                                            questions: quizQuestions.length,
                                            quizQuestions: quizQuestions,
                                          ),
                                          submoduleId: subId,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
