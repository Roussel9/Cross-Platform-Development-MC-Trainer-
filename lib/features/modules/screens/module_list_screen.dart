// features/modules/screens/module_list_screen.dart (VOLLSTÄNDIG KORRIGIERT für Hover/Click-Hybrid)

import 'package:flutter/material.dart';
import 'package:mc_trainer_kami/models/module_data.dart';
import 'package:mc_trainer_kami/models/lernen_module.dart';
import 'package:mc_trainer_kami/provider/backend_provider.dart';
import 'package:provider/provider.dart';
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/core/widgets/custom_app_appbar.dart';
import 'package:mc_trainer_kami/core/widgets/app_bar_actions.dart';
import 'package:share_plus/share_plus.dart';
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

// Widget für eine Modul-Karte (mit Aufklappfunktion und Navigation)
class ModuleCard extends StatefulWidget {
  final Module module;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool selectionMode;

  const ModuleCard({
    super.key,
    required this.module,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.selectionMode = false,
  });

  @override
  State<ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<ModuleCard> {
  final bool _isExpanded = false;
  bool _isHovering = false;

  // Funktion zum Navigieren
  void _navigateToLessons(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonListScreen(module: widget.module),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasLessons = widget.module.lessons.isNotEmpty;
    // Soll aufklappen, wenn wir hovern (Desktop)
    bool shouldExpandOnHover = _isHovering && hasLessons;
    // Soll angezeigt werden, wenn Hover (Desktop) oder wenn bereits getippt (Mobile)
    bool isExpanded = _isExpanded || shouldExpandOnHover;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isSelected ? Colors.blue.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: widget.isSelected
            ? Border.all(color: Colors.blue, width: 1.5)
            : null,
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
          // --- HEADER des Moduls (immer sichtbar) ---
          MouseRegion(
            // 1. HOVER (Desktop): Setze _isHovering auf true/false
            onEnter: (event) {
              if (hasLessons) setState(() => _isHovering = true);
            },
            onExit: (event) {
              if (hasLessons) setState(() => _isHovering = false);
            },
            child: GestureDetector(
              // 2. TAP (Mobile/Desktop): Navigiere zur Detailseite
              onTap: widget.onTap ?? () => _navigateToLessons(context),
              onLongPress: widget.onLongPress,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon und Progress Bar (Rest der Logik bleibt gleich)
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
                  // Chevron-Icon oder Auswahlstatus
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 10),
                    child: widget.selectionMode
                        ? Icon(
                            widget.isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: widget.isSelected
                                ? Colors.blue
                                : Colors.grey,
                          )
                        : const Icon(
                            Icons.keyboard_arrow_right,
                            color: Colors.grey,
                          ),
                  ),
                ],
              ),
            ),
          ),

          // --- EXPANDABLE BODY (Aufklappbarer Bereich bei Hover) ---
          if (hasLessons && isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.module.lessons.map((lesson) {
                  return LessonTile(
                    lesson: lesson,
                  ); // Verwenden der lokalen LessonTile
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// --- 4. DER HAUPT-SCREEN ---
class ModuleListScreen extends StatefulWidget {
  const ModuleListScreen({super.key});

  @override
  State<ModuleListScreen> createState() => _ModuleListScreenState();
}

class _ModuleListScreenState extends State<ModuleListScreen> {
  String _query = '';
  final Set<int> _selectedModuleIds = {};
  final Map<int, String> _moduleTitles = {};

  bool get _selectionMode => _selectedModuleIds.isNotEmpty;

  void _toggleModuleSelection(int? id) {
    if (id == null) return;
    setState(() {
      if (_selectedModuleIds.contains(id)) {
        _selectedModuleIds.remove(id);
      } else {
        _selectedModuleIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedModuleIds.clear();
    });
  }

  Future<void> _deleteSelectedModules(BackendProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Module löschen?'),
          content: Text(
            'Möchtest du ${_selectedModuleIds.length} Modul(e) wirklich löschen?',
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
      await provider.deleteModules(_selectedModuleIds.toList());
      _clearSelection();
    }
  }

  Future<void> _shareSelectedModules() async {
    final titles = _selectedModuleIds
        .map((id) => _moduleTitles[id])
        .whereType<String>()
        .toList();
    if (titles.isEmpty) return;
    final text = 'Meine Module:\n- ${titles.join('\n- ')}';
    await Share.share(text);
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
          appBar: _selectionMode
              ? AppBar(
                  title: Text('${_selectedModuleIds.length} selected'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearSelection,
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteSelectedModules(
                        Provider.of<BackendProvider>(context, listen: false),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: _shareSelectedModules,
                    ),
                  ],
                )
              : CustomAppBar(
                  title: 'Browse Modules',
                  subtitle:
                      'Explore and learn from our comprehensive module library',
                  showBackButton: true,
                  backgroundColor: Colors.white,
                  actions: [AppBarActions(iconColor: Colors.black)],
                ),
          body: SingleChildScrollView(
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  // Suchleiste
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _query = value.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Module suchen...',
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
                  Consumer<BackendProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (provider.error != null) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Fehler: ${provider.error}'),
                        );
                      }

                      debugPrint(
                        'ModuleListScreen: provider.lastModules.length = ${provider.lastModules.length}',
                      );

                      // Laden der Fortschritte aus Supabase
                      return FutureBuilder<Map<int, Map<String, dynamic>>>(
                        future: provider.loadUserProgressForModules(
                          provider.lastModules,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            debugPrint(
                              '❌ Error loading progress: ${snapshot.error}',
                            );
                            // Fallback ohne Fortschritte
                            return _buildModuleList(provider.lastModules, {});
                          }

                          final progressMap = snapshot.data ?? {};
                          final filteredModules = _query.isEmpty
                              ? provider.lastModules
                              : provider.lastModules.where((m) {
                                  final name = m.name.toLowerCase();
                                  final desc = (m.description ?? '')
                                      .toLowerCase();
                                  final q = _query.toLowerCase();
                                  return name.contains(q) || desc.contains(q);
                                }).toList();
                          return _buildModuleList(filteredModules, progressMap);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Baut die Liste der Module mit Fortschritten
  Widget _buildModuleList(
    List<LernenModule> lernenModules,
    Map<int, Map<String, dynamic>> progressMap,
  ) {
    // Konvertiere LernenModule -> lokale Module-View-Model mit Fortschritten
    final modules = lernenModules.map((lm) {
      final progress = progressMap[lm.id];
      final moduleProgress = (progress?['progress'] as double?) ?? 0.0;
      final isCompleted = moduleProgress >= 1.0;

      if (lm.id != null) {
        _moduleTitles[lm.id] = lm.name;
      }

      return Module(
        id: lm.id,
        title: lm.name,
        description: lm.description ?? '',
        totalLessons: 0,
        completedLessons: 0,
        progress: moduleProgress,
        iconColor: Colors.blue,
        icon: Icons.book,
        isCompleted: isCompleted,
      );
    }).toList();

    if (modules.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No modules found.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return ModuleCard(
          module: module,
          selectionMode: _selectionMode,
          isSelected:
              module.id != null && _selectedModuleIds.contains(module.id),
          onTap: () {
            if (_selectionMode) {
              _toggleModuleSelection(module.id);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LessonListScreen(module: module),
                ),
              );
            }
          },
          onLongPress: () => _toggleModuleSelection(module.id),
        );
      },
    );
  }
}
