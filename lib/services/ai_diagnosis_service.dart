// lib/services/ai_diagnosis_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:autisme/models/diagnosis_model.dart';
import 'package:autisme/models/question_model.dart';

class AIDiagnosisService {
  // PENTING: Ganti dengan API key Anda dari https://console.anthropic.com
  static const String apiKey = 'claude_code_key_musyaffaksyafak_zhtu';
  static const String apiUrl = 'https://api.anthropic.com/v1/messages';

  Future<DiagnosisResult> getDiagnosis({
    required int childAgeMonths,
    required Map<int, int> answers,
    required List<ScreeningQuestion> questions,
  }) async {
    // Hitung skor per aspek
    Map<String, int> aspectScores = {};
    Map<String, int> aspectMaxScores = {};

    for (var question in questions) {
      if (answers.containsKey(question.id)) {
        int score = answers[question.id]!;
        aspectScores[question.aspect] =
            (aspectScores[question.aspect] ?? 0) + score;

        // Hitung max score untuk aspek ini
        int maxScore = question.options
            .map((o) => o.score)
            .reduce((a, b) => a > b ? a : b);
        aspectMaxScores[question.aspect] =
            (aspectMaxScores[question.aspect] ?? 0) + maxScore;
      }
    }

    // Total score
    int totalScore = answers.values.fold(0, (sum, item) => sum + item);
    int maxScore = 0;
    for (var question in questions) {
      int qMaxScore = question.options
          .map((o) => o.score)
          .reduce((a, b) => a > b ? a : b);
      maxScore += qMaxScore;
    }

    // Tentukan risk level berdasarkan persentase
    double percentage = (totalScore / maxScore) * 100;
    String riskLevel;
    if (percentage < 30) {
      riskLevel = 'Rendah';
    } else if (percentage < 60) {
      riskLevel = 'Sedang';
    } else {
      riskLevel = 'Tinggi';
    }

    // Identifikasi aspek yang terpengaruh (skor > 50% dari max)
    List<String> affectedAspects = [];
    aspectScores.forEach((aspect, score) {
      double aspectPercentage = (score / aspectMaxScores[aspect]!) * 100;
      if (aspectPercentage > 50) {
        affectedAspects.add(aspect);
      }
    });

    // Dapatkan rekomendasi AI
    String aiRecommendation = await _getAIRecommendation(
      childAgeMonths: childAgeMonths,
      totalScore: totalScore,
      maxScore: maxScore,
      riskLevel: riskLevel,
      aspectScores: aspectScores,
      affectedAspects: affectedAspects,
    );

    return DiagnosisResult(
      totalScore: totalScore,
      maxScore: maxScore,
      riskLevel: riskLevel,
      aiRecommendation: aiRecommendation,
      affectedAspects: affectedAspects,
      aspectScores: aspectScores,
    );
  }

  Future<String> _getAIRecommendation({
    required int childAgeMonths,
    required int totalScore,
    required int maxScore,
    required String riskLevel,
    required Map<String, int> aspectScores,
    required List<String> affectedAspects,
  }) async {
    double percentage = (totalScore / maxScore) * 100;

    // Buat prompt untuk AI
    String prompt =
        '''
Anda adalah asisten ahli dalam diagnosis dini autisme pada anak. 

Berikut adalah hasil screening untuk anak usia $childAgeMonths bulan:
- Total Skor: $totalScore dari $maxScore (${percentage.toStringAsFixed(1)}%)
- Tingkat Risiko: $riskLevel
- Aspek yang terpengaruh: ${affectedAspects.isEmpty ? 'Tidak ada aspek signifikan' : affectedAspects.join(', ')}

Detail skor per aspek:
${aspectScores.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

Berikan rekomendasi komprehensif dalam bahasa Indonesia yang mencakup:
1. Interpretasi hasil screening
2. Tindakan yang sebaiknya dilakukan oleh orang tua
3. Rekomendasi konsultasi profesional (jika diperlukan)
4. Tips stimulasi dan intervensi dini yang bisa dilakukan di rumah
5. Pengingat bahwa ini adalah screening awal, bukan diagnosis medis

Gunakan bahasa yang empatik, tidak menghakimi, dan memberikan harapan. Maksimal 300 kata.
''';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 1024,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'];
      } else {
        print('AI Error: ${response.statusCode} - ${response.body}');
        return _getFallbackRecommendation(riskLevel, affectedAspects);
      }
    } catch (e) {
      print('AI Error: $e');
      return _getFallbackRecommendation(riskLevel, affectedAspects);
    }
  }

  String _getFallbackRecommendation(
    String riskLevel,
    List<String> affectedAspects,
  ) {
    // Rekomendasi fallback jika AI tidak tersedia
    if (riskLevel == 'Rendah') {
      return '''
Hasil screening menunjukkan risiko rendah untuk gangguan spektrum autisme. Anak Anda menunjukkan perkembangan yang baik.

Rekomendasi:
• Terus lakukan stimulasi perkembangan secara rutin
• Pantau milestone perkembangan anak
• Konsultasi rutin dengan dokter anak
• Ciptakan lingkungan yang mendukung eksplorasi dan pembelajaran

Ingat: Ini adalah screening awal. Jika Anda memiliki kekhawatiran khusus, konsultasikan dengan profesional.
''';
    } else if (riskLevel == 'Sedang') {
      return '''
Hasil screening menunjukkan beberapa area yang memerlukan perhatian lebih, terutama pada: ${affectedAspects.join(', ')}.

Rekomendasi:
• Konsultasikan hasil ini dengan dokter anak atau psikolog perkembangan
• Lakukan observasi lebih detail pada area yang terpengaruh
• Mulai intervensi dini jika disarankan oleh profesional
• Bergabung dengan komunitas orang tua untuk dukungan

Tindakan dini sangat penting. Jangan ragu untuk mencari bantuan profesional.
''';
    } else {
      return '''
Hasil screening menunjukkan beberapa indikator yang memerlukan evaluasi profesional segera, khususnya pada: ${affectedAspects.join(', ')}.

Rekomendasi Penting:
• SEGERA konsultasikan dengan dokter spesialis anak atau psikolog klinis
• Minta rujukan untuk evaluasi diagnostik komprehensif
• Dokumentasikan perilaku dan perkembangan anak
• Cari informasi tentang layanan intervensi dini di daerah Anda

Ingat: Screening ini bukan diagnosis final. Evaluasi profesional diperlukan untuk diagnosis yang akurat. Intervensi dini dapat membuat perbedaan signifikan.
''';
    }
  }
}
