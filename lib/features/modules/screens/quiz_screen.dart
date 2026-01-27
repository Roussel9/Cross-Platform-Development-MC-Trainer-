import 'package:flutter/material.dart';
import 'dart:async'; // NEU: Für Timer
// Stellen Sie sicher, dass diese Imports zu Ihren tatsächlichen Dateien passen
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/models/module_data.dart';
import 'package:provider/provider.dart';
import 'package:mc_trainer_kami/provider/backend_provider.dart';

// =========================================================
// DATEN MODELLE (Wiederholt zur Vollständigkeit, falls benötigt)
// =========================================================

// Hier würden Ihre tatsächlichen Model-Klassen Option, Question, Lesson, Module stehen,
// importiert aus 'package:mc_trainer_kami/models/module_data.dart'.
// Da Sie diese importiert haben, lasse ich sie hier weg, um Doppeldefinitionen zu vermeiden.

// =========================================================
// HILFSFUNKTION FÜR KORREKTEN INDEX
// =========================================================

int _getCorrectIndex(List<Option> options) {
  final correctIndex = options.indexWhere((opt) => opt.isCorrect);
  return correctIndex == -1 ? 0 : correctIndex;
}

// NEU: Format Sekunden zu MM:SS
String _formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

// =========================================================
// WIEDERVERWENDBARE WIDGETS
// =========================================================

// 1. Option Card (Für den aktiven Quiz-Modus)
class OptionCard extends StatelessWidget {
  final Option option;
  final bool isSelected;
  final VoidCallback onTap;

