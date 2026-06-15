// lib/pages/screening_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:autisme/models/question_model.dart';
import 'package:autisme/services/ai_diagnosis_service.dart';
import 'package:autisme/services/history_service.dart';
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
  bool _isProcessing = false;

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
        curve: Curves.easeInOut,
      );
    } else {
      _finishTest();
    }
  }

  Future<void> _finishTest() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final diagnosis = await _aiService.getDiagnosis(
        childAgeMonths: widget.childAgeMonths,
        answers: _answers,
        questions: _filteredQuestions,
      );

      try {
        await HistoryService().saveScreeningResult(
          result: diagnosis,
          childAgeMonths: widget.childAgeMonths,
        );
      } catch (e) {
        debugPrint('Gagal menyimpan riwayat: $e');
      }

      setState(() {
        _isProcessing = false;
      });

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text('Terjadi Kesalahan'),
            content: Text('Gagal memproses hasil diagnosis. Error: $e'),
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
    if (_isLoading) return _buildLoadingState();
    if (_filteredQuestions.isEmpty) return _buildEmptyState();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Screening',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (_currentPage > 0) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: const Text('Batalkan Screening?'),
                  content: const Text('Progres pengisian akan hilang.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Lanjut Mengisi'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Keluar',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / _filteredQuestions.length,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
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
                _buildBottomNavigation(),
              ],
            ),
          ),
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Menyiapkan Pertanyaan',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_late_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada pertanyaan',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Belum ada pertanyaan screening untuk usia anak yang dipilih.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(ScreeningQuestion question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERTANYAAN ${_currentPage + 1} DARI ${_filteredQuestions.length}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              question.aspect,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            question.question,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),

          // Options as simple clean list
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: question.options.map((option) {
                final isSelected = _answers[question.id] == option.score;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _answers[question.id] = option.score;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade400,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option.text,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: isSelected
                                      ? Colors.black87
                                      : Colors.grey.shade700,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final hasAnswered = _answers.containsKey(
      _filteredQuestions[_currentPage].id,
    );
    final isLastPage = _currentPage == _filteredQuestions.length - 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: hasAnswered ? _goToNextPage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isLastPage ? 'Selesai' : 'Lanjut',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.white, // Fully opaque white for clean look
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Memproses Hasil...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Harap tunggu sebentar',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
