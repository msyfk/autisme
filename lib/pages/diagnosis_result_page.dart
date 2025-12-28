// lib/pages/diagnosis_result_page.dart

import 'package:flutter/material.dart';
import 'package:autisme/models/diagnosis_model.dart';
import 'package:autisme/services/reminder_service.dart';

class DiagnosisResultPage extends StatefulWidget {
  final DiagnosisResult diagnosis;
  final int childAgeMonths;

  const DiagnosisResultPage({
    super.key,
    required this.diagnosis,
    required this.childAgeMonths,
  });

  @override
  State<DiagnosisResultPage> createState() => _DiagnosisResultPageState();
}

class _DiagnosisResultPageState extends State<DiagnosisResultPage> {
  @override
  void initState() {
    super.initState();
    // Update tanggal screening terakhir saat halaman hasil dibuka
    ReminderService().updateLastScreeningDate();
  }

  DiagnosisResult get diagnosis => widget.diagnosis;
  int get childAgeMonths => widget.childAgeMonths;

  Color _getRiskColor() {
    switch (diagnosis.riskLevel) {
      case 'Rendah':
        return Colors.green;
      case 'Sedang':
        return Colors.orange;
      case 'Tinggi':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRiskIcon() {
    switch (diagnosis.riskLevel) {
      case 'Rendah':
        return Icons.check_circle;
      case 'Sedang':
        return Icons.warning;
      case 'Tinggi':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Diagnosis'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Ringkasan Skor
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(_getRiskIcon(), size: 80, color: _getRiskColor()),
                    const SizedBox(height: 16),
                    Text(
                      'Tingkat Risiko: ${diagnosis.riskLevel}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getRiskColor(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Usia Anak: $childAgeMonths Bulan',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Skor Total',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      '${diagnosis.totalScore} / ${diagnosis.maxScore}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: diagnosis.percentage / 100,
                      backgroundColor: Colors.grey[200],
                      color: _getRiskColor(),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${diagnosis.percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Card Aspek yang Terpengaruh
            if (diagnosis.affectedAspects.isNotEmpty) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            color: Colors.blue.shade800,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Aspek yang Memerlukan Perhatian',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...diagnosis.affectedAspects.map(
                        (aspect) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.fiber_manual_record,
                                size: 12,
                                color: Colors.blue.shade800,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  aspect,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Card Detail Skor per Aspek
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.pie_chart_outline,
                          color: Colors.blue.shade800,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Detail Skor per Aspek',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...diagnosis.aspectScores.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value:
                                        entry.value /
                                        diagnosis.aspectScores.entries
                                            .map((e) => e.value)
                                            .reduce((a, b) => a > b ? a : b),
                                    backgroundColor: Colors.grey[200],
                                    color: Colors.blue.shade800,
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${entry.value}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Card Rekomendasi AI
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          color: Colors.blue.shade800,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Rekomendasi Ahli',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      diagnosis.aiRecommendation,
                      style: const TextStyle(fontSize: 15, height: 1.6),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Penting: Hasil ini adalah screening awal dan bukan diagnosis medis. '
                      'Konsultasikan dengan dokter spesialis anak atau psikolog klinis '
                      'untuk evaluasi yang lebih komprehensif.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tombol Kembali
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Kembali ke home, hapus semua route sebelumnya
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text(
                'Kembali ke Beranda',
                style: TextStyle(fontSize: 18),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
