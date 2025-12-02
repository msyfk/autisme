// lib/pages/screening_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:autisme/models/question_model.dart';

class ScreeningPage extends StatefulWidget {
  final int childAgeMonths; // Menerima umur anak

  const ScreeningPage({super.key, required this.childAgeMonths});

  @override
  State<ScreeningPage> createState() => _ScreeningPageState();
}

class _ScreeningPageState extends State<ScreeningPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<ScreeningQuestion> _allQuestions = [];
  List<ScreeningQuestion> _filteredQuestions = [];
  bool _isLoading = true;

  // Menyimpan jawaban: key = question ID, value = skor
  final Map<int, int> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    // 1. Load JSON dari assets
    final String response = await rootBundle.loadString(
      'assets/data/screening_data.json',
    );

    // 2. Parse ke objek Dart
    final List<ScreeningQuestion> loadedQuestions = parseQuestions(response);

    // 3. FILTER LOGIC: Ambil soal yang usianya <= usia anak
    List<ScreeningQuestion> ageAppropriate = loadedQuestions
        .where((q) => q.ageMonths <= widget.childAgeMonths)
        .toList();

    List<ScreeningQuestion> selectedQuestions = [];

    // 4. LIMIT LOGIC: Maksimal 20 Pertanyaan & Wajib mewakili setiap bagian
    if (ageAppropriate.length <= 20) {
      selectedQuestions = ageAppropriate;
    } else {
      // Jika lebih dari 20, kita pilih secara cerdas agar semua aspek/bagian terwakili

      // Grouping berdasarkan key unik "Aspek - Bagian"
      Map<String, List<ScreeningQuestion>> groups = {};
      for (var q in ageAppropriate) {
        String key = "${q.aspect}-${q.section}";
        if (!groups.containsKey(key)) {
          groups[key] = [];
        }
        groups[key]!.add(q);
      }

      // Langkah 4a: Ambil minimal 1 soal dari setiap grup (Bagian)
      List<String> groupKeys = groups.keys.toList();
      Set<int> selectedIds = {};

      for (var key in groupKeys) {
        if (selectedQuestions.length >= 20) break;

        var groupQuestions = groups[key]!;
        // Ambil soal pertama dari grup tersebut (bisa diubah jadi random jika mau variasi)
        var q = groupQuestions[0];

        selectedQuestions.add(q);
        selectedIds.add(q.id);
      }

      // Langkah 4b: Jika masih kurang dari 20, isi dengan sisa soal yang belum terpilih
      if (selectedQuestions.length < 20) {
        List<ScreeningQuestion> remaining = ageAppropriate
            .where((q) => !selectedIds.contains(q.id))
            .toList();

        // Ambil sisa kuota untuk mencapai 20
        int slotsNeeded = 20 - selectedQuestions.length;
        for (int i = 0; i < slotsNeeded && i < remaining.length; i++) {
          selectedQuestions.add(remaining[i]);
        }
      }

      // Opsional: Urutkan kembali berdasarkan ID agar urutan soal logis
      selectedQuestions.sort((a, b) => a.id.compareTo(b.id));
    }

    setState(() {
      _allQuestions = loadedQuestions;
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

  void _finishTest() {
    // Hitung total skor
    int totalScore = _answers.values.fold(0, (sum, item) => sum + item);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tes Selesai'),
        content: Text(
          'Terima kasih. Total Skor: $totalScore\n(Logika diagnosa dapat ditambahkan di sini)',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Tutup dialog
              Navigator.of(context).pop(); // Kembali ke menu utama
            },
            child: const Text('Selesai'),
          ),
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
                physics:
                    const NeverScrollableScrollPhysics(), // User harus klik tombol/opsi
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
                  // Tombol lanjut hanya aktif jika pertanyaan ini sudah dijawab
                  onPressed:
                      _answers.containsKey(_filteredQuestions[_currentPage].id)
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
              // Menampilkan Aspek dan Bagian
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

              // Menampilkan Opsi Jawaban Dinamis
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
