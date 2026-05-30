// lib/models/screening_history_model.dart

import 'package:autisme/models/diagnosis_model.dart';

class ScreeningHistory {
  final String? id;
  final String userId;
  final String? childId;
  final int childAgeMonths;
  final DateTime createdAt;
  final DiagnosisResult result;

  ScreeningHistory({
    this.id,
    required this.userId,
    this.childId,
    required this.childAgeMonths,
    required this.createdAt,
    required this.result,
  });

  // Konversi dari database (Supabase)
  factory ScreeningHistory.fromJson(Map<String, dynamic> json) {
    return ScreeningHistory(
      id: json['id'],
      userId: json['user_id'],
      childId: json['child_id'],
      childAgeMonths: json['child_age_months'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      result: DiagnosisResult(
        totalScore: json['total_score'],
        maxScore: json['max_score'],
        riskLevel: json['risk_level'],
        aiRecommendation: json['ai_recommendation'],
        affectedAspects: List<String>.from(json['affected_aspects'] ?? []),
        aspectScores: Map<String, int>.from(json['aspect_scores'] ?? {}),
      ),
    );
  }

  // Konversi untuk disimpan ke database (Supabase)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'child_id': childId,
      'child_age_months': childAgeMonths,
      'total_score': result.totalScore,
      'max_score': result.maxScore,
      'risk_level': result.riskLevel,
      'ai_recommendation': result.aiRecommendation,
      'affected_aspects': result.affectedAspects,
      'aspect_scores': result.aspectScores,
    };
  }
}
