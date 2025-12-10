// lib/pages/screening_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart'; // Pastikan sudah di add di pubspec
import 'package:autisme/models/question_model.dart';
import 'package:autisme/services/gemini_service.dart'; // Import service AI

class ScreeningPage extends StatefulWidget {
  final int childAgeMonths;

  const ScreeningPage({super.key, required this.childAgeMonths});

  @override
  State<ScreeningPage> createState() => _ScreeningPageState();
}

class _ScreeningPageState extends State<ScreeningPage> {
  final PageController _pageController = PageController();
  final GeminiService _geminiService =
      GeminiService(); // Inisialisasi Service AI

  int _currentPage = 0;
  List<ScreeningQuestion> _filteredQuestions = [];
  bool _isLoading = true;
  final Map<int, int> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final String response = await rootBundle.loadString(
      'assets/data/screening_data.json',
    );

    final List<ScreeningQuestion> loadedQuestions = parseQuestions(response);

    List<ScreeningQuestion> ageAppropriate = loadedQuestions
        .where((q) => q.ageMonths <= widget.childAgeMonths)
        .toList();

    List<ScreeningQuestion> selectedQuestions = [];

    // LIMIT LOGIC: Maksimal 20 Pertanyaan
    if (ageAppropriate.length <= 20) {
      selectedQuestions = ageAppropriate;
    } else {
      Map<String, List<ScreeningQuestion>> groups = {};
      for (var q in ageAppropriate) {
        String key = "${q.aspect}-${q.section}";
        if (!groups.containsKey(key)) {
          groups[key] = [];
        }
        groups[key]!.add(q);
      }

      List<String> groupKeys = groups.keys.toList();
      Set<int> selectedIds = {};

      for (var key in groupKeys) {
        if (selectedQuestions.length >= 20) break;
        var groupQuestions = groups[key]!;
        var q = groupQuestions[0];
        selectedQuestions.add(q);
        selectedIds.add(q.id);
      }

      if (selectedQuestions.length < 20) {
        List<ScreeningQuestion> remaining = ageAppropriate
            .where((q) => !selectedIds.contains(q.id))
            .toList();

        int slotsNeeded = 20 - selectedQuestions.length;
        for (int i = 0; i < slotsNeeded && i < remaining.length; i++) {
          selectedQuestions.add(remaining[i]);
        }
      }

      selectedQuestions.sort((a, b) => a.id.compareTo(b.id));
    }

    setState(() {
      _filteredQuestions = selectedQuestions;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _filteredQuestions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _finishTestWithAI(); // Panggil fungsi baru yang menggunakan AI
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  // Fungsi untuk menyelesaikan tes dan memanggil AI
  Future<void> _finishTestWithAI() async {
    // 1. Hitung Total Skor
    int totalScore = _answers.values.fold(0, (sum, item) => sum + item);

    // 2. Tampilkan Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Sedang menganalisis jawaban dengan AI..."),
          ],
        ),
      ),
    );

    // 3. Panggil Gemini AI
    String analysisResult = await _geminiService.analyzeScreeningResult(
      totalScore: totalScore,
      questions: _filteredQuestions,
      answers: _answers,
    );

    // 4. Tutup Loading Dialog
    if (!mounted) return;
    Navigator.of(context).pop();

    // 5. Tampilkan Hasil
    _showResultDialog(totalScore, analysisResult);
  }

  void _showResultDialog(int totalScore, String aiAnalysis) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.psychology, color: Colors.blue.shade800),
            const SizedBox(width: 10),
            const Text(
              'Hasil Analisis AI',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Skor:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "$totalScore",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Render teks Markdown dari AI
                MarkdownBody(
                  data: aiAnalysis,
                  styleSheet: MarkdownStyleSheet(
                    h1: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    h2: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    p: const TextStyle(fontSize: 14, height: 1.5),
                    strong: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                Navigator.of(context).pop(); // Kembali ke menu utama
              },
              child: const Text('Selesai', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_filteredQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Screening')),
        body: const Center(
          child: Text('Tidak ada pertanyaan untuk kategori usia ini.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screening Test'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentPage + 1) / _filteredQuestions.length,
              backgroundColor: Colors.grey[200],
              color: Colors.blue.shade800,
            ),
            const SizedBox(height: 16),

            Text(
              'Pertanyaan ${_currentPage + 1}/${_filteredQuestions.length}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredQuestions.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildQuestionCard(_filteredQuestions[index]);
                },
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentPage == 0 ? null : _goToPreviousPage,
                  child: const Text('Kembali'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                  ),
                  onPressed:
                      _answers.containsKey(_filteredQuestions[_currentPage].id)
                      ? _goToNextPage
                      : null,
                  child: Text(
                    _currentPage == _filteredQuestions.length - 1
                        ? 'Analisis AI'
                        : 'Lanjut',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(ScreeningQuestion question) {
    return SingleChildScrollView(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${question.aspect} - ${question.section}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                question.question,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              ...question.options.map((option) {
                return RadioListTile<int>(
                  title: Text(option.text),
                  value: option.score,
                  groupValue: _answers[question.id],
                  activeColor: Colors.blue.shade800,
                  onChanged: (int? value) {
                    setState(() {
                      _answers[question.id] = value!;
                    });
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
