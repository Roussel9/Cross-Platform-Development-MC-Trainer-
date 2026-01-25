// features/modules/screens/module_list_screen.dart (VOLLSTÄNDIG KORRIGIERT für Hover/Click-Hybrid)

import 'package:flutter/material.dart';
import 'package:mc_trainer_kami/models/module_data.dart';
import 'package:mc_trainer_kami/models/lernen_module.dart';
import 'package:mc_trainer_kami/provider/backend_provider.dart';
import 'package:provider/provider.dart';
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/core/widgets/custom_app_appbar.dart';
import 'package:mc_trainer_kami/core/widgets/app_bar_actions.dart';
// Import des neuen Lesson Screens für die Navigation
import 'lesson_list_screen.dart';

// Quiz-Set für die erste Lektion "Atomic Structure"
final List<Question> atomicStructureQuiz = [
  Question(
    questionText: 'What charge does an electron carry?',
    options: [
      Option(text: 'Positive', label: 'A'),
      Option(text: 'Neutral', label: 'B'),
      Option(text: 'Negative', label: 'C', isCorrect: true),
      Option(text: 'Dual charge', label: 'D'),
    ],
    correctOptionIndex: 2,
  ),

  Question(
    questionText: 'Who proposed the nuclear model of the atom?',
    options: [
      Option(text: 'Dalton', label: 'A'),
      Option(text: 'Thomson', label: 'B'),
      Option(text: 'Rutherford', label: 'C', isCorrect: true),
      Option(text: 'Bohr', label: 'D'),
    ],
    correctOptionIndex: 2,
  ),

  Question(
    questionText: 'What experiment led to the discovery of the nucleus?',
    options: [
      Option(text: 'Cathode ray experiment', label: 'A'),
      Option(text: 'Gold foil experiment', label: 'B', isCorrect: true),
      Option(text: 'Oil drop experiment', label: 'C'),
      Option(text: 'Mass spectrometry', label: 'D'),
    ],
    correctOptionIndex: 1,
  ),

  Question(
    questionText: 'What is the nucleus mainly composed of?',
    options: [
      Option(text: 'Electrons', label: 'A'),
      Option(text: 'Protons and neutrons', label: 'B', isCorrect: true),
      Option(text: 'Quarks', label: 'C'),
      Option(text: 'Ions', label: 'D'),
    ],
    correctOptionIndex: 1,
  ),

  Question(
    questionText: 'Why are atoms electrically neutral?',
    options: [
      Option(text: 'They have no electrons', label: 'A'),
      Option(text: 'Protons cancel neutrons', label: 'B'),
      Option(text: 'Equal protons and electrons', label: 'C', isCorrect: true),
      Option(text: 'Neutrons have charge', label: 'D'),
    ],
    correctOptionIndex: 2,
  ),

  Question(
    questionText: 'Which particle was discovered first?',
    options: [
      Option(text: 'Electron', label: 'A', isCorrect: true),
      Option(text: 'Proton', label: 'B'),
      Option(text: 'Neutron', label: 'C'),
      Option(text: 'Nucleus', label: 'D'),
    ],
    correctOptionIndex: 0,
  ),

  Question(
    questionText: 'What is the electron cloud?',
    options: [
      Option(text: 'Fixed electron paths', label: 'A'),
      Option(
        text: 'Region where electrons are likely found',
        label: 'B',
        isCorrect: true,
      ),
      Option(text: 'The nucleus', label: 'C'),
      Option(text: 'Energy source of atom', label: 'D'),
    ],
    correctOptionIndex: 1,
  ),

  Question(
    questionText: 'Which force holds the nucleus together?',
    options: [
      Option(text: 'Electromagnetic force', label: 'A'),
      Option(text: 'Gravitational force', label: 'B'),
      Option(text: 'Strong nuclear force', label: 'C', isCorrect: true),
      Option(text: 'Weak force', label: 'D'),
    ],
    correctOptionIndex: 2,
  ),

  Question(
    questionText: 'What happens when an atom loses an electron?',
    options: [
      Option(text: 'It becomes an anion', label: 'A'),
      Option(text: 'It becomes a cation', label: 'B', isCorrect: true),
      Option(text: 'It becomes neutral', label: 'C'),
      Option(text: 'It becomes an isotope', label: 'D'),
    ],
    correctOptionIndex: 1,
  ),

  Question(
    questionText: 'Which scientist proposed quantized electron orbits?',
    options: [
      Option(text: 'Rutherford', label: 'A'),
      Option(text: 'Bohr', label: 'B', isCorrect: true),
      Option(text: 'Einstein', label: 'C'),
      Option(text: 'Dalton', label: 'D'),
    ],
    correctOptionIndex: 1,
  ),
];

