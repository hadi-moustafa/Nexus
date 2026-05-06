import '../models/quiz.dart';
import 'api_client.dart';

class QuizService {
  QuizService._();
  static final QuizService instance = QuizService._();

  Future<DailyQuiz> fetchTodaysQuiz() async {
    final response = await ApiClient.instance.get('/quiz/today');
    return DailyQuiz.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Submits answers for a quiz. [answers] is a 0-based option index per question,
  /// ordered by question position.
  Future<QuizResult> submitQuiz({
    required String quizId,
    required List<int> answers,
  }) async {
    final response = await ApiClient.instance.post(
      '/quiz/submit',
      data: {'quizId': quizId, 'answers': answers},
    );
    return QuizResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
