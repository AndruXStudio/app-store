import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_model.dart';

/// 自建信任库：public.apps（Supabase）
class CatalogService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<AppModel>> fetchAll({String? category}) async {
    try {
      var query = _client
          .from('apps')
          .select()
          .eq('published', true)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: false);

      final rows = await query;
      var list = (rows as List).map(_fromRow).toList();
      if (category != null && category != 'all') {
        list = list.where((a) => a.category == category).toList();
      }
      return list;
    } catch (e) {
      // 表不存在或 RLS：返回空，由上层回退其它源
      return [];
    }
  }

  Future<List<AppModel>> search(String keyword) async {
    final q = keyword.trim();
    if (q.isEmpty) return fetchAll();
    try {
      final rows = await _client
          .from('apps')
          .select()
          .eq('published', true)
          .or('name.ilike.%$q%,developer.ilike.%$q%,description.ilike.%$q%,package_name.ilike.%$q%')
          .order('sort_order', ascending: true);
      return (rows as List).map(_fromRow).toList();
    } catch (_) {
      return [];
    }
  }

  AppModel _fromRow(dynamic row) {
    final m = Map<String, dynamic>.from(row as Map);
    final downloadUrl = m['download_url']?.toString() ?? '';
    final name = m['name']?.toString() ?? 'App';
    final size = m['size_label']?.toString() ?? m['size']?.toString() ?? '';
    return AppModel(
      id: 'catalog_${m['id']}',
      name: name,
      developer: m['developer']?.toString() ?? 'AnNexus',
      description: m['description']?.toString() ?? '',
      iconUrl: m['icon_url']?.toString() ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=01875F&color=fff',
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