// --- 2. DUMMY DATEN (Bleiben unverändert) ---
final List<Module> dummyModules = [
  Module(
    title: 'Advanced Mathematics',
    description: 'Master advanced mathematical concepts and problem-solving',
    totalLessons: 8,
    completedLessons: 5,
    progress: 0.65,
    iconColor: const Color(0xFF5E35B1),
    icon: Icons.book,
  ),
  Module(
    title: 'Physics Fundamentals',
    description: 'Explore the fundamental principles of physics',
    totalLessons: 6,
    completedLessons: 2,
    progress: 0.40,
    iconColor: const Color(0xFF9C27B0),
    icon: Icons.menu_book,
  ),
  Module(
    title: 'Chemistry Essentials',
    description: 'Learn the core concepts of chemistry',
    totalLessons: 7,
    completedLessons: 0,
    progress: 0.0,
    iconColor: const Color(0xFF4CAF50),
    icon: Icons.science,
    lessons: [
      Lesson(
        title: 'Atomic Structure',
        duration: '22 min',
        questions: 20,
        isLocked: false,
        // HIER: Zuweisung der Quiz-Fragen
        quizQuestions: atomicStructureQuiz,
      ),
      Lesson(
        title: 'Chemical Bonding',
        duration: '28 min',
        questions: 25,
        isLocked: false,
      ),
      Lesson(
        title: 'Chemical Reactions',
        duration: '32 min',
        questions: 28,
        isLocked: true,
      ),
      Lesson(
        title: 'Thermodynamics',
        duration: '40 min',
        questions: 35,
        isLocked: true,
      ),
    ],
  ),
  Module(
    title: 'Biology Basics',
    description: 'Understand the fundamentals of life',
    totalLessons: 5,
    completedLessons: 5,
    progress: 1.0,
    iconColor: const Color(0xFF4CAF50),
    icon: Icons.local_florist,
    isCompleted: true,
  ),
];

// --- 3. WIDGETS ---

// Widget für eine einzelne Lektion (NUR für die Vorschau auf dem ModuleListScreen)
class LessonTile extends StatelessWidget {
  final Lesson lesson;

  const LessonTile({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors
            .scaffoldBackgroundColor, // Hellerer Hintergrund für die Liste
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. STATUS ICON (Links)
          Padding(
            padding: const EdgeInsets.only(top: 2.0, right: 12.0),
            child: Icon(leadingIcon, size: 20, color: iconColor),
          ),

          // 2. TITEL & METADATEN
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDimmed ? Colors.grey.shade500 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
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
        ],
      ),
    );
  }
}

// Ändere die ModuleCard Klasse:

class ModuleCard extends StatefulWidget {
  final Module module;
  final Function(int)? onDelete;
  final bool showDeleteButton;

  const ModuleCard({
    super.key,
    required this.module,
    this.onDelete,
    this.showDeleteButton = false,
  });

  @override
  State<ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<ModuleCard> {
  bool _isHovering = false;
  bool _isCheckingAvailability = false;
  bool _canBeDeleted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkIfCanBeDeleted();
  }

  void _checkIfCanBeDeleted() async {
    if (widget.module.id != null) {
      setState(() => _isCheckingAvailability = true);

      final backend = Provider.of<BackendProvider>(context, listen: false);
      final canDelete = await backend.isModuleAvailableToUser(widget.module.id!);

      if (mounted) {
        setState(() {
          _canBeDeleted = canDelete;
          _isCheckingAvailability = false;
        });
      }
    }
  }

