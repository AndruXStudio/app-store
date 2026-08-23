class AppModel {
  final String id;
  final String name;
  final String developer;
  final String description;
  final String iconUrl;
  final String? bannerUrl;
  final double rating;
  final int downloads;
  final String category; // app | game | archive | other
  final String version;
  final String size;
  final String downloadUrl;
  final String? githubUrl;
  final List<String> screenshots;
  final String? packageName;
  final String? language; // 主要编程语言
  final String? fileType; // apk | zip | aab | tar | rar | 7z | ipa | other
  final List<Map<String, dynamic>> assets;
  final String? source;
  final String? submitterRole;
  final String? submitterUsername;
  final int? catalogId;
  final String? status;
  final String? changelog;

  AppModel({
    required this.id,
    required this.name,
    required this.developer,
    required this.description,
    required this.iconUrl,
    this.bannerUrl,
    this.rating = 4.5,
    this.downloads = 1000,
    required this.category,
    this.version = '1.0.0',
    this.size = '10 MB',
    required this.downloadUrl,
    this.githubUrl,
    this.screenshots = const [],
    this.packageName,
    this.language,
    this.fileType,
    this.assets = const [],
    this.source,
    this.submitterRole,
    this.submitterUsername,
    this.catalogId,
    this.status,
    this.changelog,
  });

  factory AppModel.fromGithubRelease(Map<String, dynamic> repo, Map<String, dynamic>? release) {
    final owner = repo['owner']?['login'] ?? 'Unknown';
    final name = repo['name'] ?? 'Unknown';
    final description = repo['description'] ?? 'No description';
    final htmlUrl = repo['html_url'] ?? '';
    final language = repo['language']?.toString();

    String downloadUrl = '';
    String size = 'Unknown';
    String version = '1.0.0';
    String? fileType;
    final List<Map<String, dynamic>> assetsList = [];

    if (release != null) {
      version = release['tag_name'] ?? '1.0.0';
      final assets = release['assets'] as List? ?? [];
      for (var asset in assets) {
        final assetName = (asset['name'] as String? ?? '');
        final lower = assetName.toLowerCase();
        final url = asset['browser_download_url']?.toString() ?? '';
        final sizeBytes = asset['size'] as int? ?? 0;
        final ft = _detectFileType(lower);
        assetsList.add({
          'name': assetName,
          'url': url,
          'size': _formatSize(sizeBytes),
          'sizeBytes': sizeBytes,
          'fileType': ft,
        });
        // 优先选可安装/常用包作为主下载
        if (downloadUrl.isEmpty &&
            (lower.endsWith('.apk') ||
                lower.endsWith('.zip') ||
                lower.endsWith('.aab') ||
                lower.endsWith('.ipa') ||
                lower.endsWith('.tar.gz') ||
                lower.endsWith('.tgz') ||
                lower.endsWith('.7z') ||
                lower.endsWith('.rar') ||
                lower.endsWith('.exe') ||
                lower.endsWith('.dmg') ||
                lower.endsWith('.AppImage') ||
                lower.endsWith('.deb'))) {
          downloadUrl = url;
          size = _formatSize(sizeBytes);
          fileType = ft;
        }
      }
      // 若没匹配到，取第一个 asset
      if (downloadUrl.isEmpty && assetsList.isNotEmpty) {
        downloadUrl = assetsList.first['url']?.toString() ?? '';
        size = assetsList.first['size']?.toString() ?? 'Unknown';
        fileType = assetsList.first['fileType']?.toString();
      }
    }

    return AppModel(
      id: repo['id'].toString(),
      name: name,
      developer: owner,
      description: description,
      iconUrl: repo['owner']?['avatar_url'] ?? 'https://github.com/identicons/$owner.png',
      rating: 4.0 + (repo['stargazers_count'] as int? ?? 0) % 10 / 10,
      downloads: repo['stargazers_count'] as int? ?? 0,
      category: _guessCategory(name, description, fileType, language),
      version: version,
      size: size,
      downloadUrl: downloadUrl.isNotEmpty ? downloadUrl : htmlUrl,
      githubUrl: htmlUrl,
      language: language,
      fileType: fileType,
      assets: assetsList,
      source: 'github',
    );
  }

  static String _detectFileType(String lowerName) {
    if (lowerName.endsWith('.apk') || lowerName.endsWith('.aab')) return 'apk';
    if (lowerName.endsWith('.ipa')) return 'ipa';
    if (lowerName.endsWith('.zip') ||
        lowerName.endsWith('.rar') ||
        lowerName.endsWith('.7z') ||
        lowerName.endsWith('.tar') ||
        lowerName.endsWith('.tar.gz') ||
        lowerName.endsWith('.tgz') ||
        lowerName.endsWith('.gz') ||
        lowerName.endsWith('.bz2') ||
        lowerName.endsWith('.xz')) {
      return 'archive';
    }
    if (lowerName.endsWith('.exe') || lowerName.endsWith('.msi')) return 'windows';
    if (lowerName.endsWith('.dmg') || lowerName.endsWith('.pkg')) return 'macos';
    if (lowerName.endsWith('.deb') ||
        lowerName.endsWith('.rpm') ||
        lowerName.endsWith('.appimage')) {
      return 'linux';
    }
    if (lowerName.endsWith('.jar')) return 'java';
    return 'other';
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String _guessCategory(String name, String desc, String? fileType, String? language) {
    final lower = (name + desc).toLowerCase();
    if (fileType == 'archive') return 'archive';
    if (lower.contains('game') ||
        lower.contains('puzzle') ||
        lower.contains('rpg') ||
        lower.contains('arcade') ||
        lower.contains('adventure')) {
      return 'game';
    }
    if (fileType == 'apk' || fileType == 'ipa') return 'app';
    return 'app';
  }

  String get categoryLabel {
    switch (category) {
      case 'game':
        return '游戏';
      case 'archive':
        return '压缩包';
      case 'other':
        return '其他';
      default:
        return '应用';
    }
  }

  String get fileTypeLabel {
    switch (fileType) {
      case 'apk':
        return 'Android 应用';
      case 'ipa':
        return 'iOS 应用';
      case 'archive':
        return '压缩包';
      case 'windows':
        return 'Windows';
      case 'macos':
        return 'macOS';
      case 'linux':
        return 'Linux';
      case 'java':
        return 'Java';
      default:
        return fileType ?? '文件';
    }
  }
}
