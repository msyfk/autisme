// lib/models/diagnosis_model.dart

class DiagnosisResult {
  final int totalScore;
  final int maxScore;
  final String riskLevel; // Rendah, Sedang, Tinggi
  final String aiRecommendation;
  final List<String> affectedAspects;
  final Map<String, int> aspectScores;

  DiagnosisResult({
    required this.totalScore,
    required this.maxScore,
    required this.riskLevel,
    required this.aiRecommendation,
    required this.affectedAspects,
    required this.aspectScores,
  });

  double get percentage => (totalScore / maxScore) * 100;
}
