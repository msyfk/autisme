// lib/services/gemini_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:autisme/models/question_model.dart';

class GeminiService {
  // PENTING: Ganti string di bawah ini dengan API Key asli Anda dari Google AI Studio
  static const String _apiKey = 'AIzaSyD6ISH367XP_cVBeA1LvCaE8V308VkEuCs';

  late final GenerativeModel _model;

  GeminiService() {
    // PERBAIKAN DISINI: Mengganti 'gemini-pro' menjadi 'gemini-1.5-flash'
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
  }

  Future<String> analyzeScreeningResult({
    required int totalScore,
    required List<ScreeningQuestion> questions,
    required Map<int, int> answers,
  }) async {
    try {
      // 1. Susun Prompt (Instruksi) untuk AI
      final buffer = StringBuffer();
      buffer.writeln(
        "Bertindaklah sebagai ahli psikologi anak dan spesialis perkembangan anak.",
      );
      buffer.writeln(
        "Berikan analisis hasil skrining deteksi dini autisme (ASD) berikut ini:",
      );
      buffer.writeln(
        "\nTotal Skor: $totalScore (Skala penilaian: makin tinggi skor, makin tinggi risiko)",
      );
      buffer.writeln("\nRincian Jawaban:");

      for (var question in questions) {
        // Hanya sertakan pertanyaan yang dijawab
        if (answers.containsKey(question.id)) {
          final score = answers[question.id];
          // Cari teks opsi jawaban berdasarkan skor
          final selectedOption = question.options.firstWhere(
            (opt) => opt.score == score,
            orElse: () =>
                QuestionOption(text: "Jawaban tidak diketahui", score: 0),
          );

          buffer.writeln(
            "- ${question.question}: ${selectedOption.text} (Skor: $score)",
          );
        }
      }

      buffer.writeln("\nInstruksi Output:");
      buffer.writeln(
        "1. Tentukan kategori risiko (Rendah/Sedang/Tinggi) berdasarkan skor dan pola jawaban.",
      );
      buffer.writeln(
        "2. Berikan analisis singkat mengenai aspek mana yang paling perlu diperhatikan (Sosial, Komunikasi, atau Perilaku).",
      );
      buffer.writeln(
        "3. Berikan 3-5 rekomendasi konkret dan empatik untuk orang tua tentang apa yang harus dilakukan selanjutnya.",
      );
      buffer.writeln(
        "4. Gunakan bahasa yang menenangkan namun profesional (Bahasa Indonesia).",
      );
      buffer.writeln(
        "5. Format teks menggunakan Markdown agar mudah dibaca (gunakan Bold untuk poin penting).",
      );

      // 2. Kirim ke Gemini
      final content = [Content.text(buffer.toString())];
      final response = await _model.generateContent(content);

      return response.text ??
          "Maaf, tidak dapat menghasilkan analisis saat ini.";
    } catch (e) {
      return "Terjadi kesalahan saat menghubungkan ke AI: $e";
    }
  }
}