  void _navigateToLessons(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonListScreen(module: widget.module),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) async {
    if (!_canBeDeleted) return;

    final backend = Provider.of<BackendProvider>(context, listen: false);
    final isDefault = await backend.isModuleDefault(widget.module.id!);

    String message = 'Möchtest du das Modul "${widget.module.title}" wirklich entfernen?\n\n';

    if (isDefault) {
      message += 'Dies ist ein Standard-Modul. Es wird nur für dich entfernt und kann später wieder importiert werden.';
    } else {
      message += 'Dies ist ein importiertes Modul. Es wird komplett gelöscht und kann nicht wiederhergestellt werden.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDefault ? 'Standard-Modul entfernen' : 'Modul löschen'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await backend.deleteModule(
                widget.module.id!,
                widget.module.title,
              );

              if (success && widget.onDelete != null) {
                widget.onDelete!(widget.module.id!);
              }

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isDefault
                          ? '${widget.module.title} wurde entfernt'
                          : '${widget.module.title} wurde gelöscht',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(isDefault ? 'Entfernen' : 'Löschen'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    if (_isCheckingAvailability) {
      return const Padding(
        padding: EdgeInsets.only(right: 8.0, top: 10),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      onSelected: (value) {
        if (value == 'delete') {
          _showDeleteDialog(context);
        }
      },
      itemBuilder: (context) {
        // Füge einen Debug-Eintrag hinzu um zu sehen, was passiert
        return [
          if (_canBeDeleted)
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Modul löschen'),
                ],
              ),
            )
          else
            PopupMenuItem<String>(
              enabled: false,
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kann nicht gelöscht werden',
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                      Text(
                        'ID: ${widget.module.id}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasLessons = widget.module.lessons.isNotEmpty;
    bool shouldExpandOnHover = _isHovering && hasLessons;

    return MouseRegion(
      onEnter: (event) {
        if (hasLessons) setState(() => _isHovering = true);
      },
      onExit: (event) {
        if (hasLessons) setState(() => _isHovering = false);
      },
      child: GestureDetector(
        onTap: () => _navigateToLessons(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER des Moduls ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.module.iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.module.icon,
                      color: widget.module.iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.module.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (widget.module.isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Completed',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.module.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Progress Bar
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: widget.module.progress,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.module.progress == 1.0
                                      ? Colors.green
                                      : widget.module.iconColor,
                                ),
                                borderRadius: BorderRadius.circular(5),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(widget.module.progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: widget.module.progress == 1.0
                                    ? Colors.green
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${widget.module.completedLessons}/${widget.module.totalLessons} lessons',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Löschen-Button (immer anzeigen, aber ggf. deaktiviert)
                  _buildDeleteButton(context),
                  // Navigations-Button
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 10),
                    child: Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              // Optional: Lektionen anzeigen bei Hover
              if (shouldExpandOnHover && hasLessons)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    ...widget.module.lessons.map(
                          (lesson) => LessonTile(lesson: lesson),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ändere die ModuleListScreen Klasse:

class ModuleListScreen extends StatefulWidget {
  const ModuleListScreen({super.key});

  @override
  State<ModuleListScreen> createState() => _ModuleListScreenState();
}

class _ModuleListScreenState extends State<ModuleListScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  Future<void> _refreshModules() async {
    final backend = context.read<BackendProvider>();
    await backend.fetchModules();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(gradient: AppColors.darkOverlayGradient),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CustomAppBar(
            title: 'Browse Modules',
            subtitle: 'Explore and learn from our comprehensive module library',
            showBackButton: true,
            backgroundColor: Colors.white,
            actions: [AppBarActions(iconColor: Colors.black)],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/import-modules');
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.download, color: Colors.white),
          ),
          body: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _refreshModules,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    Consumer<BackendProvider>(
                      builder: (context, provider, _) {
                        if (provider.isLoading) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          ));
                        }

                        if (provider.error != null) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Icon(Icons.error, size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text('Fehler: ${provider.error}'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _refreshModules,
                                  child: const Text('Erneut versuchen'),
                                ),
                              ],
                            ),
                          );
                        }

                        final modules = provider.lastModules.map((lm) {
                          return Module(
                            id: lm.id,
                            title: lm.name,
                            description: lm.description ?? '',
                            totalLessons: 0,
                            completedLessons: 0,
                            progress: 0.0,
                            iconColor: Colors.blue,
                            icon: Icons.book,
                          );
                        }).toList();

                        if (modules.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                const Icon(Icons.library_books, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'Keine Module gefunden',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Importiere neue Module über das Download-Symbol',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/import-modules');
                                  },
                                  icon: const Icon(Icons.download),
                                  label: const Text('Module importieren'),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            // Info Text
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info, color: Colors.blue, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Module können über die drei Punkte gelöscht werden',
                                      style: TextStyle(
                                        color: Colors.blue[800],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Module Liste
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: modules.length,
                              itemBuilder: (context, index) {
                                return ModuleCard(
                                  module: modules[index],
                                  showDeleteButton: true,
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}