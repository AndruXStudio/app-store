import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class CommunityService {
  final _client = Supabase.instance.client;
  final _auth = AuthService();

  Future<List<Map<String, dynamic>>> fetchComments(int appId) async {
    try {
      final rows = await _client
          .from('app_comments')
          .select()
          .eq('app_id', appId)
          .order('created_at', ascending: false);
      return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addComment(int appId, String content) async {
    final user = await _auth.getCurrentUserModel();
    if (user == null) throw Exception('请先登录');
    await _client.from('app_comments').insert({
      'app_id': appId,
      'user_id': user.id.isNotEmpty ? user.id : user.username,
      'username': user.username,
      'content': content.trim(),
    });
  }

  Future<void> deleteComment(int commentId) async {
    await _client.from('app_comments').delete().eq('id', commentId);
  }

  Future<void> report({
    required String targetType,
    required String targetId,
    String? reason,
  }) async {
    final user = await _auth.getCurrentUserModel();
    await _client.from('reports').insert({
      'target_type': targetType,
      'target_id': targetId,
      'reporter_id': user?.id ?? user?.username,
      'reason': reason ?? '',
    });
  }

  Future<bool> isLiked(int appId) async {
    final user = await _auth.getCurrentUserModel();
    if (user == null) return false;
    final uid = user.id.isNotEmpty ? user.id : user.username;
    try {
      final row = await _client
          .from('app_likes')
          .select()
          .eq('app_id', appId)
          .eq('user_id', uid)
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleLike(int appId) async {
    final user = await _auth.getCurrentUserModel();
    if (user == null) throw Exception('请先登录');
    final uid = user.id.isNotEmpty ? user.id : user.username;
    final liked = await isLiked(appId);
    if (liked) {
      await _client.from('app_likes').delete().eq('app_id', appId).eq('user_id', uid);
    } else {
      await _client.from('app_likes').insert({'app_id': appId, 'user_id': uid});
    }
  }

  Future<bool> isFavorited(int appId) async {
    final user = await _auth.getCurrentUserModel();
    if (user == null) return false;
    final uid = user.id.isNotEmpty ? user.id : user.username;
    try {
      final row = await _client
          .from('app_favorites')
          .select()
          .eq('app_id', appId)
          .eq('user_id', uid)
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleFavorite(int appId) async {
    final user = await _auth.getCurrentUserModel();
    if (user == null) throw Exception('请先登录');
    final uid = user.id.isNotEmpty ? user.id : user.username;
    final fav = await isFavorited(appId);
    if (fav) {
      await _client.from('app_favorites').delete().eq('app_id', appId).eq('user_id', uid);
    } else {
      await _client.from('app_favorites').insert({'app_id': appId, 'user_id': uid});
    }
  }
}
