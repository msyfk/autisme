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
      data: {'full_name': fullName, 'children': []},
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

  // Update user profile
  Future<UserResponse> updateProfile({
    String? fullName,
    List<Map<String, dynamic>>? children,
  }) async {
    final Map<String, dynamic> data = {};

    if (fullName != null) {
      data['full_name'] = fullName;
    }

    if (children != null) {
      data['children'] = children;
    }

    final response = await _supabase.auth.updateUser(
      UserAttributes(data: data),
    );
    return response;
  }

  // Add a child
  Future<UserResponse> addChild({
    required String name,
    required int age,
  }) async {
    final currentChildren = getChildren();
    final newChild = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'age': age,
    };
    currentChildren.add(newChild);

    return updateProfile(children: currentChildren);
  }

  // Update a child
  Future<UserResponse> updateChild({
    required String childId,
    String? name,
    int? age,
  }) async {
    final currentChildren = getChildren();
    final index = currentChildren.indexWhere((c) => c['id'] == childId);

    if (index != -1) {
      if (name != null) currentChildren[index]['name'] = name;
      if (age != null) currentChildren[index]['age'] = age;
    }

    return updateProfile(children: currentChildren);
  }

  // Remove a child
  Future<UserResponse> removeChild(String childId) async {
    final currentChildren = getChildren();
    currentChildren.removeWhere((c) => c['id'] == childId);

    return updateProfile(children: currentChildren);
  }

  // Get children list
  List<Map<String, dynamic>> getChildren() {
    final metadata = _supabase.auth.currentUser?.userMetadata;
    if (metadata == null || metadata['children'] == null) {
      return [];
    }
    final children = metadata['children'] as List<dynamic>;
    return children.map((c) => Map<String, dynamic>.from(c)).toList();
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
