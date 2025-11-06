// lib/pages/screening_page.dart

import 'package:flutter/material.dart';

// Enum untuk jawaban Ya/Tidak
enum Answer { ya, tidak }

class ScreeningPage extends StatefulWidget {
  const ScreeningPage({super.key});

  @override
  State<ScreeningPage> createState() => _ScreeningPageState();
}

class _ScreeningPageState extends State<ScreeningPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Daftar pertanyaan (Ganti dengan pertanyaan Anda)
  final List<String> _questions = [
    'Apakah anak Anda jarang melakukan kontak mata saat diajak berbicara?',
    'Apakah anak Anda kesulitan untuk memulai atau mempertahankan percakapan?',
    'Apakah anak Anda menunjukkan minat yang sangat kuat pada satu topik tertentu?',
    'Apakah anak Anda sering mengulang kata-kata atau frasa (ekolalia)?',
    'Apakah anak Anda merasa terganggu dengan perubahan rutinitas kecil?',
    // Tambahkan pertanyaan lain di sini
  ];

  // Tempat untuk menyimpan jawaban (saat ini hanya untuk UI)
  final Map<int, Answer?> _answers = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // Jika sudah di pertanyaan terakhir, selesaikan tes
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
    // Tampilkan dialog hasil (Contoh Sederhana)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tes Selesai'),
        content: const Text(
          'Terima kasih telah menyelesaikan tes screening. Hasil akan ditampilkan di sini.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Tutup dialog
              Navigator.of(context).pop(); // Kembali ke halaman dashboard
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screening Test'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Indikator Pertanyaan (Contoh: 1/10)
            Text(
              'Pertanyaan ${_currentPage + 1}/${_questions.length}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jawablah pertanyaan di bawah ini dengan jujur.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),

            // Konten Pertanyaan (PageView)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _questions.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildQuestionCard(_questions[index], index);
                },
              ),
            ),

            const SizedBox(height: 24),

            // Tombol Navigasi (Kembali & Lanjut)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol Kembali
                TextButton(
                  onPressed: _currentPage == 0
                      ? null
                      : _goToPreviousPage, // Nonaktifkan jika di halaman pertama
                  child: Text(
                    'Kembali',
                    style: TextStyle(
                      fontSize: 16,
                      color: _currentPage == 0
                          ? Colors.grey
                          : Colors.blue.shade800,
                    ),
                  ),
                ),

                // Tombol Lanjut
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _goToNextPage,
                  child: Text(
                    // Ubah teks tombol di pertanyaan terakhir
                    _currentPage == _questions.length - 1
                        ? 'Selesai'
                        : 'Lanjut',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk membuat kartu pertanyaan
  Widget _buildQuestionCard(String question, int index) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Membuat kartu pas dengan konten
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: const TextStyle(fontSize: 18, height: 1.5)),
            const SizedBox(height: 24),
            // Pilihan Jawaban
            RadioListTile<Answer>(
              title: const Text('Ya'),
              value: Answer.ya,
              groupValue: _answers[index],
              onChanged: (Answer? value) {
                setState(() {
                  _answers[index] = value;
                });
              },
            ),
            RadioListTile<Answer>(
              title: const Text('Tidak'),
              value: Answer.tidak,
              groupValue: _answers[index],
              onChanged: (Answer? value) {
                setState(() {
                  _answers[index] = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
