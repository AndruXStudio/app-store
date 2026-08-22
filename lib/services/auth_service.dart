import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  static const _keyLoggedIn = 'annexus_logged_in';
  static const _keyUserId = 'annexus_user_id';
  static const _keyUsername = 'annexus_username';
  static const _keyEmail = 'annexus_email';
  static const _keyAvatar = 'annexus_avatar';

  /// 当前是否已登录（本地会话）
  Future<bool> get isLoggedIn async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  Future<UserModel?> getCurrentUserModel() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_keyLoggedIn) ?? false)) return null;
    return UserModel(
      id: prefs.getString(_keyUserId) ?? '',
      username: prefs.getString(_keyUsername) ?? 'User',
      email: prefs.getString(_keyEmail),
      avatarUrl: prefs.getString(_keyAvatar),
    );
  }

  /// 登录：查 public.users 表
  /// 字段：users = 用户名，password = 密码
  Future<UserModel> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    final input = emailOrUsername.trim();
    final pwd = password;

    // 先按用户名查
    var row = await _client
        .from('users')
        .select()
        .eq('users', input)
        .eq('password', pwd)
        .maybeSingle();

    // 若没找到且输入像邮箱，再按 email 查（兼容）
    if (row == null && input.contains('@')) {
      row = await _client
          .from('users')
          .select()
          .eq('email', input)
          .eq('password', pwd)
          .maybeSingle();
    }

    if (row == null) {
      throw Exception('用户名或密码错误');
    }

    final user = UserModel(
      id: row['id']?.toString() ?? input,
      username: row['users']?.toString() ?? input,
      email: row['email']?.toString(),
      avatarUrl: row['avatar_url']?.toString() ?? row['avatar']?.toString(),
    );

    await _saveSession(user);
    return user;
  }

  /// 注册：写入 public.users
  Future<UserModel> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    // 检查用户名是否已存在
    final exists = await _client
        .from('users')
        .select('users')
        .eq('users', username.trim())
        .maybeSingle();
    if (exists != null) {
      throw Exception('用户名已被占用');
    }

    final data = {
      'users': username.trim(),
      'password': password,
      'email': email.trim(),
    };

    final row = await _client.from('users').insert(data).select().single();

    final user = UserModel(
      id: row['id']?.toString() ?? username,
      username: row['users']?.toString() ?? username,
      email: row['email']?.toString() ?? email,
      avatarUrl: row['avatar_url']?.toString(),
    );

    await _saveSession(user);
    return user;
  }

  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyUserId, user.id);
    await prefs.setString(_keyUsername, user.username);
    if (user.email != null) await prefs.setString(_keyEmail, user.email!);
    if (user.avatarUrl != null) await prefs.setString(_keyAvatar, user.avatarUrl!);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyAvatar);
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }
}
