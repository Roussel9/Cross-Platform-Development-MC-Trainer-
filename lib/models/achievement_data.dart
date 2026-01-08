import 'package:flutter/material.dart'; // Benötigt für Color und IconData

class Achievement {
  final int id;
  final String title;
  final String description;
  final IconData? icon;
  final Color? color;
  final bool isUnlocked;
  final DateTime? unlockedDate;
  final int points;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.icon,
    this.color,
    required this.isUnlocked,
    this.unlockedDate,
    required this.points,
  });
}
