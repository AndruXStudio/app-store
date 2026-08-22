import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_model.dart';

/// 多源 APK 聚合：只返回带 APK 下载的应用
class ApkSourceService {
  static const _ua = 'AnNexus/1.0 (Android; APK-Store)';

  /// source: all | fdroid | github
  Future<List<AppModel>> search(String query, {String source = 'all'}) async {
    final results = <AppModel>[];
    final q = query.trim();

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

    // 去重（按名称+开发者）
    final seen = <String>{};
    final unique = <AppModel>[];
    for (final a in results) {
      final key = '${a.name.toLowerCase()}|${a.developer.toLowerCase()}';
      if (seen.add(key)) unique.add(a);
    }
    return unique;
  }

  Future<List<AppModel>> featured({String source = 'all'}) async {
    final results = <AppModel>[];
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
    if (results.isEmpty) {
      return _fallbackSamples().where((a) => a.category == 'game').toList();
    }
    return results;
  }

  // ---------- F-Droid ----------
  // 使用公开包信息 API + 一批热门包名（稳定、免魔法）
  static const _fdroidPopular = [
    'org.fdroid.fdroid',
    'com.termux',
    'org.mozilla.fennec_fdroid',
    'com.simplemobiletools.gallery.pro',
    'org.thoughtcrime.securesms',
    'com.nextcloud.client',
    'org.videolan.vlc',
    'net.osmand.plus',
    'com.fsck.k9',
    'org.telegram.messenger',
    'com.aurora.store',
    'org.schabi.newpipe',
    'com.amaze.filemanager',
    'org.kde.kdeconnect_tp',
    'com.simplemobiletools.calendar.pro',
    'org.documentfoundation.libreoffice',
    'com.kunzisoft.keepass.libre',
    'org.billthefarmer.editor',
    'com.iven.itsmusic',
    'org.tasks',
    'com.github.axet.audiorecorder',
    'nya.kitsunyan.foxydroid',
    'com.looker.droidify',
    'org.fossify.gallery',
    'org.fossify.messages',
    'com.limelight',
    'com.pciedric.jellyfin',
    'org.jellyfin.mobile',
    'chat.simplex.app',
    'im.vector.app',
  ];

  Future<List<AppModel>> _fdroidFeatured() async {
    final list = <AppModel>[];
    // 并行拉取一部分
    final packages = _fdroidPopular.take(24).toList();
    final futures = packages.map(_fdroidPackage);
    final results = await Future.wait(futures);
    for (final a in results) {
      if (a != null) list.add(a);
    }
    return list;
  }

  Future<List<AppModel>> _searchFdroid(String query) async {
    if (query.isEmpty) return _fdroidFeatured();
    final list = <AppModel>[];
    final q = query.toLowerCase();
    // 先在热门里滤
    for (final pkg in _fdroidPopular) {
      if (pkg.toLowerCase().contains(q)) {
        final a = await _fdroidPackage(pkg);
        if (a != null) list.add(a);
      }
    }
    // 再尝试把 query 当 package name
    if (query.contains('.')) {
      final a = await _fdroidPackage(query);
      if (a != null) list.add(a);
    }
    // F-Droid 网站搜索页无稳定 JSON，补充 GitHub 结果由上层合并
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
      // F-Droid 直链
      final apkUrl = 'https://f-droid.org/repo/${pkg}_$versionCode.apk';
      // 部分用不同命名，备选
      final apkUrlAlt = 'https://f-droid.org/repo/$pkg-$version.apk';

      final sizeBytes = best['size'] as int? ?? 0;
      final size = _fmtSize(sizeBytes);

      // 详情页补全名称（API 较简）
      String name = pkg.split('.').last;
      String desc = 'F-Droid 开源应用';
      String icon = 'https://f-droid.org/repo/icons-640/$pkg.png';
      try {
        final page = await http.get(
          Uri.parse('https://f-droid.org/api/v1/packages/$pkg'),
          headers: {'User-Agent': _ua},
        );
        // 使用 package 名美化
        name = pkg.replaceAll(RegExp(r'.*\.'), '').replaceAll('_', ' ');
        name = name.isEmpty ? pkg : '${name[0].toUpperCase()}${name.substring(1)}';
      } catch (_) {}

      return AppModel(
        id: 'fdroid_$pkg',
        name: name,
        developer: 'F-Droid',
        description: desc,
        iconUrl: icon,
        rating: 4.5,
        downloads: 10000,
        category: 'app',
        version: version,
        size: size,
        downloadUrl: apkUrl,
        githubUrl: 'https://f-droid.org/packages/$pkg/',
        language: null,
        fileType: 'apk',
        packageName: pkg,
        assets: [
          {
            'name': '$pkg-$version.apk',
            'url': apkUrl,
            'size': size,
            'fileType': 'apk',
          },
          {
            'name': '$pkg-$version-alt.apk',
            'url': apkUrlAlt,
            'size': size,
            'fileType': 'apk',
          },
        ],
        source: 'fdroid',
      );
    } catch (_) {
      return null;
    }
  }

  // ---------- GitHub（仅 APK）----------
  Future<List<AppModel>> _searchGithubApk(String query) async {
    final q = query.isEmpty
        ? 'android apk extension:apk stars:>20'
        : '$query android apk';
    final uri = Uri.parse('https://api.github.com/search/repositories').replace(
      queryParameters: {
        'q': q,
        'sort': 'stars',
        'order': 'desc',
        'per_page': '20',
      },
    );
    final res = await http.get(uri, headers: {
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': _ua,
    });
    if (res.statusCode != 200) return [];
    final data = json.decode(res.body);
    final items = data['items'] as List? ?? [];
    final list = <AppModel>[];

    for (final item in items.take(12)) {
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
      // 只保留有 APK 的
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
        packageName: app.packageName,
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
      AppModel(
        id: 'sample_termux',
        name: 'Termux',
        developer: 'termux',
        description: 'Android 终端与 Linux 环境',
        iconUrl: 'https://f-droid.org/repo/icons-640/com.termux.png',
        category: 'app',
        version: '0.118.0',
        size: '45 MB',
        downloadUrl: 'https://f-droid.org/packages/com.termux/',
        fileType: 'apk',
        source: 'fdroid',
        packageName: 'com.termux',
      ),
    ];
  }
}
