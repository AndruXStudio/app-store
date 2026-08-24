import '../models/app_model.dart';
import 'catalog_service.dart';

class ApkSourceService {
  final CatalogService _catalog = CatalogService();

  Future<List<AppModel>> search(String query, {String source = 'all'}) async {
    return _catalog.search(query);
  }

  Future<List<AppModel>> featured({String source = 'all'}) async {
    return _catalog.fetchPublished();
  }

  Future<List<AppModel>> appsOnly() async {
    return _catalog.fetchPublished(category: 'app');
  }

  Future<List<AppModel>> games({String source = 'all'}) async {
    return _catalog.fetchPublished(category: 'game');
  }
}
