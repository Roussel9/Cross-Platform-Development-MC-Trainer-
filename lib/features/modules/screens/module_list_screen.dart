// features/modules/screens/module_list_screen.dart (VOLLSTÄNDIG KORRIGIERT für Hover/Click-Hybrid)

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mc_trainer_kami/models/module_data.dart';
import 'package:mc_trainer_kami/models/lernen_module.dart';
import 'package:mc_trainer_kami/provider/backend_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/core/widgets/custom_app_appbar.dart';
import 'package:mc_trainer_kami/core/widgets/app_bar_actions.dart';
// Import des neuen Lesson Screens für die Navigation
import 'lesson_list_screen.dart';

// --- WIDGETS ---

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
                      '${lesson.questions} Fragen',
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
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const ModuleCard({
    super.key,
    required this.module,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onLongPress,
    this.onTap,
  });

  @override
  State<ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<ModuleCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    bool hasLessons = widget.module.lessons.isNotEmpty;
    bool shouldExpandOnHover =
        _isHovering && hasLessons && !widget.isSelectionMode;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: MouseRegion(
        onEnter: widget.isSelectionMode
            ? null
            : (event) {
                if (hasLessons) setState(() => _isHovering = true);
              },
        onExit: widget.isSelectionMode
            ? null
            : (event) {
                if (hasLessons) setState(() => _isHovering = false);
              },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isSelected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: widget.isSelected
                ? Border.all(color: Colors.blue, width: 2)
                : Border.all(color: Colors.transparent),
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
                  // Auswahl-Checkbox (nur im Auswahlmodus)
                  if (widget.isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 12, top: 8),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: widget.isSelected ? Colors.blue : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isSelected
                                ? Colors.blue
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: widget.isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),

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

                  // Modul-Informationen
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.module.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    widget.isSelectionMode && widget.isSelected
                                    ? Colors.blue.shade800
                                    : Colors.black87,
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
                                  'Abgeschlossen',
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
                            color: widget.isSelectionMode && widget.isSelected
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
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
                        if (widget.module.totalLessons > 0)
                          Text(
                            '${widget.module.completedLessons}/${widget.module.totalLessons} Lektionen',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Navigations-Button 
                  if (!widget.isSelectionMode)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, top: 10),
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



class ModuleListScreen extends StatefulWidget {
  const ModuleListScreen({super.key});

  @override
  State<ModuleListScreen> createState() => _ModuleListScreenState();
}

