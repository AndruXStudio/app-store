import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_model.dart';

class CatalogService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<AppModel>> fetchAll({String? category}) async {
    try {
      final rows = await _client
          .from('apps')
          .select()
          .or('published.eq.true,status.eq.approved')
          .order('sort_order', ascending: true)
          .order('created_at', ascending: false);
      var list = (rows as List).map(_fromRow).toList();
      // filter published or approved
      list = list.where((a) => a.status == 'approved' || a.status == null || a.status == 'published').toList();
      // also accept published=true rows even if status pending legacy
      if (category != null && category != 'all') {
        list = list.where((a) => a.category == category).toList();
      }
      return list;
    } catch (e) {
      try {
        final rows = await _client.from('apps').select().eq('published', true);
        return (rows as List).map(_fromRow).toList();
      } catch (_) {
        return [];
      }
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
          .or('name.ilike.%$q%,developer.ilike.%$q%,description.ilike.%$q%,package_name.ilike.%$q%');
      return (rows as List).map(_fromRow).toList();
    } catch (_) {
      return [];
    }
  }

  AppModel _fromRow(dynamic row) {
    final m = Map<String, dynamic>.from(row as Map);
    final id = m['id'];
    final name = m['name']?.toString() ?? 'App';
    final downloadUrl = m['download_url']?.toString() ?? '';
    final size = m['size_label']?.toString() ?? m['size']?.toString() ?? '';
    final role = m['submitter_role']?.toString() ?? 'user';
    final published = m['published'] == true;
    final status = m['status']?.toString() ?? (published ? 'approved' : 'pending');
    return AppModel(
      id: 'catalog_$id',
      name: name,
      developer: m['developer']?.toString() ?? 'AnNexus',
      description: m['description']?.toString() ?? '',
      iconUrl: m['icon_url']?.toString() ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=1565C0&color=fff',
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
      submitterRole: role,
      submitterUsername: m['submitter_username']?.toString(),
      catalogId: id is int ? id : int.tryParse('$id'),
      status: status,
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
