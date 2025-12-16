import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle; // Erlaubt null
  final bool showBackButton;
  final Color backgroundColor;
  final List<Widget>? actions; // Erlaubt null

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.backgroundColor = Colors.white,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    // Sicherstellen, dass die Actions nicht null sind, wenn sie an AppBar übergeben werden
    final List<Widget> finalActions = actions ?? [];

    return AppBar(
      // Elevation nur, wenn Hintergrund nicht transparent ist
      elevation: backgroundColor == Colors.transparent ? 0 : 2,
      backgroundColor: backgroundColor,
      // Korrekte Berechnung der Höhe (Höher, wenn Untertitel existiert)
      toolbarHeight: subtitle != null ? 80 : 56,

      leading: showBackButton
          ? IconButton(
              // Logik zur Farbauswahl für den Back Button
              icon: Icon(
                Icons.arrow_back,
                color: backgroundColor == Colors.transparent
                    ? Colors.white
                    : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            )
          : null,

      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              // Logik zur Farbauswahl für den Titel
              color: backgroundColor == Colors.transparent
                  ? Colors.white
                  : Colors.black87,
              fontSize: 20,
            ),
          ),
          // HIER IST DER WICHTIGE NULL-CHECK: Nur anzeigen, wenn subtitle NICHT null ist
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                color: backgroundColor == Colors.transparent
                    ? Colors.white.withOpacity(0.8)
                    : Colors.grey,
                fontSize: 12,
              ),
            ),
        ],
      ),
      actions: finalActions, // Verwenden der nicht-nullbaren Liste
    );
  }

  @override
  // Dies muss exakt zur toolbarHeight Logik passen!
  Size get preferredSize => Size.fromHeight(subtitle != null ? 80.0 : 56.0);
}
