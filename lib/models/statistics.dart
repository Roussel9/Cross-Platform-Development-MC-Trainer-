import 'package:flutter/material.dart'; // Benötigt für Color und IconData

// --- DATEN MODELLE ---
class Statistics {
  final int total_questions;
  final int correct_answered;
  final int incorrect_answered;
  final bool session_success;

  Statistics({
    required this.total_questions,
    required this.correct_answered,
    required this.incorrect_answered,
    required this.session_success,
  });
}
