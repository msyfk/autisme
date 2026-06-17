import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static const String oauthRedirectUrl =
      'com.musyaffak.neurosense://login-callback/';

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

  Future<AuthResponse> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    final serverClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];

    await googleSignIn.initialize(serverClientId: serverClientId);

    if (!googleSignIn.supportsAuthenticate()) {
      throw const AuthException(
        'Perangkat ini tidak mendukung Native Google Sign-In.',
      );
    }

    final googleUser = await googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw const AuthException('Google Sign-In gagal mendapatkan ID token.');
    }

    return _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  Future<bool> signInWithFacebook() {
    return _supabase.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: oauthRedirectUrl,
      authScreenLaunchMode: LaunchMode.inAppBrowserView,
    );
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

  bool get hasCompletedChildProfile {
    return getChildren().any((child) => getChildAgeMonths(child) != null);
  }

  int? getChildAgeMonths(Map<String, dynamic> child) {
    final value = child['age_months'] ?? child['age'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<UserResponse> savePrimaryChild({
    required String name,
    required int ageMonths,
    String? gender,
  }) {
    final currentChildren = getChildren();
    final child = {
      'id': currentChildren.isNotEmpty
          ? currentChildren.first['id']
          : DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'age_months': ageMonths,
      if (gender != null && gender.isNotEmpty) 'gender': gender,
    };

    if (currentChildren.isEmpty) {
      currentChildren.add(child);
    } else {
      currentChildren[0] = child;
    }

    return updateProfile(children: currentChildren);
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
      'age_months': age,
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
      if (age != null) currentChildren[index]['age_months'] = age;
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
