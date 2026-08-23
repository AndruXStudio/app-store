import 'package:flutter/foundation.dart';
import '../models/app_model.dart';
import '../services/apk_source_service.dart';

class AppProvider extends ChangeNotifier {
  final ApkSourceService _api = ApkSourceService();

  List<AppModel> _featured = [];
  List<AppModel> _apps = [];
  List<AppModel> _games = [];
  List<AppModel> _searchResults = [];
  bool _loadingFeatured = false;
  bool _loadingApps = false;
  bool _loadingGames = false;
  bool _loadingSearch = false;
  String _searchQuery = '';
  String _source = 'catalog';

  List<AppModel> get featured => _featured;
  List<AppModel> get apps => _apps;
  List<AppModel> get games => _games;
  List<AppModel> get searchResults => _searchResults;
  bool get loadingFeatured => _loadingFeatured;
  bool get loadingApps => _loadingApps;
  bool get loadingGames => _loadingGames;
  bool get loadingSearch => _loadingSearch;
  String get searchQuery => _searchQuery;
  String get source => _source;

  Future<void> setSource(String source) async {
    _source = 'catalog';
    await refreshAll();
  }

  Future<void> loadFeatured() async {
    if (_featured.isNotEmpty) return;
    _loadingFeatured = true;
    notifyListeners();
    _featured = await _api.featured();
    _loadingFeatured = false;
    notifyListeners();
  }

  Future<void> loadApps() async {
    _loadingApps = true;
    notifyListeners();
    _apps = await _api.featured();
    _loadingApps = false;
    notifyListeners();
  }

  Future<void> loadGames() async {
    _loadingGames = true;
    notifyListeners();
    _games = await _api.games();
    _loadingGames = false;
    notifyListeners();
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _loadingSearch = true;
    notifyListeners();
    _searchResults = await _api.search(query);
    _loadingSearch = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  Future<void> refreshAll() async {
    _featured = [];
    _apps = [];
    _games = [];
    await Future.wait([loadFeatured(), loadApps(), loadGames()]);
  }
}
