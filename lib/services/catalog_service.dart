import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_model.dart';
import 'auth_service.dart';

class CatalogService {
  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _auth = AuthService();

  Future<List<AppModel>> fetchPublished({String? category}) async {
    try {
      final rows = await _client
          .from('apps')
          .select()
          .eq('published', true)
          .eq('status', 'approved')
          .order('sort_order', ascending: true)
          .order('created_at', ascending: false);
      var list = (rows as List).map(_fromRow).toList();
      if (category != null && category != 'all') {
        list = list.where((a) => a.category == category).toList();
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<List<AppModel>> search(String keyword) async {
    final q = keyword.trim();
    if (q.isEmpty) return fetchPublished();
    try {
      final rows = await _client
          .from('apps')
          .select()
          .eq('published', true)
          .eq('status', 'approved')
          .or('name.ilike.%$q%,developer.ilike.%$q%,description.ilike.%$q%,package_name.ilike.%$q%');
      return (rows as List).map(_fromRow).toList();
    } catch (_) {
      return [];
    }
  }

  /// 用户投稿 → pending
  Future<void> submitApp({
    required String name,
    required String downloadUrl,
    String? packageName,
    String? developer,
    String? description,
    String? iconUrl,
    String? version,
    String? sizeLabel,
    String category = 'app',
    String? changelog,
  }) async {
    final user = await _auth.getCurrentUserModel();
    final role = await getMyRole();
    await _client.from('apps').insert({
      'name': name,
      'package_name': packageName,
      'developer': developer ?? user?.username ?? '用户',
      'description': description ?? '',
      'icon_url': iconUrl,
      'version': version ?? '1.0.0',
      'size_label': sizeLabel ?? '',
      'download_url': downloadUrl,
      'category': category,
      'changelog': changelog,
      'published': false,
      'status': 'pending',
      'submitter_id': user?.id ?? user?.username,
      'publisher_role': role,
    });
  }

  Future<List<Map<String, dynamic>>> fetchPending() async {
    try {
      final rows = await _client
          .from('apps')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> reviewApp(int id, {required bool approve, String? note}) async {
    final res = await _client
        .from('apps')
        .update({
          'status': approve ? 'approved' : 'rejected',
          'published': approve,
          'reviewed_at': DateTime.now().toIso8601String(),
          'review_note': note,
        })
        .eq('id', id)
        .select('id, status, published');
    if (res is! List || res.isEmpty) {
      throw Exception('更新失败：没有权限或记录不存在（请检查 RLS 的 UPDATE 策略）');
    }
  }

  Future<List<AppModel>> fetchBySubmitter(String submitterId) async {
    try {
      final rows = await _client
          .from('apps')
          .select()
          .eq('submitter_id', submitterId)
          .order('created_at', ascending: false);
      return (rows as List).map(_fromRow).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteApp(int id) async {
    await _client.from('apps').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> fetchVersions(int appId) async {
    try {
      final rows = await _client
          .from('app_versions')
          .select()
          .eq('app_id', appId)
          .order('created_at', ascending: false);
      return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String> getMyRole() async {
    final user = await _auth.getCurrentUserModel();
    if (user == null) return 'user';
    try {
      final row = await _client
          .from('users')
          .select('role')
          .or('id.eq.${user.id},users.eq.${user.username}')
          .maybeSingle();
      return row?['role']?.toString() ?? 'user';
    } catch (_) {
      return 'user';
    }
  }

  Future<bool> isStaff() async {
    final r = await getMyRole();
    return r == 'admin' || r == 'creator';
  }

  AppModel _fromRow(dynamic row) {
    final m = Map<String, dynamic>.from(row as Map);
    final downloadUrl = m['download_url']?.toString() ?? '';
    final name = m['name']?.toString() ?? 'App';
    final size = m['size_label']?.toString() ?? '';
    final role = m['publisher_role']?.toString() ?? 'user';
    return AppModel(
      id: 'catalog_${m['id']}',
      name: name,
      developer: m['developer']?.toString() ?? 'AnNexus',
      description: m['description']?.toString() ?? '',
      iconUrl: m['icon_url']?.toString() ?? '',
      rating: (m['rating'] as num?)?.toDouble() ?? 4.5,
      downloads: (m['downloads'] as num?)?.toInt() ?? 0,
      category: m['category']?.toString() == 'game' ? 'game' : 'app',
      version: m['version']?.toString() ?? '1.0.0',
      size: size.isEmpty ? '未知' : size,
      downloadUrl: downloadUrl,
      githubUrl: m['homepage']?.toString(),
      language: m['language']?.toString(),
      fileType: 'apk',
      packageName: m['package_name']?.toString(),
      source: 'catalog',
      publisherRole: role,
      submitterRole: role,
      submitterUsername: m['developer']?.toString(),
      catalogId: m['id'] is int ? m['id'] as int : int.tryParse('${m['id']}'),
      submitterId: m['submitter_id']?.toString(),
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