class _ModuleListScreenState extends State<ModuleListScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

 
  bool _isSelectionMode = false;
  Set<int> _selectedModuleIds = {};
  List<Module> _currentModules = []; 
  String _moduleQuery = '';

  bool _matchesModuleQuery(Module module, String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;

    final title = module.title.toLowerCase();
    final desc = module.description.toLowerCase();

    final titleWords = title.split(RegExp(r'\s+'));
    final descWords = desc.split(RegExp(r'\s+'));

    // 1) Titel-Präfixe bevorzugen
    if (titleWords.any((w) => w.startsWith(q))) return true;

    // 2) Titel-Teiltreffer nur bei längerer Eingabe
    if (q.length >= 3 && title.contains(q)) return true;

    // 3) Beschreibung nur bei längerer Eingabe und Wort-Präfix
    if (q.length >= 4 && descWords.any((w) => w.startsWith(q))) return true;

    return false;
  }

  Future<void> _refreshModules() async {
    final backend = context.read<BackendProvider>();
    await backend.fetchModules();
    _exitSelectionMode(); // Auswahlmodus beenden
  }

  Future<({int total, int completed, double progress})> _loadModuleProgress(
    Module module,
    BackendProvider provider,
  ) async {
    final moduleId = module.id;
    if (moduleId == null) {
      return (total: 0, completed: 0, progress: 0.0);
    }

    final submodules = await provider.fetchSubmodules(moduleId);
    if (submodules.isEmpty) {
      return (total: 0, completed: 0, progress: 0.0);
    }

    int completed = 0;
    for (final sub in submodules) {
      final isCompleted = await provider.isSubmoduleCompleted(sub['id']);
      if (isCompleted) completed++;
    }

    final total = submodules.length;
    final progress = total == 0 ? 0.0 : (completed / total);
    return (total: total, completed: completed, progress: progress);
  }

  //  METHODEN FÜR CAB
  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
    });
  }

  void _syncSelectionWithModules() {
    final validIds = _currentModules
        .map((m) => m.id)
        .whereType<int>()
        .toSet();
    final newSelected = _selectedModuleIds.intersection(validIds);

    if (!setEquals(newSelected, _selectedModuleIds)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedModuleIds = newSelected;
          if (_selectedModuleIds.isEmpty) {
            _isSelectionMode = false;
          }
        });
      });
    }
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedModuleIds.clear();
    });
  }

  void _toggleSelection(int moduleId) {
    setState(() {
      if (_selectedModuleIds.contains(moduleId)) {
        _selectedModuleIds.remove(moduleId);
        // Wenn keine Module mehr ausgewählt sind, CAB verlassen
        if (_selectedModuleIds.isEmpty) {
          _exitSelectionMode();
        }
      } else {
        _selectedModuleIds.add(moduleId);
      }
    });
  }

  void _selectAllModules() {
    setState(() {
      // _currentModules Verwenden 
      _selectedModuleIds = Set.from(
        _currentModules.map((m) => m.id ?? 0).where((id) => id > 0),
      );
    });
  }

  void _showDeleteDialog() async {
    final backend = Provider.of<BackendProvider>(context, listen: false);

    //  ausgewählte Module aus _currentModules finden 
    final selectedModules = _currentModules
        .where((m) => m.id != null && _selectedModuleIds.contains(m.id))
        .toList();

    String message =
        'Möchtest du die ausgewählten Module wirklich löschen?\n\n';
    message += 'Ausgewählt: ${selectedModules.length} Module\n';
    for (var module in selectedModules.take(3)) {
      message += '• ${module.title}\n';
    }
    if (selectedModules.length > 3) {
      message += '• ... und ${selectedModules.length - 3} weitere\n';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Module löschen'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              bool allSuccessful = true;
              for (var module in selectedModules) {
                if (module.id != null) {
                  final success = await backend.deleteModule(
                    module.id!,
                    module.title,
                  );
                  if (!success) {
                    allSuccessful = false;
                  }
                }
              }

              if (allSuccessful && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${selectedModules.length} Module wurden gelöscht',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                _exitSelectionMode();
                await backend.fetchModules();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  //  APP BAR FÜR CAB
  AppBar _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: Colors.blue,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: _exitSelectionMode,
      ),
      title: Text(
        '${_selectedModuleIds.length} ausgewählt',
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        if (_selectedModuleIds.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _showDeleteDialog,
          ),
        IconButton(
          icon: const Icon(Icons.select_all, color: Colors.white),
          onPressed: _selectAllModules,
        ),
      ],
    );
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
          appBar: _isSelectionMode
              ? _buildSelectionAppBar() 
              : CustomAppBar(
                  title: 'Browse Modules',
                  subtitle:
                      'Explore and learn from our comprehensive module library',
                  showBackButton: true,
                  backgroundColor: Colors.white,
                  actions: [AppBarActions(iconColor: Colors.black)],
                ),
          floatingActionButton: !_isSelectionMode
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/import-modules');
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.download, color: Colors.white),
                )
              : null,
          body: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _refreshModules,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Consumer<BackendProvider>(
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
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error,
                              size: 48,
                              color: Colors.red,
                            ),
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

                    // Module aus Provider laden und in _currentModules speichern
                    _currentModules = provider.lastModules.map((lm) {
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

                    _syncSelectionWithModules();

                    if (_currentModules.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.library_books,
                              size: 64,
                              color: Colors.grey,
                            ),
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

                    final userId =
                        Supabase.instance.client.auth.currentUser?.id;

                    final filteredModules = _moduleQuery.isEmpty
                      ? _currentModules
                      : _currentModules
                        .where((m) => _matchesModuleQuery(m, _moduleQuery))
                        .toList();

                    final listContent = Column(
                      children: [
                        TextField(
                          onChanged: (value) {
                            setState(() {
                              _moduleQuery = value.trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Module suchen...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _moduleQuery.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _moduleQuery = '';
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
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredModules.length,
                          itemBuilder: (context, index) {
                            final module = filteredModules[index];
                            return FutureBuilder<({
                              int total,
                              int completed,
                              double progress
                            })>(
                              future: _loadModuleProgress(module, provider),
                              builder: (context, snapshot) {
                                final data = snapshot.data;
                                final displayModule = Module(
                                  id: module.id,
                                  title: module.title,
                                  description: module.description,
                                  totalLessons: data?.total ?? 0,
                                  completedLessons: data?.completed ?? 0,
                                  progress: data?.progress ?? 0.0,
                                  iconColor: module.iconColor,
                                  icon: module.icon,
                                  lessons: module.lessons,
                                  isCompleted:
                                      (data?.progress ?? 0.0) >= 1.0,
                                );

                                return ModuleCard(
                                  module: displayModule,
                                  isSelected:
                                      module.id != null &&
                                      _selectedModuleIds.contains(module.id),
                                  isSelectionMode: _isSelectionMode,
                                  onLongPress: () {
                                    if (!_isSelectionMode) {
                                      _enterSelectionMode();
                                    }
                                    if (module.id != null) {
                                      _toggleSelection(module.id!);
                                    }
                                  },
                                  onTap: () async {
                                    if (_isSelectionMode && module.id != null) {
                                      _toggleSelection(module.id!);
                                      return;
                                    }

                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LessonListScreen(module: module),
                                      ),
                                    );
                                    if (!mounted) return;
                                    await provider.refreshAllProgress();
                                    setState(() {});
                                  },
                                );
                              },
                            );
                          },
                        ),
                        if (!_isSelectionMode) // Nur zeigen, wenn nicht im Auswahlmodus
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isSelectionMode
                                        ? 'Wähle Module aus zum Löschen'
                                        : 'Langer Klick auf ein Modul zum Auswählen',
                                    style: TextStyle(
                                      color: Colors.blue[800],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );

                    if (userId == null) {
                      return listContent;
                    }

                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: Supabase.instance.client
                          .from('learning_sessions')
                          .stream(primaryKey: ['id'])
                          .eq('user_id', userId),
                      builder: (context, _) {
                        return listContent;
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