  const OptionCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color highlightColor = Colors.blue;
    final Color backgroundColor = isSelected
        ? highlightColor.withOpacity(0.1)
        : Colors.white;
    final Color borderColor = isSelected
        ? highlightColor
        : Colors.grey.shade200;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              alignment: Alignment.center,
              child: Text(
                '${option.label}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? highlightColor : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                option.text,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. Question Stepper
class QuestionStepper extends StatelessWidget {
  final int totalQuestions;
  final int currentQuestionIndex;
  final Function(int) onStepTap;

  const QuestionStepper({
    super.key,
    required this.totalQuestions,
    required this.currentQuestionIndex,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color highlightColor = Colors.blue;

    return SizedBox(
      height: 40,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: totalQuestions,
        itemBuilder: (context, index) {
          final questionNumber = index + 1;
          final isCurrent = index == currentQuestionIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () => onStepTap(index),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCurrent ? highlightColor : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrent ? highlightColor : Colors.grey.shade300,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$questionNumber',
                  style: TextStyle(
                    color: isCurrent ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 3. Review Option Card
class ReviewOptionCard extends StatelessWidget {
  final Option option;
  final bool isCorrect;
  final bool isSelected; // Vom Benutzer gewählte Option

  const ReviewOptionCard({
    super.key,
    required this.option,
    required this.isCorrect,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    Color borderColor;
    IconData icon;
    Color statusColor;
    String statusText = '';

    if (isCorrect) {
      cardColor = Colors.green.withOpacity(0.1);
      borderColor = Colors.green;
      icon = Icons.check_circle;
      statusColor = Colors.green;
      statusText = 'Correct Answer';
    } else if (isSelected) {
      cardColor = Colors.red.withOpacity(0.1);
      borderColor = Colors.red;
      icon = Icons.cancel;
      statusColor = Colors.red;
      statusText = 'Your Answer';
    } else {
      cardColor = Colors.white;
      borderColor = Colors.grey.shade200;
      icon = Icons.circle_outlined;
      statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            alignment: Alignment.center,
            child: Text(
              '${option.label}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              option.text,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),

          if (isCorrect || isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: statusColor, size: 20),
                  const SizedBox(height: 4),
                  if (isSelected && !isCorrect)
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 10),
                    ),
                  if (isCorrect && !isSelected)
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 10),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// 4. Quiz Result Overlay (Popup nach Abschluss des Quiz) - Overflow-Fix für extreme Breiten
class QuizResultOverlay extends StatelessWidget {
  // ... [Konstruktor und Variablen bleiben unverändert] ...

  final int correctAnswers;
  final int totalQuestions;
  final String title;
  final int durationSeconds;
  final VoidCallback onReviewAnswers;
  final VoidCallback onRetryLesson;
  final VoidCallback onBackToModule;

  const QuizResultOverlay({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.title,
    required this.durationSeconds,
    required this.onReviewAnswers,
    required this.onRetryLesson,
    required this.onBackToModule,
  });

  Widget _buildStatPill(String label, dynamic value, Color color) {
    // ... [Implementierung unverändert] ...
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
            ),
            Text(
              value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final incorrectAnswers = totalQuestions - correctAnswers;
    final successRate = totalQuestions > 0
        ? (correctAnswers / totalQuestions) * 100
        : 0;
    final passed = successRate >= 60;

    final screenWidth = MediaQuery.of(context).size.width;

    // Fix 1: Begrenzt die Karte nicht nach unten, wenn der Bildschirm extrem schmal ist.
    // Die Card nimmt 90% der Breite auf kleinen Bildschirmen ein, maximal 500px.
    final maxCardWidth = screenWidth < 600 ? screenWidth * 0.9 : 500.0;

    const double buttonMaxWidth = 160.0;
    const EdgeInsets buttonPadding = EdgeInsets.symmetric(vertical: 10);

    // Fix 2: Erhöhe den Schwellenwert für Full-Width-Buttons, um sicherzustellen,
    // dass sie sofort untereinander springen und den Overflow verhindern.
    // Setze isSmallScreen auf 500px, um sicherzugehen.
    final bool isSmallScreen = screenWidth < 500;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCardWidth),
        child: Material(
          type: MaterialType.transparency,
          child: Card(
            margin: const EdgeInsets.all(10), // Hier sind 20px Margin
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0), // Hier sind 30px Padding
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ... [Titel, Status, Ergebnis, Statistiken unverändert] ...
                  Icon(
                    passed ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: passed ? Colors.green : Colors.red,
                    size: 70,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    passed ? 'Congratulations!' : 'Keep Trying!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: passed ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    passed
                        ? 'You passed the lesson!'
                        : 'You need 60% to pass. Don\'t give up!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${successRate.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$correctAnswers out of $totalQuestions correct answers',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatPill('Correct', correctAnswers, Colors.green),
                      _buildStatPill('Incorrect', incorrectAnswers, Colors.red),
                      _buildStatPill(
                        'Time',
                        _formatTime(durationSeconds),
                        Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Aktionen (Müssen bei isSmallScreen Full-Width sein)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      // Review Answers Button
                      SizedBox(
                        // Sollte bei isSmallScreen Full-Width sein
                        width: isSmallScreen ? double.infinity : buttonMaxWidth,
                        child: OutlinedButton.icon(
                          onPressed: onReviewAnswers,
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Review Answers'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: buttonPadding,
                          ),
                        ),
                      ),

                      // Retry Lesson Button
                      SizedBox(
                        width: isSmallScreen ? double.infinity : buttonMaxWidth,
                        child: OutlinedButton.icon(
                          onPressed: onRetryLesson,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Lesson'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: buttonPadding,
                          ),
                        ),
                      ),

                      // Back to Module Button
                      SizedBox(
                        width: isSmallScreen ? double.infinity : buttonMaxWidth,
                        child: ElevatedButton.icon(
                          onPressed: onBackToModule,
                          icon: const Icon(
                            Icons.view_list,
                            color: Colors.white,
                          ),
                          label: const Text('Back to Module'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: buttonPadding,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================
// HAUPT-SCREEN (QUIZSCREEN)
// =========================================================

class QuizScreen extends StatefulWidget {
  final Module module;
  final Lesson lesson;
  final dynamic submoduleId; // NEU: für Session-Tracking

  const QuizScreen({
    super.key,
    required this.module,
    required this.lesson,
    this.submoduleId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Question> _questions;
  int _currentQuestionIndex = 0;
  late ScrollController _scrollController;

  bool _quizFinished = false;
  bool _isReviewMode = false;
  bool _answerSubmitted = false; // NEU: Benutzer hat Antwort eingegeben
  int _correctAnswers = 0;
  String? _sessionId; // NEU: für Session-Tracking
  bool _answerConfirmed = false; // NEU: Nutzer hat OK geklickt

  // NEU: Timer für Quiz
  late Timer _quizTimer;
  int _elapsedSeconds = 0; // Verstrichene Sekunden

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _questions = widget.lesson.quizQuestions.map((q) {
      final correctIndex = _getCorrectIndex(q.options);
      return Question(
        id: q.id, // ✅ WICHTIG: ID mitkopieren!
        questionText: q.questionText,
        options: q.options,
        selectedOptionIndex: null, // Starten ohne Auswahl
        correctOptionIndex: correctIndex,
        explanation: q.explanation,
      );
    }).toList();

    // NEU: Starte Learning Session in Supabase
    _startSession();

    // NEU: Starte Timer
    _startQuizTimer();
  }

  void _startQuizTimer() {
    _elapsedSeconds = 0;
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
    debugPrint('⏱️ Quiz Timer gestartet');
  }

  Future<void> _startSession() async {
    if (widget.submoduleId == null) return;
    try {
      final provider = Provider.of<BackendProvider>(context, listen: false);
      final sessionId = await provider.startLearningSession(widget.submoduleId);
      setState(() {
        _sessionId = sessionId;
      });
    } catch (e) {
      debugPrint('Failed to start session: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _quizTimer.cancel(); // NEU: Stoppe Timer beim Dispose

    super.dispose();
  }

  void _calculateResult() {
    _correctAnswers = 0;
    for (var q in _questions) {
      if (q.selectedOptionIndex != null &&
          q.selectedOptionIndex == q.correctOptionIndex) {
        _correctAnswers++;
      }
    }
  }

  void _selectOption(int optionIndex) {
    if (!_isReviewMode && !_answerSubmitted) {
      setState(() {
        _questions[_currentQuestionIndex].selectedOptionIndex = optionIndex;
        _answerConfirmed = false; // Zurücksetzen: Nutzer kann noch ändern
      });
    }
  }

  void _confirmAnswer() {
    if (!_isReviewMode &&
        !_answerSubmitted &&
        _questions[_currentQuestionIndex].selectedOptionIndex != null) {
      final selectedIndex =
          _questions[_currentQuestionIndex].selectedOptionIndex!;
      final isCorrect =
          selectedIndex == _questions[_currentQuestionIndex].correctOptionIndex;
      setState(() {
        _answerSubmitted = true; // Zeige Feedback
        _answerConfirmed = true; // Markiere als bestätigt
        if (isCorrect) {
          _correctAnswers++;
        }
      });
      _recordAnswer(selectedIndex);
    }
  }

  Future<void> _recordAnswer(int selectedIndex) async {
    try {
      final provider = Provider.of<BackendProvider>(context, listen: false);
      final question = _questions[_currentQuestionIndex];
      final isCorrect = selectedIndex == question.correctOptionIndex;

      // NEU: Speichere Antwort mit Question ID (als String)
      // Hier müssen wir die Question ID haben - müssen wir zur Question-Klasse hinzufügen
      // Für jetzt: nur tracking
      await provider.recordAnswer(
        question.id?.toString() ?? 'unknown',
        isCorrect,
      );
    } catch (e) {
      debugPrint('Failed to record answer: $e');
    }
  }

  void _goToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      setState(() {
        _currentQuestionIndex = index;
        _answerSubmitted = false; // Zurücksetzen für neue Frage
        _answerConfirmed = false; // Zurücksetzen Bestätigung
      });
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _goToQuestion(_currentQuestionIndex + 1);
    } else {
      // Quiz fertig
      _calculateResult();
      setState(() {
        _quizFinished = true;
      });
      _finishSessionAndShowResults();
    }
  }

  Future<void> _finishSessionAndShowResults() async {
    try {
      _quizTimer.cancel(); // NEU: Stoppe Timer
      debugPrint('🎬 Starting session finish sequence...');
      await _finishSession();
      debugPrint('✅ Session finished successfully');
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ Error finishing session: $e');
    }
  }

  Future<void> _finishSession() async {
    if (_sessionId == null || widget.submoduleId == null) return;
    try {
      final provider = Provider.of<BackendProvider>(context, listen: false);
      final durationMinutes = _elapsedSeconds ~/ 60; // Konvertiere zu Minuten

      debugPrint(
        '⏱️ Quiz beendet: $_elapsedSeconds Sekunden = $durationMinutes Minuten',
      );
      debugPrint('✅ Korrekte Antworten: $_correctAnswers/${_questions.length}');

      await provider.finishLearningSession(
        _sessionId!,
        total: _questions.length,
        correct: _correctAnswers,
        submoduleId: widget.submoduleId, // NEU: Übergebe Submodule ID
        durationMinutes: durationMinutes, // NEU: Sende die Zeit
      );

      // NEU: Aktualisiere Fortschritte nach dem Beenden der Session
      debugPrint('🔄 Aktualisiere Fortschritte nach Quiz-Session...');
      await provider.updateSubmoduleProgress(widget.submoduleId);
      if (widget.module.id != null) {
        await provider.updateModuleProgress(widget.module.id);
      }
      debugPrint('✅ Fortschritte aktualisiert');
    } catch (e) {
      debugPrint('Failed to finish session: $e');
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      _goToQuestion(_currentQuestionIndex - 1);
    }
  }

  void _startReviewMode() {
    setState(() {
      _quizFinished = false;
      _isReviewMode = true;
      _goToQuestion(0);
    });
  }

  void _backToResultsOverlay() {
    setState(() {
      _isReviewMode = false;
      _quizFinished = true;
      _answerSubmitted = false;
      _answerConfirmed = false;
    });
  }

  Future<void> _retryLesson() async {
    Set<int> masteredIds = {};
    if (widget.submoduleId != null) {
      final provider = Provider.of<BackendProvider>(context, listen: false);
      masteredIds = await provider.getMasteredQuestionIdsForSubmodule(
        widget.submoduleId,
      );
    }

    final filteredQuestions = widget.lesson.quizQuestions.where((q) {
      if (q.id == null) return true;
      return !masteredIds.contains(q.id);
    }).toList();

    setState(() {
      _quizFinished = false;
      _isReviewMode = false;
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
      _answerSubmitted = false;
      _answerConfirmed = false;
      _elapsedSeconds = 0; // NEU: Reset Timer

      _questions = filteredQuestions.map((q) {
        final correctIndex = _getCorrectIndex(q.options);
        return Question(
          id: q.id, // ✅ WICHTIG: ID mitkopieren!
          questionText: q.questionText,
          options: q.options,
          selectedOptionIndex: null,
          correctOptionIndex: correctIndex,
          explanation: q.explanation,
        );
      }).toList();
      _scrollController.jumpTo(0);
    });
    _startSession(); // Neue Session starten
    _startQuizTimer(); // NEU: Starte Timer neu
  }

  Future<void> _backToModule() async {
    final provider = Provider.of<BackendProvider>(context, listen: false);
    await provider.refreshAllProgress();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _confirmExitLesson() async {
    if (!mounted) return;
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Session verlassen?'),
          content: const Text(
            'Wenn du die Session verlässt, gehen deine bisherigen Fortschritte verloren. Möchtest du wirklich verlassen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Weiterlernen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Verlassen'),
            ),
          ],
        );
      },
    );

    if (shouldExit == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalQuestions = _questions.length;
    final int questionNumber = _currentQuestionIndex + 1;
    const Color primaryColor = Colors.blue;

    final Question currentQuestion = _questions[_currentQuestionIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 500;

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.lesson.title)),
        body: const Center(
          child: Text('Keine Fragen für diese Lektion gefunden.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Hintergrund & Gradient
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.darkOverlayGradient,
              ),
            ),
          ),

          // 2. HAUPTINHALT
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      // --- HEADER / TOP BEREICH ---
                      Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.only(top: 60, bottom: 20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Exit Lesson / Back to Results Button
                              GestureDetector(
                                onTap: () => _isReviewMode
                                    ? _backToModule()
                                    : _confirmExitLesson(),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isReviewMode
                                          ? 'Back to Module'
                                          : 'Exit Lesson',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Timer und Gesamtfragen
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTime(_elapsedSeconds),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_correctAnswers}/$totalQuestions',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Modul/Lektions-Header und Progress Bar
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Icon(
                                            widget.module.icon,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.module.title,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                widget.module.description,
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),

                                    // Progress Bar und Timer
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Progress Question $questionNumber of $totalQuestions',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: questionNumber / totalQuestions,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            primaryColor,
                                          ),
                                      minHeight: 10,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // --- FRAGENBEREICH ---
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 25,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Frage-Nummer-Label
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Question ${_currentQuestionIndex + 1}',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),

                              // Frage-Text
                              Text(
                                currentQuestion.questionText,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Antwort-Optionen
                              ...currentQuestion.options.asMap().entries.map((
                                entry,
                              ) {
                                final optionIndex = entry.key;
                                final option = entry.value;
                                final isCorrect =
                                    optionIndex ==
                                    currentQuestion.correctOptionIndex;

                                final isSelected =
                                    currentQuestion.selectedOptionIndex ==
                                    optionIndex;

                                // NEU: Im Quiz-Modus nach Auswahl oder Review-Modus
                                if (_answerSubmitted || _isReviewMode) {
                                  return ReviewOptionCard(
                                    option: option,
                                    isCorrect: isCorrect,
                                    isSelected: isSelected,
                                  );
                                } else {
                                  return OptionCard(
                                    option: option,
                                    isSelected: isSelected,
                                    onTap: () => _selectOption(optionIndex),
                                  );
                                }
                              }).toList(),

                              // NEU: Feedback nach Antwort
                              if (_answerSubmitted && !_isReviewMode)
                                Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color:
                                          (_questions[_currentQuestionIndex]
                                                  .selectedOptionIndex ==
                                              _questions[_currentQuestionIndex]
                                                  .correctOptionIndex)
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color:
                                            (_questions[_currentQuestionIndex]
                                                    .selectedOptionIndex ==
                                                _questions[_currentQuestionIndex]
                                                    .correctOptionIndex)
                                            ? Colors.green.shade200
                                            : Colors.red.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          (_questions[_currentQuestionIndex]
                                                      .selectedOptionIndex ==
                                                  _questions[_currentQuestionIndex]
                                                      .correctOptionIndex)
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color:
                                              (_questions[_currentQuestionIndex]
                                                      .selectedOptionIndex ==
                                                  _questions[_currentQuestionIndex]
                                                      .correctOptionIndex)
                                              ? Colors.green
                                              : Colors.red,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            (_questions[_currentQuestionIndex]
                                                        .selectedOptionIndex ==
                                                    _questions[_currentQuestionIndex]
                                                        .correctOptionIndex)
                                                ? 'Correct!'
                                                : 'Incorrect!',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  (_questions[_currentQuestionIndex]
                                                          .selectedOptionIndex ==
                                                      _questions[_currentQuestionIndex]
                                                          .correctOptionIndex)
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Erklärungen NUR nach OK oder im Review Mode
                              if ((_answerConfirmed || _isReviewMode) &&
                                  currentQuestion.explanation != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: Colors.blue.shade100,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Explanation',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(currentQuestion.explanation!),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // --- BOTTOM NAVIGATION BAR ---
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // 1. Pips / Question Stepper
                            Padding(
                              padding: const EdgeInsets.only(bottom: 15.0),
                              child: QuestionStepper(
                                totalQuestions: totalQuestions,
                                currentQuestionIndex: _currentQuestionIndex,
                                onStepTap: _goToQuestion,
                              ),
                            ),

                            // 2. Previous / OK / Next Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Previous Button
                                SizedBox(
                                  width: isSmallScreen ? 90 : 140,
                                  child: ElevatedButton.icon(
                                    onPressed: _currentQuestionIndex > 0
                                        ? _goToPreviousQuestion
                                        : null,
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Previous',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                    ),
                                  ),
                                ),

                                // OK Button (Mitte) - nur wenn Antwort ausgewählt aber noch nicht bestätigt
                                if (!_isReviewMode &&
                                    !_answerSubmitted &&
                                    _questions[_currentQuestionIndex]
                                            .selectedOptionIndex !=
                                        null)
                                  SizedBox(
                                    width: isSmallScreen ? 70 : 100,
                                    child: ElevatedButton(
                                      onPressed: _confirmAnswer,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15,
                                        ),
                                      ),
                                      child: const Text(
                                        'OK',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                // Next Button / Finish Button (nur wenn Antwort bestätigt)
                                SizedBox(
                                  width: isSmallScreen ? 90 : 140,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        (_answerSubmitted || _isReviewMode)
                                        ? _goToNextQuestion
                                        : null, // NEU: Disabled bis Antwort bestätigt
                                    icon: Icon(
                                      _currentQuestionIndex ==
                                              totalQuestions - 1
                                          ? Icons.check
                                          : Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      _currentQuestionIndex ==
                                              totalQuestions - 1
                                          ? 'Finish'
                                          : 'Next',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      disabledBackgroundColor: Colors.grey,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (_isReviewMode)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _backToResultsOverlay,
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      size: 16,
                                    ),
                                    label: const Text('Back to Results'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. ERGEBNIS-POPUP (Overlay) - VERWENDET DAS MOBILE-OPTIMIERTE WIDGET
          if (_quizFinished)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: QuizResultOverlay(
                correctAnswers: _correctAnswers,
                totalQuestions: totalQuestions,
                title: widget.module.title,
                durationSeconds: _elapsedSeconds,
                onReviewAnswers: _startReviewMode,
                onRetryLesson: _retryLesson,
                onBackToModule: _backToModule,
              ),
            ),
        ],
      ),
    );
  }
}
