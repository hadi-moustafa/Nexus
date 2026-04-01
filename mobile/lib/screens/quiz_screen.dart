import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  final bool isDark;

  const QuizScreen({super.key, required this.isDark});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestion = 0;
  int? _selectedAnswer;
  bool _showResult = false;
  int _score = 0;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Which country recently announced a major climate initiative at COP29?',
      'options': ['China', 'United States', 'India', 'Brazil'],
      'correct': 0,
    },
    {
      'question': 'What tech company launched a new AI model this week?',
      'options': ['Google', 'Microsoft', 'Apple', 'Meta'],
      'correct': 1,
    },
    {
      'question': 'Which currency reached its highest value against the dollar this month?',
      'options': ['Euro', 'British Pound', 'Japanese Yen', 'Swiss Franc'],
      'correct': 3,
    },
  ];

  void _selectAnswer(int index) {
    if (_showResult) return;
    setState(() {
      _selectedAnswer = index;
    });
  }

  void _submitAnswer() {
    if (_selectedAnswer == null) return;
    
    setState(() {
      _showResult = true;
      if (_selectedAnswer == _questions[_currentQuestion]['correct']) {
        _score += 10;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = null;
        _showResult = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);
    final question = _questions[_currentQuestion];

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
                  Text(
                    'Daily Quiz',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: NexusColors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.stars,
                          color: NexusColors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_score XP',
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

              const SizedBox(height: 24),

              // Progress Bar
              _ProgressBar(
                current: _currentQuestion + 1,
                total: _questions.length,
                isDark: widget.isDark,
              ),

              const SizedBox(height: 32),

              // Question Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: NexusColors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Question ${_currentQuestion + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: NexusColors.teal,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '30s',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      question['question'],
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Options
              Expanded(
                child: ListView.builder(
                  itemCount: (question['options'] as List).length,
                  itemBuilder: (context, index) {
                    final option = question['options'][index];
                    final isSelected = _selectedAnswer == index;
                    final isCorrect = question['correct'] == index;

                    Color? borderColor;
                    Color? bgColor;

                    if (_showResult) {
                      if (isCorrect) {
                        borderColor = NexusColors.teal;
                        bgColor = NexusColors.teal.withOpacity(0.1);
                      } else if (isSelected && !isCorrect) {
                        borderColor = Colors.red;
                        bgColor = Colors.red.withOpacity(0.1);
                      }
                    } else if (isSelected) {
                      borderColor = NexusColors.teal;
                      bgColor = NexusColors.teal.withOpacity(0.05);
                    }

                    return GestureDetector(
                      onTap: () => _selectAnswer(index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor ?? colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor ?? colors.border,
                            width: isSelected || (_showResult && isCorrect) ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? NexusColors.teal 
                                    : colors.muted,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected 
                                        ? Colors.white 
                                        : colors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected 
                                      ? FontWeight.w600 
                                      : FontWeight.w400,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            if (_showResult && isCorrect)
                              const Icon(
                                Icons.check_circle,
                                color: NexusColors.teal,
                              ),
                            if (_showResult && isSelected && !isCorrect)
                              const Icon(
                                Icons.cancel,
                                color: Colors.red,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showResult 
                      ? _nextQuestion 
                      : (_selectedAnswer != null ? _submitAnswer : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NexusColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: colors.muted,
                  ),
                  child: Text(
                    _showResult 
                        ? (_currentQuestion < _questions.length - 1 
                            ? 'Next Question' 
                            : 'See Results')
                        : 'Submit Answer',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final bool isDark;

  const _ProgressBar({
    required this.current,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            Text(
              '$current of $total',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: List.generate(total, (index) {
              final isCompleted = index < current;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < total - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: isCompleted ? NexusColors.teal : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
