// lib/pages/diagnosis_result_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
        return Icons.check_circle_outline;
      case 'Sedang':
        return Icons.warning_amber_outlined;
      case 'Tinggi':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Hasil Screening'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ringkasan Utama (Minimalist)
            Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: _getRiskColor().withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getRiskColor().withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(_getRiskIcon(), size: 64, color: _getRiskColor()),
                  const SizedBox(height: 16),
                  Text(
                    'Risiko ${diagnosis.riskLevel}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getRiskColor(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Usia Anak: $childAgeMonths Bulan',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${diagnosis.totalScore}',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        ' / ${diagnosis.maxScore} Skor',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: diagnosis.percentage / 100,
                      backgroundColor: Colors.white,
                      color: _getRiskColor(),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Card Aspek yang Terpengaruh
            if (diagnosis.affectedAspects.isNotEmpty) ...[
              Text(
                'Perlu Perhatian',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: diagnosis.affectedAspects
                      .map(
                        (aspect) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  aspect,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Detail Skor per Aspek
            Text(
              'Detail Skor',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: diagnosis.aspectScores.entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${entry.value}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value:
                                    entry.value /
                                    diagnosis.aspectScores.entries
                                        .map((e) => e.value)
                                        .reduce((a, b) => a > b ? a : b),
                                backgroundColor: Colors.grey.shade100,
                                color: Theme.of(context).colorScheme.primary,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Rekomendasi AI
            Text(
              'Rekomendasi Ahli',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: MarkdownBody(
                data: diagnosis.aiRecommendation,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.grey.shade800,
                  ),
                  strong: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  h1: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  h2: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  h3: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  listBullet: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  blockSpacing: 16,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Disclaimer Minimalis
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hasil ini adalah screening awal dan bukan diagnosis medis. Konsultasikan dengan profesional untuk evaluasi lebih lanjut.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Tombol Kembali
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Selesai'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
