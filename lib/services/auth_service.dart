import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;
    return UserModel(
      id: user.id,
      username: user.userMetadata?['username'] ?? user.email?.split('@').first ?? 'User',
      email: user.email,
      avatarUrl: user.userMetadata?['avatar_url'],
    );
  }

  Future<AuthResponse> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
    return response;
  }

  Future<AuthResponse> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    // Try email first, if it looks like email
    String email = emailOrUsername;
    if (!emailOrUsername.contains('@')) {
      // Assume username, try to find email from profiles or just use as is
      // For simplicity, treat as email if no @, user may register with username as email prefix
      email = '$emailOrUsername@appstore.local';
    }
    try {
      return await _client.auth.signInWithPassword(
        email: emailOrUsername.contains('@') ? emailOrUsername : email,
        password: password,
      );
    } catch (_) {
      // Fallback: try original
      return await _client.auth.signInWithPassword(
        email: emailOrUsername,
        password: password,
      );
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
