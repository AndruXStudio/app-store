import '../models/app_model.dart';
import 'catalog_service.dart';

/// 仅用户信任库（Supabase），无开源第三方源
class ApkSourceService {
  final CatalogService _catalog = CatalogService();

  Future<List<AppModel>> search(String query, {String source = 'all'}) async {
    return _catalog.search(query);
  }

  Future<List<AppModel>> featured({String source = 'all'}) async {
    final list = await _catalog.fetchAll();
    return list;
  }

  Future<List<AppModel>> games({String source = 'all'}) async {
    return _catalog.fetchAll(category: 'game');
  }
}
