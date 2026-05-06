import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../services/quiz_service.dart';
import '../theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  final bool isDark;
  const QuizScreen({super.key, required this.isDark});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // ── Load state ────────────────────────────────────────────────────────────
  DailyQuiz? _quiz;
  bool _loadingQuiz = true;
  String? _loadError;

  // ── Quiz play state ───────────────────────────────────────────────────────
  int _currentIndex = 0;
  final List<int?> _selectedAnswers = [];   // one slot per question
  bool _showingResult = false;              // result revealed for current Q

  // ── Submit state ──────────────────────────────────────────────────────────
  bool _submitting = false;
  QuizResult? _result;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _loadingQuiz = true;
      _loadError = null;
    });
    try {
      final quiz = await QuizService.instance.fetchTodaysQuiz();
      if (mounted) {
        setState(() {
          _quiz = quiz;
          _selectedAnswers.clear();
          _selectedAnswers.addAll(List.filled(quiz.questions.length, null));
          _loadingQuiz = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('NOT_FOUND') || e.toString().contains('404')
            ? 'No quiz available today — check back tomorrow!'
            : 'Could not load today\'s quiz.';
        setState(() {
          _loadError = msg;
          _loadingQuiz = false;
        });
      }
    }
  }

  void _selectAnswer(int optionIndex) {
    if (_showingResult) return;
    setState(() => _selectedAnswers[_currentIndex] = optionIndex);
  }

  void _submitAnswer() {
    if (_selectedAnswers[_currentIndex] == null) return;
    setState(() => _showingResult = true);
  }

  void _nextQuestion() {
    if (_currentIndex < _quiz!.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _showingResult = false;
      });
    } else {
      _submitQuiz();
    }
  }

  Future<void> _submitQuiz() async {
    setState(() => _submitting = true);
    try {
      final answers = _selectedAnswers.map((a) => a ?? 0).toList();
      final result = await QuizService.instance.submitQuiz(
        quizId: _quiz!.id,
        answers: answers,
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        final isAlreadyDone = e.toString().contains('409') ||
            e.toString().contains('already submitted');
        setState(() {
          _result = null;
          _loadError = isAlreadyDone
              ? 'You already completed today\'s quiz!'
              : 'Failed to submit quiz. Your answers were saved locally.';
          _submitting = false;
        });
      }
    } finally {
      if (mounted && _submitting) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);

    if (_loadingQuiz) return _buildLoading(colors);
    if (_loadError != null && _quiz == null) return _buildError(colors);
    if (_quiz!.alreadyCompleted) return _buildAlreadyCompleted(colors);
    if (_submitting) return _buildLoading(colors);
    if (_result != null) return _buildResults(colors);

    return _buildQuiz(colors);
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading(DynamicColors colors) {
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: CircularProgressIndicator(color: NexusColors.teal, strokeWidth: 2),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError(DynamicColors colors) {
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_outlined, size: 72, color: colors.muted),
              const SizedBox(height: 24),
              Text(
                _loadError!,
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loadQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NexusColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Already completed ─────────────────────────────────────────────────────

  Widget _buildAlreadyCompleted(DynamicColors colors) {
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: NexusColors.teal.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: NexusColors.teal, size: 44),
              ),
              const SizedBox(height: 24),
              Text(
                'Already Completed!',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You've already taken today's quiz. Come back tomorrow for a new challenge!",
                style: TextStyle(fontSize: 15, color: colors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Results ───────────────────────────────────────────────────────────────

  Widget _buildResults(DynamicColors colors) {
    final r = _result!;
    final percent = r.total > 0 ? (r.score / r.total * 100).round() : 0;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              if (r.isPerfect)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: NexusColors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: NexusColors.amber.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars, color: NexusColors.amber, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Perfect Score!',
                        style: TextStyle(
                          color: NexusColors.amber,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                "$percent%",
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 72,
                  fontWeight: FontWeight.w700,
                  color: percent >= 80 ? NexusColors.teal : colors.textPrimary,
                ),
              ),
              Text(
                "${r.score} of ${r.total} correct",
                style: TextStyle(fontSize: 18, color: colors.textSecondary),
              ),
              const SizedBox(height: 32),
              // XP + Streak row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ResultStat(
                    icon: Icons.bolt,
                    label: 'XP Earned',
                    value: '+${r.xpEarned}',
                    color: NexusColors.amber,
                    colors: colors,
                  ),
                  const SizedBox(width: 24),
                  _ResultStat(
                    icon: Icons.local_fire_department,
                    label: 'Streak',
                    value: '${r.newStreak} days',
                    color: Colors.orange,
                    colors: colors,
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    _result = null;
                    _quiz = null;
                    _loadQuiz();
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NexusColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Active quiz ───────────────────────────────────────────────────────────

  Widget _buildQuiz(DynamicColors colors) {
    final quiz = _quiz!;
    final question = quiz.questions[_currentIndex];
    final selected = _selectedAnswers[_currentIndex];

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      quiz.title,
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: NexusColors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, color: NexusColors.amber, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${quiz.xpReward} XP',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: NexusColors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress
              _ProgressBar(
                current: _currentIndex + 1,
                total: quiz.questions.length,
                isDark: widget.isDark,
              ),
              const SizedBox(height: 28),

              // Question card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: NexusColors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Question ${_currentIndex + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: NexusColors.teal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      question.question,
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Options
              Expanded(
                child: ListView.builder(
                  itemCount: question.options.length,
                  itemBuilder: (_, i) {
                    final isSelected = selected == i;

                    Color? borderColor;
                    Color? bgColor;

                    if (_showingResult) {
                      // Correct answers come back from the server after submit.
                      // During per-question review, just highlight the selection.
                      if (isSelected) {
                        borderColor = NexusColors.teal;
                        bgColor = NexusColors.teal.withOpacity(0.08);
                      }
                    } else if (isSelected) {
                      borderColor = NexusColors.teal;
                      bgColor = NexusColors.teal.withOpacity(0.05);
                    }

                    return GestureDetector(
                      onTap: () => _selectAnswer(i),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor ?? colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor ?? colors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected ? NexusColors.teal : colors.muted,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + i),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : colors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                question.options[i],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showingResult
                      ? _nextQuestion
                      : (selected != null ? _submitAnswer : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NexusColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: colors.muted,
                  ),
                  child: Text(
                    _showingResult
                        ? (_currentIndex < quiz.questions.length - 1 ? 'Next Question' : 'Submit Quiz')
                        : 'Submit Answer',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final bool isDark;

  const _ProgressBar({required this.current, required this.total, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progress', style: TextStyle(fontSize: 13, color: colors.textSecondary)),
            Text('$current of $total',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: current / total,
            backgroundColor: colors.muted,
            color: NexusColors.teal,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _ResultStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final DynamicColors colors;

  const _ResultStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Fraunces', fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
        ],
      ),
    );
  }
}
