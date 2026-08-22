import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;

    // Try load profile from public.users
    String username = user.userMetadata?['username']?.toString() ??
        user.email?.split('@').first ??
        'User';
    String? avatarUrl = user.userMetadata?['avatar_url']?.toString();

    try {
      final row = await _client
          .from('users')
          .select('username, avatar_url, email')
          .eq('id', user.id)
          .maybeSingle();
      if (row != null) {
        username = row['username']?.toString() ?? username;
        avatarUrl = row['avatar_url']?.toString() ?? avatarUrl;
      }
    } catch (_) {}

    return UserModel(
      id: user.id,
      username: username,
      email: user.email,
      avatarUrl: avatarUrl,
    );
  }

  /// Register with username + email + password
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

    // Upsert profile into public.users if table exists
    final user = response.user;
    if (user != null) {
      try {
        await _client.from('users').upsert({
          'id': user.id,
          'username': username,
          'email': email,
        });
      } catch (_) {
        // table may have different columns; ignore
      }
    }
    return response;
  }

  /// Login with email OR username
  Future<AuthResponse> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    String email = emailOrUsername.trim();

    // If looks like username (no @), try resolve email from public.users
    if (!email.contains('@')) {
      try {
        final row = await _client
            .from('users')
            .select('email')
            .eq('username', email)
            .maybeSingle();
        if (row != null && row['email'] != null) {
          email = row['email'].toString();
        } else {
          // fallback: common patterns people use
          // keep original and let auth fail with clear message
        }
      } catch (_) {
        // users table query failed (RLS / no table) — try as email anyway
      }
    }

    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
