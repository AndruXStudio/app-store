import 'package:flutter/foundation.dart';
import '../models/app_model.dart';
import '../services/catalog_service.dart';

class AppProvider extends ChangeNotifier {
  final CatalogService _catalog = CatalogService();

  List<AppModel> _apps = [];
  List<AppModel> _games = [];
  List<AppModel> _featured = [];
  List<AppModel> _searchResults = [];
  String _searchQuery = '';

  bool loadingApps = false;
  bool loadingGames = false;
  bool loadingHome = false;
  bool loadingFeatured = false;
  bool loadingSearch = false;
  String? error;

  List<AppModel> get apps => _apps;
  List<AppModel> get games => _games;
  List<AppModel> get featured => _featured;
  List<AppModel> get searchResults => _searchResults;
  String get searchQuery => _searchQuery;

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
    loadingFeatured = true;
    notifyListeners();
    try {
      final all = await _catalog.fetchPublished();
      _featured = all;
      _apps = all.where((a) => a.category == 'app').toList();
      _games = all.where((a) => a.category == 'game').toList();
    } catch (e) {
      error = e.toString();
    }
    loadingHome = false;
    loadingFeatured = false;
    notifyListeners();
  }

  Future<void> search(String query) async {
    _searchQuery = query.trim();
    if (_searchQuery.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    loadingSearch = true;
    notifyListeners();
    try {
      _searchResults = await _catalog.search(_searchQuery);
    } catch (e) {
      error = e.toString();
      _searchResults = [];
    }
    loadingSearch = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    loadingSearch = false;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await Future.wait([loadApps(), loadGames(), loadHome()]);
  }
}
