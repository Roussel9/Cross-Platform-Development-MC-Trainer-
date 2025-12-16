import 'package:flutter/material.dart'; // Benötigt für Color und IconData

// --- DATEN MODELLE ---
class Option {
  final String text;
  final String label;
  final bool isCorrect;

  Option({required this.text, required this.label, this.isCorrect = false});
}

class Question {
  final String questionText;
  final List<Option> options;
  final int correctOptionIndex;
  final String? explanation;
  int? selectedOptionIndex;

  Question({
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    this.explanation,
    this.selectedOptionIndex,
  });
}

class Lesson {
  final String title;
  final String duration;
  final int questions;
  final bool isCompleted;
  final bool isLocked;
  final List<Question> quizQuestions;

  Lesson({
    required this.title,
    required this.duration,
    required this.questions,
    this.isCompleted = false,
    this.isLocked = false,
    this.quizQuestions = const [],
  });
}

class Module {
  final String title;
  final String description;
  final int totalLessons;
  final int completedLessons;
  final double progress;
  final Color iconColor;
  final IconData icon;
  final List<Lesson> lessons;
  final bool isCompleted;

  Module({
    required this.title,
    required this.description,
    required this.totalLessons,
    required this.completedLessons,
    required this.progress,
    required this.iconColor,
    required this.icon,
    this.lessons = const [],
    this.isCompleted = false,
  });
}
