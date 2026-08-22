import 'package:flutter/foundation.dart';
import '../models/app_model.dart';
import '../services/github_service.dart';

class AppProvider extends ChangeNotifier {
  final GithubService _github = GithubService();
  List<AppModel> _featured = [];
  List<AppModel> _apps = [];
  List<AppModel> _games = [];
  List<AppModel> _searchResults = [];
  bool _loadingFeatured = false;
  bool _loadingApps = false;
  bool _loadingGames = false;
  bool _loadingSearch = false;
  String _searchQuery = '';

  List<AppModel> get featured => _featured;
  List<AppModel> get apps => _apps;
  List<AppModel> get games => _games;
  List<AppModel> get searchResults => _searchResults;
  bool get loadingFeatured => _loadingFeatured;
  bool get loadingApps => _loadingApps;
  bool get loadingGames => _loadingGames;
  bool get loadingSearch => _loadingSearch;
  String get searchQuery => _searchQuery;

  Future<void> loadFeatured() async {
    if (_featured.isNotEmpty) return;
    _loadingFeatured = true;
    notifyListeners();
    _featured = await _github.getFeaturedApps();
    _loadingFeatured = false;
    notifyListeners();
  }

  Future<void> loadApps() async {
    if (_apps.isNotEmpty) return;
    _loadingApps = true;
    notifyListeners();
    _apps = await _github.searchApps('', category: 'app');
    _loadingApps = false;
    notifyListeners();
  }

  Future<void> loadGames() async {
    if (_games.isNotEmpty) return;
    _loadingGames = true;
    notifyListeners();
    _games = await _github.getGames();
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
    _searchResults = await _github.searchApps(query);
    _loadingSearch = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }
}
