import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_model.dart';
import 'catalog_service.dart';

/// 多源 APK 聚合：信任库(Supabase) + F-Droid + GitHub(APK)
class ApkSourceService {
  static const _ua = 'AnNexus/1.0 (Android; APK-Store)';
  final CatalogService _catalog = CatalogService();

  /// source: all | catalog | fdroid | github
  Future<List<AppModel>> search(String query, {String source = 'all'}) async {
    final results = <AppModel>[];
    final q = query.trim();

    if (source == 'all' || source == 'catalog') {
      try {
        results.addAll(await _catalog.search(q));
      } catch (_) {}
    }
    if (source == 'all' || source == 'fdroid') {
      try {
        results.addAll(await _searchFdroid(q));
      } catch (_) {}
    }
    if (source == 'all' || source == 'github') {
      try {
        results.addAll(await _searchGithubApk(q));
      } catch (_) {}
    }

    final seen = <String>{};
    final unique = <AppModel>[];
    for (final a in results) {
      final key = '${a.name.toLowerCase()}|${a.packageName ?? a.developer}'.toLowerCase();
      if (seen.add(key)) unique.add(a);
    }
    return unique;
  }

  Future<List<AppModel>> featured({String source = 'all'}) async {
    final results = <AppModel>[];
    if (source == 'all' || source == 'catalog') {
      try {
        results.addAll(await _catalog.fetchAll());
      } catch (_) {}
    }
    if (source == 'all' || source == 'fdroid') {
      try {
        results.addAll(await _fdroidFeatured());
      } catch (_) {}
    }
    if (source == 'all' || source == 'github') {
      try {
        results.addAll(await _searchGithubApk('android apk'));
      } catch (_) {}
    }
    if (results.isEmpty) return _fallbackSamples();
    return results;
  }

  Future<List<AppModel>> games({String source = 'all'}) async {
    final results = <AppModel>[];
    if (source == 'all' || source == 'catalog') {
      try {
        results.addAll(await _catalog.fetchAll(category: 'game'));
      } catch (_) {}
    }
    if (source == 'all' || source == 'fdroid') {
      try {
        final all = await _fdroidFeatured();
        results.addAll(all.where((a) => a.category == 'game'));
      } catch (_) {}
    }
    if (source == 'all' || source == 'github') {
      try {
        results.addAll(await _searchGithubApk('android game apk'));
      } catch (_) {}
    }
    return results;
  }

  static const _fdroidPopular = [
    'org.fdroid.fdroid',
    'com.termux',
    'org.schabi.newpipe',
    'org.videolan.vlc',
    'com.simplemobiletools.gallery.pro',
    'com.nextcloud.client',
    'com.fsck.k9',
    'com.amaze.filemanager',
    'org.kde.kdeconnect_tp',
    'com.kunzisoft.keepass.libre',
    'org.tasks',
    'com.looker.droidify',
    'org.fossify.gallery',
    'im.vector.app',
    'chat.simplex.app',
    'org.jellyfin.mobile',
    'net.osmand.plus',
    'com.aurora.store',
  ];

  Future<List<AppModel>> _fdroidFeatured() async {
    final list = <AppModel>[];
    final results = await Future.wait(_fdroidPopular.take(18).map(_fdroidPackage));
    for (final a in results) {
      if (a != null) list.add(a);
    }
    return list;
  }

  Future<List<AppModel>> _searchFdroid(String query) async {
    if (query.isEmpty) return _fdroidFeatured();
    final list = <AppModel>[];
    final q = query.toLowerCase();
    for (final pkg in _fdroidPopular) {
      if (pkg.toLowerCase().contains(q)) {
        final a = await _fdroidPackage(pkg);
        if (a != null) list.add(a);
      }
    }
    if (query.contains('.')) {
      final a = await _fdroidPackage(query);
      if (a != null) list.add(a);
    }
    return list;
  }

