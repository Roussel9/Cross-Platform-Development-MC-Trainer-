import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mc_trainer_kami/provider/backend_provider.dart';
import 'package:mc_trainer_kami/features/home/screens/profile_screen.dart';

class AppBarActions extends StatelessWidget {
  final Color iconColor;

  const AppBarActions({super.key, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Consumer<BackendProvider>(
      builder: (context, provider, _) {
        final unread = provider.unreadNotificationsCount;

        return Row(
          children: [
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_none, color: iconColor),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) {
                        final items = provider.notifications;
                        return AlertDialog(
                          title: const Text('Benachrichtigungen'),
                          content: SizedBox(
                            width: 320,
                            child: items.isEmpty
                                ? const Text('Keine Benachrichtigungen.')
                                : ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: items.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 12),
                                    itemBuilder: (context, index) {
                                      final n = items[index];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(n.title),
                                        subtitle: Text(n.message),
                                      );
                                    },
                                  ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                              },
                              child: const Text('Schließen'),
                            ),
                          ],
                        );
                      },
                    ).then((_) => provider.markAllNotificationsRead());
                  },
                ),
                if (unread > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        unread > 9 ? '9+' : unread.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  radius: 15,
                  child: Text(
                    provider.userInitials.isNotEmpty
                        ? provider.userInitials
                        : 'JD',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
