// features/modules/screens/import_modules_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mc_trainer_kami/provider/backend_provider.dart';
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/core/widgets/custom_app_appbar.dart';
import 'package:mc_trainer_kami/models/importable_module.dart';

class ImportModulesScreen extends StatefulWidget {
  const ImportModulesScreen({super.key});

  @override
  State<ImportModulesScreen> createState() => _ImportModulesScreenState();
}

class _ImportModulesScreenState extends State<ImportModulesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ImportableModule> _filteredModules = [];
  bool _isSelectionMode = false;
  final Set<int> _selectedModuleIds = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackendProvider>().fetchImportableModules();
    });

    // Listener für die Sucheingabe
    _searchController.addListener(_filterModules);

    // WICHTIG: Listener für Provider-Änderungen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BackendProvider>();

      // Füge einen Listener hinzu, der auf Änderungen reagiert
      provider.addListener(() {
        if (mounted) {
          // Aktualisiere die gefilterte Liste, wenn sich die availableModules ändern
          _filterModules();
          setState(() {});
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterModules() {
    final provider = context.read<BackendProvider>();
    final searchText = _searchController.text.toLowerCase().trim();

    if (mounted) {
      setState(() {
        if (searchText.isEmpty) {
          _filteredModules = List.from(provider.availableModules);
        } else {
          // Erstelle eine Liste von Modulen mit Prioritäts-Scores
          final List<Map<String, dynamic>> moduleScores = [];

          for (var module in provider.availableModules) {
            int score = 0;
            final lowerTitle = module.title.toLowerCase();
            final lowerDescription = module.description.toLowerCase();

            // PRIORITÄT 1: Beginnt mit Suchtext (höchste Priorität)
            if (lowerTitle.startsWith(searchText)) {
              score = 100;
            }
            // PRIORITÄT 2: Enthält Suchtext im Titel (mittlere Priorität)
            else if (lowerTitle.contains(searchText)) {
              score = 50;
            }
            // PRIORITÄT 3: Enthält Suchtext in der Beschreibung (niedrigste Priorität)
            else if (lowerDescription.contains(searchText)) {
              score = 10;
            }

            if (score > 0) {
              moduleScores.add({
                'module': module,
                'score': score,
                'title': lowerTitle,
              });
            }
          }

          // Sortiere nach Score (absteigend), dann alphabetisch nach Titel
          moduleScores.sort((a, b) {
            if (a['score'] != b['score']) {
              return (b['score'] as int).compareTo(a['score'] as int);
            }
            return (a['title'] as String).compareTo(b['title'] as String);
          });

          _filteredModules = moduleScores.map((item) => item['module'] as ImportableModule).toList();
        }
      });
    }
  }

  bool _isSelectable(ImportableModule module) {
    return !module.isImported && !module.isDefault;
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
    });
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
        if (_selectedModuleIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedModuleIds.add(moduleId);
      }
    });
  }

  void _selectAllVisible() {
    setState(() {
      _selectedModuleIds
        ..clear()
        ..addAll(
          _filteredModules
              .where(_isSelectable)
              .map((m) => m.id),
        );
      _isSelectionMode = _selectedModuleIds.isNotEmpty;
    });
  }

  Future<void> _importSelectedModules(BackendProvider provider) async {
    if (_selectedModuleIds.isEmpty) return;

    final selectedModules = _filteredModules
        .where((m) => _selectedModuleIds.contains(m.id))
        .toList();

    int successCount = 0;
    for (final module in selectedModules) {
      final success = await provider.importModule(module);
      if (success) {
        successCount++;
      }
    }

    if (!mounted) return;

    await provider.fetchImportableModules();
    _filterModules();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$successCount von ${selectedModules.length} Modulen importiert',
        ),
        backgroundColor: successCount == selectedModules.length
            ? Colors.green
            : Colors.orange,
      ),
    );

    _exitSelectionMode();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Module suchen...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildImportableModuleCard(
    BuildContext context,
    ImportableModule module,
    BackendProvider provider,
    bool isSelected,
  ) {
    // Prüfe ob der Suchtext im Titel vorkommt
    final searchText = _searchController.text.toLowerCase();
    final moduleTitle = module.title.toLowerCase();

    Widget titleWidget;
    if (searchText.isNotEmpty && moduleTitle.contains(searchText)) {
      // Hervorhebung des Suchtexts im Titel
      final matchStart = moduleTitle.indexOf(searchText);
      final matchEnd = matchStart + searchText.length;

      titleWidget = RichText(
        text: TextSpan(
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: module.isDefault ? Colors.blue[800] : Colors.black87,
          ),
          children: [
            if (matchStart > 0)
              TextSpan(
                text: module.title.substring(0, matchStart),
              ),
            TextSpan(
              text: module.title.substring(matchStart, matchEnd),
              style: const TextStyle(
                backgroundColor: Colors.yellow,
                color: Colors.black,
              ),
            ),
            if (matchEnd < module.title.length)
              TextSpan(
                text: module.title.substring(matchEnd),
              ),
          ],
        ),
      );
    } else {
      titleWidget = Text(
        module.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: module.isDefault ? Colors.blue[800] : Colors.black87,
        ),
      );
    }

    final selectable = _isSelectable(module);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onLongPress: selectable
            ? () {
                if (!_isSelectionMode) {
                  _enterSelectionMode();
                }
                _toggleSelection(module.id);
              }
            : null,
        onTap: () {
          if (_isSelectionMode && selectable) {
            _toggleSelection(module.id);
          }
        },
        contentPadding: const EdgeInsets.all(16),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isSelectionMode)
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _parseColor(module.color),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIcon(module.icon),
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
        title: titleWidget,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              module.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (module.isImported)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Importiert',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else if (module.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.library_books, color: Colors.blue[700], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Bereits vorhanden',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: _isSelectionMode
            ? Icon(
                selectable
                    ? (isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked)
                    : Icons.lock,
                color: selectable
                    ? (isSelected ? Colors.blue : Colors.grey)
                    : Colors.grey.shade400,
              )
            : module.isImported
                ? const Icon(Icons.check, color: Colors.green)
                : module.isDefault
                    ? const Icon(Icons.check, color: Colors.blue)
                    : ElevatedButton(
                        onPressed: () async {
                          // WICHTIG: Setze loading state
                          setState(() {});

                          final success = await provider.importModule(module);

                          if (success && mounted) {
                            // WICHTIG: Nach erfolgreichem Import, aktualisiere die Liste
                            await provider.fetchImportableModules();

                            // Aktualisiere die gefilterte Liste
                            _filterModules();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('${module.title} wurde importiert!'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else if (!success && mounted &&
                              provider.error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(provider.error!),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }

                          // WICHTIG: Setze state zurück
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColorLight,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: provider.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Importieren'),
                      ),
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Module gefunden für "${_searchController.text}"',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Versuche einen anderen Suchbegriff',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              _searchController.clear();
            },
            child: const Text('Alle Module anzeigen'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Module verfügbar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stelle sicher, dass du mit dem Internet verbunden bist',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'calculate': return Icons.calculate;
      case 'science': return Icons.science;
      case 'biotech': return Icons.biotech;
      case 'psychology': return Icons.psychology;
      case 'computer': return Icons.computer;
      case 'history_edu': return Icons.history_edu;
      case 'menu_book': return Icons.menu_book;
      default: return Icons.book;
    }
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', ''), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackgroundColor,
      appBar: _isSelectionMode
          ? AppBar(
              title: Text('${_selectedModuleIds.length} ausgewählt'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              actions: [
                if (_selectedModuleIds.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {
                      final provider =
                          Provider.of<BackendProvider>(context, listen: false);
                      _importSelectedModules(provider);
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _selectAllVisible,
                ),
              ],
            )
          : CustomAppBar(
              title: 'Module Importieren',
              subtitle: 'Lade neue Lernmodule von unserem Server',
              showBackButton: true,
            ),
      body: Consumer<BackendProvider>(
        builder: (context, provider, _) {
          // Initialisiere gefilterte Module
          if (_filteredModules.isEmpty && provider.availableModules.isNotEmpty) {
            _filteredModules = provider.availableModules;
          }

          return Column(
            children: [
              // Suchleiste
              _buildSearchBar(),

              // Anzahl der gefundenen Module
              if (_searchController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_filteredModules.length} Module gefunden',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                          },
                          child: const Text('Zurücksetzen'),
                        ),
                    ],
                  ),
                ),

              // Hauptinhalt
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await provider.fetchImportableModules();
                    _filterModules(); // Nach dem Neuladen Filter aktualisieren
                  },
                  child: _buildContent(provider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BackendProvider provider) {
    if (provider.isLoading && provider.availableModules.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetchImportableModules(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColorLight,
                foregroundColor: Colors.white,
              ),
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (provider.availableModules.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 32),
          _buildEmptyState(),
        ],
      );
    }

    if (_searchController.text.isNotEmpty && _filteredModules.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 32),
          _buildNoResultsFound(),
        ],
      );
    }

    return ListView(
      children: [
        if (_searchController.text.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Verfügbare Module:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Suchergebnisse für "${_searchController.text}":',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
          ),

        // Module-Liste
        ..._filteredModules.map(
          (module) => _buildImportableModuleCard(
            context,
            module,
            provider,
            _selectedModuleIds.contains(module.id),
          ),
        ),

        // Info-Karte
        if (_searchController.text.isEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Importierte Module werden auf deinem Gerät gespeichert '
                          'und sind auch offline verfügbar. '
                          'Du kannst importierte Module jederzeit in den Moduleinstellungen löschen.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}