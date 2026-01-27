class AppNotification {
  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    DateTime? createdAt,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now();
}
