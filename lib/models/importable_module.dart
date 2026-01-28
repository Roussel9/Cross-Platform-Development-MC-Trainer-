

class ImportableModule {
  final int id;
  final String title;
  final String description;
  final String icon;
  final String color;
  final bool isDefault;
  final bool isImported;
  final bool isDeleted;
  final String? serverUrl;

  ImportableModule({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isDefault,
    required this.isImported,
    this.isDeleted = false,
    this.serverUrl,
  });

 
  ImportableModule copyWith({
    int? id,
    String? title,
    String? description,
    String? icon,
    String? color,
    bool? isDefault,
    bool? isImported,
    bool? isDeleted,
    String? serverUrl,
  }) {
    return ImportableModule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      isImported: isImported ?? this.isImported,
      isDeleted: isDeleted ?? this.isDeleted,
      serverUrl: serverUrl ?? this.serverUrl,
    );
  }
}