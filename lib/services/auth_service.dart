import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Register dengan email dan password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    return response;
  }

  // Login dengan email dan password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  // Logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Cek user saat ini
  User? get currentUser => _supabase.auth.currentUser;

  // Stream untuk mendengarkan perubahan auth state
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
