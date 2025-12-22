// lib/pages/screening_page.dart (UPDATED)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:autisme/models/question_model.dart';
import 'package:autisme/services/ai_diagnosis_service.dart';
import 'package:autisme/pages/diagnosis_result_page.dart';

class ScreeningPage extends StatefulWidget {
  final int childAgeMonths;

  const ScreeningPage({super.key, required this.childAgeMonths});

  @override
  State<ScreeningPage> createState() => _ScreeningPageState();
}

class _ScreeningPageState extends State<ScreeningPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<ScreeningQuestion> _filteredQuestions = [];
  bool _isLoading = true;
  bool _isProcessing = false; // Untuk loading saat proses AI

  final Map<int, int> _answers = {};
  final AIDiagnosisService _aiService = AIDiagnosisService();

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
      _finishTest();
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

  Future<void> _finishTest() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Dapatkan diagnosis dari AI
      final diagnosis = await _aiService.getDiagnosis(
        childAgeMonths: widget.childAgeMonths,
        answers: _answers,
        questions: _filteredQuestions,
      );

      setState(() {
        _isProcessing = false;
      });

      // Navigasi ke halaman hasil
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DiagnosisResultPage(
              diagnosis: diagnosis,
              childAgeMonths: widget.childAgeMonths,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Terjadi Kesalahan'),
            content: Text(
              'Gagal memproses hasil diagnosis. Error: $e\n\n'
              'Silakan coba lagi atau hubungi administrator.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Progress bar
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

                // Area Pertanyaan
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

                // Tombol Navigasi
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
                          _answers.containsKey(
                            _filteredQuestions[_currentPage].id,
                          )
                          ? _goToNextPage
                          : null,
                      child: Text(
                        _currentPage == _filteredQuestions.length - 1
                            ? 'Selesai'
                            : 'Lanjut',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Loading overlay saat proses AI
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        const Text(
                          'Menganalisis Hasil...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AI sedang memproses data screening\ndan membuat rekomendasi untuk Anda',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
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