  Future<AppModel?> _fdroidPackage(String packageName) async {
    try {
      final uri = Uri.parse('https://f-droid.org/api/v1/packages/$packageName');
      final res = await http.get(uri, headers: {'User-Agent': _ua, 'Accept': 'application/json'});
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as Map<String, dynamic>;
      final pkg = data['packageName']?.toString() ?? packageName;
      final suggested = data['suggestedVersionCode'];
      final packages = data['packages'] as List? ?? [];
      if (packages.isEmpty) return null;

      Map<String, dynamic>? best;
      for (final p in packages) {
        if (p is Map<String, dynamic> && p['versionCode'] == suggested) {
          best = p;
          break;
        }
      }
      best ??= packages.first as Map<String, dynamic>;

      final version = best['versionName']?.toString() ?? '1.0';
      final versionCode = best['versionCode']?.toString() ?? '';
      final apkUrl = 'https://f-droid.org/repo/${pkg}_$versionCode.apk';
      final sizeBytes = best['size'] as int? ?? 0;
      final size = _fmtSize(sizeBytes);
      var name = pkg.split('.').last.replaceAll('_', ' ');
      if (name.isNotEmpty) name = '${name[0].toUpperCase()}${name.substring(1)}';

      return AppModel(
        id: 'fdroid_$pkg',
        name: name,
        developer: 'F-Droid',
        description: 'F-Droid 开源应用 · $pkg',
        iconUrl: 'https://f-droid.org/repo/icons-640/$pkg.png',
        rating: 4.5,
        downloads: 10000,
        category: 'app',
        version: version,
        size: size,
        downloadUrl: apkUrl,
        githubUrl: 'https://f-droid.org/packages/$pkg/',
        fileType: 'apk',
        packageName: pkg,
        source: 'fdroid',
        assets: [
          {'name': '$pkg-$version.apk', 'url': apkUrl, 'size': size, 'fileType': 'apk'},
        ],
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<AppModel>> _searchGithubApk(String query) async {
    final q = query.isEmpty
        ? 'android apk extension:apk stars:>20'
        : '$query android apk';
    final uri = Uri.parse('https://api.github.com/search/repositories').replace(
      queryParameters: {'q': q, 'sort': 'stars', 'order': 'desc', 'per_page': '15'},
    );
    final res = await http.get(uri, headers: {
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': _ua,
    });
    if (res.statusCode != 200) return [];
    final data = json.decode(res.body);
    final items = data['items'] as List? ?? [];
    final list = <AppModel>[];

    for (final item in items.take(10)) {
      Map<String, dynamic>? release;
      try {
        final relUri =
            Uri.parse('https://api.github.com/repos/${item['full_name']}/releases/latest');
        final relRes = await http.get(relUri, headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': _ua,
        });
        if (relRes.statusCode == 200) {
          release = json.decode(relRes.body) as Map<String, dynamic>;
        }
      } catch (_) {}

      final app = AppModel.fromGithubRelease(item as Map<String, dynamic>, release);
      final apkAssets = app.assets.where((a) => a['fileType'] == 'apk').toList();
      if (apkAssets.isEmpty && app.fileType != 'apk') continue;

      list.add(AppModel(
        id: 'gh_${app.id}',
        name: app.name,
        developer: app.developer,
        description: app.description,
        iconUrl: app.iconUrl,
        rating: app.rating,
        downloads: app.downloads,
        category: app.category == 'game' ? 'game' : 'app',
        version: app.version,
        size: apkAssets.isNotEmpty ? apkAssets.first['size']?.toString() ?? app.size : app.size,
        downloadUrl: apkAssets.isNotEmpty
            ? apkAssets.first['url']?.toString() ?? app.downloadUrl
            : app.downloadUrl,
        githubUrl: app.githubUrl,
        language: app.language,
        fileType: 'apk',
        assets: apkAssets.isNotEmpty ? apkAssets : app.assets,
        source: 'github',
      ));
    }
    return list;
  }

  static String _fmtSize(int bytes) {
    if (bytes <= 0) return '未知';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  List<AppModel> _fallbackSamples() {
    return [
      AppModel(
        id: 'sample_newpipe',
        name: 'NewPipe',
        developer: 'TeamNewPipe',
        description: '轻量级 YouTube 前端（开源）',
        iconUrl: 'https://f-droid.org/repo/icons-640/org.schabi.newpipe.png',
        category: 'app',
        version: '0.27.0',
        size: '12 MB',
        downloadUrl: 'https://f-droid.org/packages/org.schabi.newpipe/',
        fileType: 'apk',
        source: 'fdroid',
        packageName: 'org.schabi.newpipe',
      ),
    ];
  }
}
