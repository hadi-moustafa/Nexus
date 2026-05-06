class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int timeLimit;
  final int position;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.timeLimit,
    required this.position,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      timeLimit: json['timeLimit'] as int? ?? 30,
      position: json['position'] as int,
    );
  }
}

class DailyQuiz {
  final String id;
  final String title;
  final int xpReward;
  final String scheduledFor;
  final List<QuizQuestion> questions;
  final bool alreadyCompleted;

  const DailyQuiz({
    required this.id,
    required this.title,
    required this.xpReward,
    required this.scheduledFor,
    required this.questions,
    required this.alreadyCompleted,
  });

  factory DailyQuiz.fromJson(Map<String, dynamic> json) {
    return DailyQuiz(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Daily News Quiz',
      xpReward: json['xpReward'] as int? ?? 0,
      scheduledFor: json['scheduledFor'] as String,
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      alreadyCompleted: json['alreadyCompleted'] as bool? ?? false,
    );
  }
}

class QuizResult {
  final int score;
  final int total;
  final bool isPerfect;
  final int xpEarned;
  final int newStreak;
  final List<int> correctAnswers;

  const QuizResult({
    required this.score,
    required this.total,
    required this.isPerfect,
    required this.xpEarned,
    required this.newStreak,
    required this.correctAnswers,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      score: json['score'] as int,
      total: json['total'] as int,
      isPerfect: json['isPerfect'] as bool? ?? false,
      xpEarned: json['xpEarned'] as int? ?? 0,
      newStreak: json['newStreak'] as int? ?? 0,
      correctAnswers: List<int>.from(json['correctAnswers'] as List? ?? []),
    );
  }
}
