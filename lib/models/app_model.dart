class AppModel {
  final String id;
  final String name;
  final String developer;
  final String description;
  final String iconUrl;
  final String? bannerUrl;
  final double rating;
  final int downloads;
  final String category; // 'app' or 'game'
  final String version;
  final String size;
  final String downloadUrl;
  final String? githubUrl;
  final List<String> screenshots;
  final String? packageName;

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
  });

  factory AppModel.fromGithubRelease(Map<String, dynamic> repo, Map<String, dynamic>? release) {
    final owner = repo['owner']?['login'] ?? 'Unknown';
    final name = repo['name'] ?? 'Unknown';
    final description = repo['description'] ?? 'No description';
    final htmlUrl = repo['html_url'] ?? '';
    String downloadUrl = '';
    String size = 'Unknown';
    String version = '1.0.0';
    if (release != null) {
      version = release['tag_name'] ?? '1.0.0';
      final assets = release['assets'] as List? ?? [];
      for (var asset in assets) {
        final assetName = (asset['name'] as String? ?? '').toLowerCase();
        if (assetName.endsWith('.apk') ||
            assetName.endsWith('.zip') ||
            assetName.endsWith('.aab') ||
            assetName.endsWith('.ipa')) {
          downloadUrl = asset['browser_download_url'] ?? '';
          final sizeBytes = asset['size'] as int? ?? 0;
          size = _formatSize(sizeBytes);
          break;
        }
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
      category: _guessCategory(name, description),
      version: version,
      size: size,
      downloadUrl: downloadUrl.isNotEmpty ? downloadUrl : htmlUrl,
      githubUrl: htmlUrl,
      screenshots: [],
    );
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String _guessCategory(String name, String desc) {
    final lower = (name + desc).toLowerCase();
    if (lower.contains('game') ||
        lower.contains('puzzle') ||
        lower.contains('rpg') ||
        lower.contains('arcade') ||
        lower.contains('adventure')) {
      return 'game';
    }
    return 'app';
  }
}
