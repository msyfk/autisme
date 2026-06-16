// lib/services/ai_diagnosis_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:autisme/models/diagnosis_model.dart';
import 'package:autisme/models/question_model.dart';

class AIDiagnosisService {
  // API Key dibaca dari file .env
  static String get apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';
  static const String apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String modelId = 'deepseek/deepseek-v4-flash';

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

        // Hitung max score untuk aspek ini (maksimal skor adalah jumlah opsi, karena skor urut 1-4)
        int maxScore = question.options.length;
        aspectMaxScores[question.aspect] =
            (aspectMaxScores[question.aspect] ?? 0) + maxScore;
      }
    }

    // Total score
    int totalScore = answers.values.fold(0, (sum, item) => sum + item);
    // Hitung S_min (Skor minimum = jumlah pertanyaan terjawab * 1)
    int sMin = answers.length;

    // Hitung S_maks (Skor maksimal = jumlah opsi pada masing-masing pertanyaan terjawab)
    int sMax = 0;
    for (var question in questions) {
      if (answers.containsKey(question.id)) {
        sMax += question.options.length;
      }
    }

    // Hitung batas kuartil teoritis
    double r = (sMax - sMin).toDouble();
    double k1 = sMin + (0.25 * r);
    double k2 = sMin + (0.50 * r);
    double k3 = sMin + (0.75 * r);

    // Tentukan kategori (Sangat Rendah, Rendah, Tinggi, Sangat Tinggi)
    String riskLevel;
    if (totalScore < k1) {
      riskLevel = 'Sangat Rendah';
    } else if (totalScore < k2) {
      riskLevel = 'Rendah';
    } else if (totalScore < k3) {
      riskLevel = 'Tinggi';
    } else {
      riskLevel = 'Sangat Tinggi';
    }

    int maxScore = sMax;

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
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://autisme-app.com', // Optional: untuk tracking
          'X-Title': 'Autisme Screening App', // Optional: untuk tracking
        },
        body: jsonEncode({
          'model': modelId,
          'messages': [
            {
              'role': 'system',
              'content':
                  'Anda adalah asisten ahli dalam diagnosis dini autisme pada anak. Berikan rekomendasi dalam bahasa Indonesia yang empatik, tidak menghakimi, dan memberikan harapan.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Extract text from OpenRouter/OpenAI response structure
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'];
          if (message != null && message['content'] != null) {
            return message['content'] ??
                _getFallbackRecommendation(riskLevel, affectedAspects);
          }
        }
        return _getFallbackRecommendation(riskLevel, affectedAspects);
      } else {
        debugPrint('AI Error: ${response.statusCode} - ${response.body}');
        return _getFallbackRecommendation(riskLevel, affectedAspects);
      }
    } catch (e) {
      debugPrint('AI Error: $e');
      return _getFallbackRecommendation(riskLevel, affectedAspects);
    }
  }

  String _getFallbackRecommendation(
    String riskLevel,
    List<String> affectedAspects,
  ) {
    // Rekomendasi fallback jika AI tidak tersedia
    if (riskLevel == 'Sangat Rendah') {
      return '''
Hasil screening menunjukkan sangat sedikit karakteristik perilaku yang berkaitan dengan ASD berdasarkan hasil screening.

Rekomendasi:
• Terus lakukan stimulasi perkembangan secara rutin
• Pantau milestone perkembangan anak
• Konsultasikan ke dokter anak saat jadwal imunisasi rutin
''';
    } else if (riskLevel == 'Rendah') {
      return '''
Hasil screening menunjukkan sedikit karakteristik perilaku yang berkaitan dengan ASD berdasarkan hasil screening.

Rekomendasi:
• Berikan lebih banyak waktu bermain interaktif
• Ajak anak berkomunikasi lebih sering
• Lakukan pemantauan secara rutin
''';
    } else if (riskLevel == 'Tinggi') {
      return '''
Hasil screening menunjukkan cukup banyak karakteristik perilaku yang berkaitan dengan ASD. Disarankan dilakukan observasi dan pemantauan lebih lanjut.

Rekomendasi:
• Segera konsultasikan ke Dokter Spesialis Anak atau Psikolog Anak
• Mulai cari informasi tentang intervensi dini
• Fokus stimulasi pada aspek: ${affectedAspects.join(', ')}
''';
    } else {
      // Sangat Tinggi
      return '''
Hasil screening menunjukkan banyak karakteristik perilaku yang berkaitan dengan ASD berdasarkan hasil screening awal. Disarankan untuk berkonsultasi lebih lanjut dengan tenaga profesional seperti dokter spesialis anak, psikolog, atau psikiater anak untuk evaluasi lanjutan.

Rekomendasi:
• Sangat disarankan untuk segera menemui profesional spesialis
• Diperlukan evaluasi komprehensif sesegera mungkin
• Persiapkan catatan perilaku anak yang Anda perhatikan
''';
    }
  }
}
