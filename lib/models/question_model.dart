import 'dart:convert';

class QuestionOption {
  final String text;
  final int score;

  QuestionOption({required this.text, required this.score});

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(text: json['text'], score: json['score']);
  }
}

class ScreeningQuestion {
  final int id;
  final String aspect;
  final String section;
  final String question;
  final int ageMonths;
  final List<QuestionOption> options;

  ScreeningQuestion({
    required this.id,
    required this.aspect,
    required this.section,
    required this.question,
    required this.ageMonths,
    required this.options,
  });

  factory ScreeningQuestion.fromJson(Map<String, dynamic> json) {
    var list = json['options'] as List;
    List<QuestionOption> optionsList = list
        .map((i) => QuestionOption.fromJson(i))
        .toList();

    return ScreeningQuestion(
      id: json['id'],
      aspect: json['aspect'],
      section: json['section'],
      question: json['question'],
      ageMonths: json['age_months'],
      options: optionsList,
    );
  }
}

List<ScreeningQuestion> parseQuestions(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed
      .map<ScreeningQuestion>((json) => ScreeningQuestion.fromJson(json))
      .toList();
}
