// features/modules/screens/import_modules_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mc_trainer_kami/provider/backend_provider.dart';
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/core/widgets/custom_app_appbar.dart';
import 'package:mc_trainer_kami/models/importable_module.dart'; // WICHTIG: Diesen Import hinzufügen

class ImportModulesScreen extends StatefulWidget {
  const ImportModulesScreen({super.key});

  @override
  State<ImportModulesScreen> createState() => _ImportModulesScreenState();
}

class _ImportModulesScreenState extends State<ImportModulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackendProvider>().fetchImportableModules();
    });
  }

  // In import_modules_screen.dart, ändere die _buildImportableModuleCard Methode:

  Widget _buildImportableModuleCard(
      BuildContext context,
      ImportableModule module,
      BackendProvider provider,
      ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
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
        title: Text(
          module.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: module.isDefault ? Colors.blue[800] : Colors.black87,
          ),
        ),
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
        trailing: module.isImported
            ? const Icon(Icons.check, color: Colors.green)
            : module.isDefault
            ? const Icon(Icons.check, color: Colors.blue)
            : ElevatedButton(
          onPressed: () async {
            final success = await provider.importModule(module);
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${module.title} wurde importiert!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (!success && mounted && provider.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.error!),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColorLight,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Importieren'),
        ),
      ),
    );
  }
  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'calculate': return Icons.calculate;
      case 'science': return Icons.science;
      case 'biotech': return Icons.biotech;
      case 'psychology': return Icons.psychology;
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
      appBar: CustomAppBar(
        title: 'Module Importieren',
        subtitle: 'Lade neue Lernmodule von unserem Server',
        showBackButton: true,
      ),
      body: Consumer<BackendProvider>(
        builder: (context, provider, _) {
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

          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchImportableModules();
            },
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Verfügbare Module zum Import:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (provider.availableModules.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Keine Module verfügbar',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Stelle sicher, dass du mit dem Internet verbunden bist',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...provider.availableModules.map(
                        (module) => _buildImportableModuleCard(context, module, provider),
                  ),
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
              ],
            ),
          );
        },
      ),
    );
  }
}