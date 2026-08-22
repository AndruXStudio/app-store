import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_model.dart';

class LocalDataService {
  static const _favKey = 'annexus_favorites';
  static const _histKey = 'annexus_history';
  static const _settingsKey = 'annexus_settings';

  Future<List<Map<String, dynamic>>> _getList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> _setList(String key, List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(list));
  }

  Map<String, dynamic> _appToMap(AppModel app) => {
        'id': app.id,
        'name': app.name,
        'developer': app.developer,
        'description': app.description,
        'iconUrl': app.iconUrl,
        'rating': app.rating,
        'downloads': app.downloads,
        'category': app.category,
        'version': app.version,
        'size': app.size,
        'downloadUrl': app.downloadUrl,
        'githubUrl': app.githubUrl,
        'language': app.language,
        'fileType': app.fileType,
      };

  AppModel _mapToApp(Map<String, dynamic> m) => AppModel(
        id: m['id']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        developer: m['developer']?.toString() ?? '',
        description: m['description']?.toString() ?? '',
        iconUrl: m['iconUrl']?.toString() ?? '',
        rating: (m['rating'] as num?)?.toDouble() ?? 4.0,
        downloads: (m['downloads'] as num?)?.toInt() ?? 0,
        category: m['category']?.toString() ?? 'app',
        version: m['version']?.toString() ?? '1.0',
        size: m['size']?.toString() ?? '',
        downloadUrl: m['downloadUrl']?.toString() ?? '',
        githubUrl: m['githubUrl']?.toString(),
        language: m['language']?.toString(),
        fileType: m['fileType']?.toString(),
      );

  Future<List<AppModel>> getFavorites() async {
    final list = await _getList(_favKey);
    return list.map(_mapToApp).toList();
  }

  Future<bool> isFavorite(String id) async {
    final list = await _getList(_favKey);
    return list.any((e) => e['id'] == id);
  }

  Future<void> toggleFavorite(AppModel app) async {
    final list = await _getList(_favKey);
    final idx = list.indexWhere((e) => e['id'] == app.id);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.insert(0, _appToMap(app));
    }
    await _setList(_favKey, list);
  }

  Future<List<AppModel>> getHistory() async {
    final list = await _getList(_histKey);
    return list.map(_mapToApp).toList();
  }

  Future<void> addHistory(AppModel app) async {
    final list = await _getList(_histKey);
    list.removeWhere((e) => e['id'] == app.id);
    list.insert(0, _appToMap(app));
    if (list.length > 50) list.removeRange(50, list.length);
    await _setList(_histKey, list);
  }

  Future<void> clearHistory() async {
    await _setList(_histKey, []);
  }

  Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null) {
      return {
        'darkMode': 'system', // system / light / dark
        'wifiOnlyDownload': false,
        'showPreRelease': true,
        'language': 'zh',
      };
    }
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings));
  }
}
