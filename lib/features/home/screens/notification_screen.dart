import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/app_notifications.dart';
import '../../../provider/backend_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  AppNotification? _selectedNotification;

  @override
  void initState() {
    super.initState();
    // Dein Provider-Aufruf nach dem ersten Frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackendProvider>().fetchHomeData();
    });
  }

  void _handleSelect(AppNotification notification) {
    setState(() {
      context.read<BackendProvider>().setNotificationToRead(notification.id);
      _selectedNotification = notification;
      notification.isRead = true;
    });
  }

  void _deleteNotification(AppNotification note) {
    context.read<BackendProvider>().deleteNotification(note.id);
    if (_selectedNotification == note) {
      setState(() => _selectedNotification = null);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gelöscht'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backend = context.watch<BackendProvider>();
    final isSplitView = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Benachrichtigungen',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (backend.notifications.isNotEmpty)
            TextButton(
              onPressed: () => {
                backend.clearAllNotification(),
                backend.notifications.clear(),
              },
              child: const Text(
                'Alle löschen',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
        ],
      ),
      body: backend.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // MASTER: Liste
                Expanded(
                  flex: isSplitView ? 2 : 1,
                  child: backend.notifications.isEmpty
                      ? const Center(child: Text('Keine Nachrichten'))
                      : _buildList(backend.notifications, isSplitView),
                ),
                // DETAIL: Mailbox-Ansicht
                if (isSplitView)
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: _buildDetailView(),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildList(List<AppNotification> notes, bool isSplitView) {
    return ListView.separated(
      itemCount: notes.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final note = notes[index];
        final isSelected = _selectedNotification == note;

        return Dismissible(
          key: Key('${note.id}'), // Sicherer Key-Fix
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.redAccent,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.red),
          ),
          onDismissed: (_) => _deleteNotification(note),
          child: ListTile(
            onTap: () {
              _handleSelect(note);
              if (!isSplitView) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MobileDetailScreen(
                      notification: note,
                      onDelete: () => _deleteNotification(note),
                    ),
                  ),
                );
              }
            },
            tileColor: isSelected && isSplitView
                ? Colors.blue.withOpacity(0.05)
                : Colors.white,
            leading: CircleAvatar(
              backgroundColor: note.isRead
                  ? Colors.grey.shade100
                  : Colors.blue.shade50,
              child: Icon(
                note.isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active,
                color: note.isRead ? Colors.grey : Colors.blue,
              ),
            ),
            title: Text(
              note.title,
              style: TextStyle(
                fontWeight: note.isRead ? FontWeight.normal : FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              note.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red,
              ),
              onPressed: () => _deleteNotification(note),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailView() {
    if (_selectedNotification == null)
      return const Center(child: Text('Wähle eine Nachricht aus'));

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat(
                  'dd.MM.yyyy, HH:mm',
                ).format(_selectedNotification!.createdAt),
                style: const TextStyle(color: Colors.grey),
              ),
              TextButton.icon(
                onPressed: () => _deleteNotification(_selectedNotification!),
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Löschen',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _selectedNotification!.title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 40),
          Text(
            _selectedNotification!.message,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// 📄 4. Mobile Detail Ansicht
class MobileDetailScreen extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onDelete;

  const MobileDetailScreen({
    super.key,
    required this.notification,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd.MM.yyyy HH:mm').format(notification.createdAt),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              notification.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 40),
            Text(notification.message, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
