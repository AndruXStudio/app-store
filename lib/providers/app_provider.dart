import 'package:flutter/foundation.dart';
import '../models/app_model.dart';
import '../services/catalog_service.dart';

class AppProvider extends ChangeNotifier {
  final CatalogService _catalog = CatalogService();

  List<AppModel> _apps = [];
  List<AppModel> _games = [];
  List<AppModel> _featured = [];
  bool loadingApps = false;
  bool loadingGames = false;
  bool loadingHome = false;
  String? error;

  List<AppModel> get apps => _apps;
  List<AppModel> get games => _games;
  List<AppModel> get featured => _featured;

  Future<void> loadApps() async {
    loadingApps = true;
    error = null;
    notifyListeners();
    try {
      _apps = await _catalog.fetchPublished(category: 'app');
    } catch (e) {
      error = e.toString();
      _apps = [];
    }
    loadingApps = false;
    notifyListeners();
  }

  Future<void> loadGames() async {
    loadingGames = true;
    error = null;
    notifyListeners();
    try {
      _games = await _catalog.fetchPublished(category: 'game');
    } catch (e) {
      error = e.toString();
      _games = [];
    }
    loadingGames = false;
    notifyListeners();
  }

  Future<void> loadFeatured() async => loadHome();

  Future<void> loadHome() async {
    loadingHome = true;
    notifyListeners();
    try {
      final all = await _catalog.fetchPublished();
      _featured = all.take(8).toList();
      _apps = all.where((a) => a.category == 'app').toList();
      _games = all.where((a) => a.category == 'game').toList();
    } catch (e) {
      error = e.toString();
    }
    loadingHome = false;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await Future.wait([loadApps(), loadGames(), loadHome()]);
  }
}
