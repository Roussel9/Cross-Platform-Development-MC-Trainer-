// models/importable_module.dart

class ImportableModule {
  final int id;
  final String title;
  final String description;
  final String icon;
  final String color;
  final bool isDefault;
  final bool isImported;
  final String? serverUrl;

  ImportableModule({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isDefault,
    required this.isImported,
    this.serverUrl,
  });
}