import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/app_model.dart';

class CommunityService {
  final _c = Supabase.instance.client;

  Future<String> getUserRole(String username) async {
    try {
      final row = await _c.from('users').select('role').eq('users', username).maybeSingle();
      return row?['role']?.toString() ?? 'user';
    } catch (_) {
      return 'user';
    }
  }

  Future<Map<String, dynamic>?> getProfile(String username) async {
    try {
      return await _c.from('users').select().eq('users', username).maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfile({
    required String username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? tags,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['display_name'] = displayName;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (bio != null) data['bio'] = bio;
    if (tags != null) data['tags'] = tags;
    if (data.isEmpty) return;
    await _c.from('users').update(data).eq('users', username);
  }

  /// 上传 APK 到 Supabase Storage，返回公开 URL
  Future<String> uploadApk(File file, String username) async {
    if (kIsWeb) throw Exception('Web 端请使用直链方式');
    final name = file.path.split(RegExp(r'[/\\]')).last;
    final safe = name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final path = 'apks/$username/${DateTime.now().millisecondsSinceEpoch}_$safe';

    await _c.storage.from('apps').upload(
          path,
          file,
          fileOptions: FileOptions(contentType: 'application/vnd.android.package-archive', upsert: true),
        );

    return _c.storage.from('apps').getPublicUrl(path);
  }

  /// 可选：上传图标
  Future<String> uploadIcon(File file, String username) async {
    final name = file.path.split(RegExp(r'[/\\]')).last;
    final safe = name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final path = 'icons/$username/${DateTime.now().millisecondsSinceEpoch}_$safe';
    await _c.storage.from('apps').upload(
          path,
          file,
          fileOptions: FileOptions(upsert: true),
        );
    return _c.storage.from('apps').getPublicUrl(path);
  }

  Future<void> submitApp({
    required String name,
    required String packageName,
    required String developer,
    required String description,
    required String downloadUrl,
    required String version,
    required String sizeLabel,
    required String submitterUsername,
    required String submitterRole,
    String? iconUrl,
    String category = 'app',
    String? changelog,
  }) async {
    await _c.from('apps').insert({
      'name': name,
      'package_name': packageName,
      'developer': developer,
      'description': description,
      'download_url': downloadUrl,
      'version': version,
      'size_label': sizeLabel,
      'icon_url': iconUrl,
      'category': category,
      'changelog': changelog,
      'submitter_username': submitterUsername,
      'submitter_role': submitterRole,
      'status': 'pending',
      'published': false,
    });
  }

  Future<List<Map<String, dynamic>>> pendingApps() async {
    final rows = await _c
        .from('apps')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> reviewApp(int id, {required bool approve, String? reason}) async {
    final payload = {
      'status': approve ? 'approved' : 'rejected',
      'published': approve,
      'reject_reason': reason,
      'reviewed_at': DateTime.now().toIso8601String(),
    };
    final res = await _c.from('apps').update(payload).eq('id', id).select('id,status,published');
    if (res is! List || res.isEmpty) {
      throw Exception('更新失败：没有权限或记录不存在。请在 Supabase SQL 执行 UPDATE 策略。');
    }
  }

  Future<List<AppModel>> appsByUser(String username) async {
    final rows = await _c
        .from('apps')
        .select()
        .eq('submitter_username', username)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => _appFromRow(r)).toList();
  }

  Future<List<AppModel>> myPosts(String username) async => appsByUser(username);

  Future<void> deleteMyApp(int id, String username) async {
    await _c.from('apps').delete().eq('id', id).eq('submitter_username', username);
  }

  Future<List<Map<String, dynamic>>> comments(int appId) async {
    final rows = await _c
        .from('app_comments')
        .select()
        .eq('app_id', appId)
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> addComment(int appId, String username, String content) async {
    await _c.from('app_comments').insert({
      'app_id': appId,
      'username': username,
      'content': content,
    });
  }

  Future<void> deleteComment(int id) async {
    await _c.from('app_comments').delete().eq('id', id);
  }

  Future<void> report({
    required String targetType,
    required String targetId,
    required String reporter,
    String reason = '',
  }) async {
    await _c.from('reports').insert({
      'target_type': targetType,
      'target_id': targetId,
      'reporter': reporter,
      'reason': reason,
    });
  }

  Future<int> likeCount(int appId) async {
    final rows = await _c.from('app_likes').select('id').eq('app_id', appId);
    return (rows as List).length;
  }

  Future<bool> hasLiked(int appId, String username) async {
    final row = await _c
        .from('app_likes')
        .select('id')
        .eq('app_id', appId)
        .eq('username', username)
        .maybeSingle();
    return row != null;
  }

  Future<void> toggleLike(int appId, String username) async {
    if (await hasLiked(appId, username)) {
      await _c.from('app_likes').delete().eq('app_id', appId).eq('username', username);
    } else {
      await _c.from('app_likes').insert({'app_id': appId, 'username': username});
    }
  }

  AppModel _appFromRow(dynamic row) {
    final m = Map<String, dynamic>.from(row as Map);
    final id = m['id'];
    final name = m['name']?.toString() ?? 'App';
    final downloadUrl = m['download_url']?.toString() ?? '';
    final size = m['size_label']?.toString() ?? '';
    final role = m['submitter_role']?.toString() ?? 'user';
    return AppModel(
      id: 'catalog_$id',
      name: name,
      developer: m['developer']?.toString() ?? '',
      description: m['description']?.toString() ?? '',
      iconUrl: m['icon_url']?.toString() ?? '',
      rating: (m['rating'] as num?)?.toDouble() ?? 4.5,
      downloads: (m['downloads'] as num?)?.toInt() ?? 0,
      category: m['category']?.toString() == 'game' ? 'game' : 'app',
      version: m['version']?.toString() ?? '1.0',
      size: size.isEmpty ? '未知' : size,
      downloadUrl: downloadUrl,
      packageName: m['package_name']?.toString(),
      fileType: 'apk',
      source: 'catalog',
      submitterRole: role,
      submitterUsername: m['submitter_username']?.toString(),
      catalogId: id is int ? id : int.tryParse('$id'),
      status: m['status']?.toString(),
      changelog: m['changelog']?.toString(),
      assets: downloadUrl.isEmpty
          ? []
          : [
              {
                'name': '${m['package_name'] ?? name}.apk',
                'url': downloadUrl,
                'size': size,
                'fileType': 'apk',
              }
            ],
    );
  }
}
