// lib/services/history_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:autisme/models/screening_history_model.dart';
import 'package:autisme/models/diagnosis_model.dart';

class HistoryService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String tableName = 'screening_history';

  // Menyimpan hasil screening ke database
  Future<void> saveScreeningResult({
    required DiagnosisResult result,
    required int childAgeMonths,
    String? childId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Pengguna belum login');
    }

    final history = ScreeningHistory(
      userId: user.id,
      childId: childId,
      childAgeMonths: childAgeMonths,
      createdAt: DateTime.now(),
      result: result,
    );

    await _supabase.from(tableName).insert(history.toJson());
  }

  // Mengambil daftar riwayat screening pengguna saat ini
  Future<List<ScreeningHistory>> getScreeningHistory({String? childId}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Pengguna belum login');
    }

    var query = _supabase.from(tableName).select().eq('user_id', user.id);

    if (childId != null) {
      query = query.eq('child_id', childId);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => ScreeningHistory.fromJson(e)).toList();
  }

  // Menghapus satu riwayat
  Future<void> deleteHistory(String id) async {
    await _supabase.from(tableName).delete().eq('id', id);
  }
}
