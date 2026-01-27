// features/modules/screens/lesson_list_screen.dart

import 'package:flutter/material.dart';
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/core/widgets/custom_app_appbar.dart';
import 'package:mc_trainer_kami/core/widgets/app_bar_actions.dart';
import 'package:mc_trainer_kami/models/module_data.dart';
import 'package:provider/provider.dart';
import 'package:mc_trainer_kami/provider/backend_provider.dart';
import 'quiz_screen.dart'; // NEU: Import für den QuizScreen
import 'package:share_plus/share_plus.dart';

// Widget für eine einzelne Lektion (JETZT ALS KARTE MIT FORTSCHRITT)
class LessonCard extends StatelessWidget {
  final Module module; // HINZUGEFÜGT für die Navigation
  final Lesson lesson;
  final double submoduleProgress; // NEU: Fortschritt des Submodules
  final VoidCallback? onOpen;
  final VoidCallback? onSelectToggle;
  final bool selectionMode;
  final bool isSelected;

  const LessonCard({
    super.key,
    required this.module,
    required this.lesson,
    this.submoduleProgress = 0.0, // Standard: kein Fortschritt
    this.onOpen,
    this.onSelectToggle,
    this.selectionMode = false,
    this.isSelected = false,
  });

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
      onTap: selectionMode ? onSelectToggle : (lesson.isLocked ? null : onOpen),
      onLongPress: onSelectToggle,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(
              bottom: 16,
            ), // Abstand zwischen den Karten
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withOpacity(0.08)
                  : Colors.white, // Weißer Hintergrund
              borderRadius: BorderRadius.circular(20), // Abgerundete Ecken
              border: isSelected
                  ? Border.all(color: Colors.blue, width: 1.5)
                  : null,
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
                          color: isDimmed
                              ? Colors.grey.shade500
                              : Colors.black87,
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
                      // NEU: Fortschritts-Anzeige
                      if (submoduleProgress > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: submoduleProgress,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    submoduleProgress >= 1.0
                                        ? Colors.green
                                        : Colors.blue,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(submoduleProgress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: submoduleProgress >= 1.0
                                      ? Colors.green
                                      : Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Pfeil-Icon oder Auswahlstatus
                if (selectionMode)
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.blue : Colors.grey,
                  )
                else if (!isDimmed)
                  const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
              ],
            ),
          ),
          if (submoduleProgress >= 1.0)
            Positioned(
              top: 8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                /*child: const Text(
                  'Abgeschlossen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),*/
              ),
            ),
          if (submoduleProgress >= 0.6 && submoduleProgress < 1.0)
            Positioned(
              top: 8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Bestanden',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// NEU: Hilfsfunktion (statisch) um completed Submodule zu zählen
Future<int> _countCompletedSubmodulesHelper(
  BuildContext context,
  List<Map<String, dynamic>> submodules,
) async {
  int count = 0;
  final provider = Provider.of<BackendProvider>(context, listen: false);

  for (var sub in submodules) {
    final isCompleted = await provider.isSubmoduleCompleted(sub['id']);
    if (isCompleted) count++;
  }

  return count;
}

// NEU: Build SubmoduleCard Widget
Widget _buildSubmoduleCard(
  BuildContext context,
  BackendProvider provider,
  Map<String, dynamic> submoduleData,
  dynamic subId,
  Module module,
  bool isCompleted, {
  required bool isLocked,
  required bool selectionMode,
  required bool isSelected,
  required VoidCallback onSelectToggle,
}) {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: provider.fetchAllQuestionsForSubmodule(subId),
    builder: (context, questionSnapshot) {
      final questionsCount = questionSnapshot.data?.length ?? 0;

      // NEU: Lade auch den Fortschritt
      return FutureBuilder<double>(
        future: provider.calculateSubmoduleProgress(subId),
        builder: (context, progressSnapshot) {
          final submoduleProgress = progressSnapshot.data ?? 0.0;

          final effectiveLocked = isLocked && !isCompleted;

          final lesson = Lesson(
            title: submoduleData['title']?.toString() ?? 'Untitled',
            duration: '${submoduleData['estimate_duration'] ?? '-'} min',
            questions: questionsCount,
            isCompleted: isCompleted,
            isLocked: effectiveLocked,
          );

          return LessonCard(
            module: module,
            lesson: lesson,
            submoduleProgress: submoduleProgress, // NEU: Übergebe Fortschritt
            selectionMode: selectionMode,
            isSelected: isSelected,
            onSelectToggle: onSelectToggle,
            onOpen: questionSnapshot.data == null || effectiveLocked
                ? null
                : () async {
                    if (questionSnapshot.data!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Keine Fragen in diesem Submodul.'),
                        ),
                      );
                      return;
                    }

                    final questionsData = questionSnapshot.data!;
                    final questionIds = questionsData
                        .map((q) => q['id'])
                        .toList();
                    final optionsMap = await provider.fetchOptionsForQuestions(
                      questionIds,
                    );

                    final List<Question> quizQuestions = [];
                    for (var q in questionsData) {
                      final qId = q['id'];
                      final opts = optionsMap[qId] ?? [];

                      final options = opts
                          .map(
                            (o) => Option(
                              text: o['text']?.toString() ?? '',
                              label: o['label']?.toString() ?? '',
                              isCorrect: (o['is_correct'] == true),
                            ),
                          )
                          .toList();

                      List<int> correctIndex = [];
                      for (int i = 0; i < options.length; i++) {
                        if (options[i].isCorrect) {
                          correctIndex.add(i);
                          break;
                        }
                      }

                      quizQuestions.add(
                        Question(
                          id: qId,
                          questionText:
                              q['questionText']?.toString() ??
                              q['question_text']?.toString() ??
                              '',
                          options: options,
                          correctOptionIndices: correctIndex,
                          explanation: q['explanation']?.toString(),
                        ),
                      );
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
    },
  );
}

class LessonListScreen extends StatefulWidget {
  final Module module;

  const LessonListScreen({super.key, required this.module});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  String _query = '';
  final Set<int> _selectedSubmoduleIds = {};
  final Map<int, String> _submoduleTitles = {};

  bool get _selectionMode => _selectedSubmoduleIds.isNotEmpty;

  void _toggleSubmoduleSelection(int? id) {
    if (id == null) return;
    setState(() {
      if (_selectedSubmoduleIds.contains(id)) {
        _selectedSubmoduleIds.remove(id);
      } else {
        _selectedSubmoduleIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedSubmoduleIds.clear();
    });
  }

  Future<void> _deleteSelectedSubmodules(BackendProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Submodule löschen?'),
          content: Text(
            'Möchtest du ${_selectedSubmoduleIds.length} Submodul(e) wirklich löschen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await provider.deleteSubmodules(_selectedSubmoduleIds.toList());
      _clearSelection();
      setState(() {});
    }
  }

  Future<void> _shareSelectedSubmodules() async {
    final titles = _selectedSubmoduleIds
        .map((id) => _submoduleTitles[id])
        .whereType<String>()
        .toList();
    if (titles.isEmpty) return;
    final text = 'Meine Submodule:\n- ${titles.join('\n- ')}';
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final Color moduleColor = widget.module.iconColor;
    final progressProvider = Provider.of<BackendProvider>(context);

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

          appBar: _selectionMode
              ? AppBar(
                  title: Text('${_selectedSubmoduleIds.length} selected'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearSelection,
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteSelectedSubmodules(
                        Provider.of<BackendProvider>(context, listen: false),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: _shareSelectedSubmodules,
                    ),
                  ],
                )
              : CustomAppBar(
                  title: widget.module.title,
                  subtitle: widget.module.description,
                  showBackButton: true,
                  backgroundColor: Colors.white,
                  actions: [AppBarActions(iconColor: Colors.black)],
                ),

          // 3. Body
          body: SingleChildScrollView(
            // Setzt den hellgrauen Hintergrund für den Body-Inhalt
            child: Container(
              color: Colors.transparent, // Setze den hellgrauen Hintergrund
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modul-Header (Fortschrittsanzeige) - Behält den weißen Hintergrund
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: progressProvider.fetchSubmodules(
                      widget.module.id ?? 0,
                    ),
                    builder: (context, submodulesSnapshot) {
                      // Zähle completed Submodule
                      return FutureBuilder<int>(
                        future: _countCompletedSubmodulesHelper(
                          context,
                          submodulesSnapshot.data ?? [],
                        ),
                        builder: (context, countSnapshot) {
                          final completedCount = countSnapshot.data ?? 0;
                          final totalCount =
                              submodulesSnapshot.data?.length ?? 0;

                          return Container(
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
                                    widget.module.icon,
                                    color: moduleColor,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$completedCount/$totalCount Submodules Completed',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width:
                                          MediaQuery.of(context).size.width -
                                          120,
                                      child: LinearProgressIndicator(
                                        value: totalCount > 0
                                            ? completedCount / totalCount
                                            : 0,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              completedCount == totalCount &&
                                                      totalCount > 0
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
                          );
                        },
                      );
                    },
                  ),

                  // Lektionen-Liste (lade Submodules aus Supabase)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (value) {
                            setState(() {
                              _query = value.trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Submodule suchen...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _query = '';
                                      });
                                    },
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: progressProvider.fetchSubmodules(
                            widget.module.id ?? 0,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Fehler beim Laden der Lektionen: ${snapshot.error}',
                                ),
                              );
                            }

                            final subs = snapshot.data ?? [];
                            final filteredSubs = _query.isEmpty
                                ? subs
                                : subs.where((s) {
                                    final title = (s['title']?.toString() ?? '')
                                        .toLowerCase();
                                    final q = _query.toLowerCase();
                                    return title.contains(q);
                                  }).toList();

                            for (final s in filteredSubs) {
                              final id = s['id'];
                              if (id is int) {
                                _submoduleTitles[id] =
                                    s['title']?.toString() ?? 'Untitled';
                              }
                            }

                            if (filteredSubs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('No lessons (submodules) found.'),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: filteredSubs.asMap().entries.map<Widget>((
                                entry,
                              ) {
                                final s = entry.value;
                                final originalIndex = subs.indexOf(s);
                                final subId = s['id'];
                                final provider = progressProvider;

                                // NEU: Prüfe ob dieses Submodule completet ist
                                return FutureBuilder<bool>(
                                  future: provider.isSubmoduleCompleted(subId),
                                  builder: (context, completionSnapshot) {
                                    final isCompleted =
                                        completionSnapshot.data ?? false;

                                    // NEU: Prüfe ob vorheriges Submodule completed ist (für Sequential Unlock)
                                    if (originalIndex <= 0) {
                                      // Erstes Submodule ist immer freigeschaltet
                                      return _buildSubmoduleCard(
                                        context,
                                        provider,
                                        s,
                                        subId,
                                        widget.module,
                                        isCompleted,
                                        isLocked: false,
                                        selectionMode: _selectionMode,
                                        isSelected:
                                            subId is int &&
                                            _selectedSubmoduleIds.contains(
                                              subId,
                                            ),
                                        onSelectToggle: () =>
                                            _toggleSubmoduleSelection(
                                              subId is int ? subId : null,
                                            ),
                                      );
                                    } else {
                                      // Prüfe ob vorheriges Submodule completed ist
                                      final previousSubId =
                                          subs[originalIndex - 1]['id'];
                                      return FutureBuilder<bool>(
                                        future: provider.isSubmoduleCompleted(
                                          previousSubId,
                                        ),
                                        builder: (context, prevSnapshot) {
                                          final isPrevCompleted =
                                              prevSnapshot.data ?? false;
                                          return _buildSubmoduleCard(
                                            context,
                                            provider,
                                            s,
                                            subId,
                                            widget.module,
                                            isCompleted,
                                            isLocked:
                                                !(isPrevCompleted ||
                                                    isCompleted), // Locked wenn vorheriges nicht fertig
                                            selectionMode: _selectionMode,
                                            isSelected:
                                                subId is int &&
                                                _selectedSubmoduleIds.contains(
                                                  subId,
                                                ),
                                            onSelectToggle: () =>
                                                _toggleSubmoduleSelection(
                                                  subId is int ? subId : null,
                                                ),
                                          );
                                        },
                                      );
                                    }
                                  },
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
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
