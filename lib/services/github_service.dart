import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_model.dart';

class GithubService {
  static const String _baseUrl = 'https://api.github.com';
  // No token needed for public search (rate limited)

  Future<List<AppModel>> searchApps(String query, {String? category}) async {
    try {
      String q = query.isEmpty ? 'android app OR flutter app stars:>50' : '$query android OR flutter OR apk';
      if (category == 'game') {
        q = query.isEmpty ? 'android game OR flutter game stars:>20' : '$query game';
      }
      final uri = Uri.parse('$_baseUrl/search/repositories').replace(queryParameters: {
        'q': q,
        'sort': 'stars',
        'order': 'desc',
        'per_page': '30',
      });
      final response = await http.get(uri, headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'AppStore-Flutter',
      });
      if (response.statusCode != 200) {
        return _getSampleApps(category);
      }
      final data = json.decode(response.body);
      final items = data['items'] as List? ?? [];
      final List<AppModel> apps = [];
      for (var item in items.take(20)) {
        // Optionally fetch latest release
        Map<String, dynamic>? release;
        try {
          final relUri = Uri.parse('$_baseUrl/repos/${item['full_name']}/releases/latest');
          final relRes = await http.get(relUri, headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'AppStore-Flutter',
          });
          if (relRes.statusCode == 200) {
            release = json.decode(relRes.body);
          }
        } catch (_) {}
        apps.add(AppModel.fromGithubRelease(item, release));
      }
      return apps;
    } catch (e) {
      return _getSampleApps(category);
    }
  }

  Future<List<AppModel>> getFeaturedApps() async {
    return searchApps('', category: null);
  }

  Future<List<AppModel>> getGames() async {
    return searchApps('', category: 'game');
  }

  List<AppModel> _getSampleApps(String? category) {
    final samples = [
      AppModel(
        id: '1',
        name: 'Termux',
        developer: 'termux',
        description: 'Terminal emulator and Linux environment for Android.',
        iconUrl: 'https://github.com/termux.png',
        rating: 4.8,
        downloads: 10000000,
        category: 'app',
        version: '0.118.0',
        size: '45 MB',
        downloadUrl: 'https://github.com/termux/termux-app/releases/latest',
        githubUrl: 'https://github.com/termux/termux-app',
      ),
      AppModel(
        id: '2',
        name: 'NewPipe',
        developer: 'TeamNewPipe',
        description: 'A free lightweight YouTube frontend for Android.',
        iconUrl: 'https://github.com/TeamNewPipe.png',
        rating: 4.7,
        downloads: 5000000,
        category: 'app',
        version: '0.27.0',
        size: '12 MB',
        downloadUrl: 'https://github.com/TeamNewPipe/NewPipe/releases/latest',
        githubUrl: 'https://github.com/TeamNewPipe/NewPipe',
      ),
      AppModel(
        id: '3',
        name: 'VLC',
        developer: 'videolan',
        description: 'Free and open source cross-platform multimedia player.',
        iconUrl: 'https://github.com/videolan.png',
        rating: 4.6,
        downloads: 20000000,
        category: 'app',
        version: '3.5.4',
        size: '35 MB',
        downloadUrl: 'https://github.com/videolan/vlc-android/releases',
        githubUrl: 'https://github.com/videolan/vlc-android',
      ),
      AppModel(
        id: '4',
        name: 'Signal',
        developer: 'signalapp',
        description: 'A private messenger for Android.',
        iconUrl: 'https://github.com/signalapp.png',
        rating: 4.5,
        downloads: 15000000,
        category: 'app',
        version: '7.0.0',
        size: '60 MB',
        downloadUrl: 'https://github.com/signalapp/Signal-Android/releases',
        githubUrl: 'https://github.com/signalapp/Signal-Android',
      ),
      AppModel(
        id: '5',
        name: '2048',
        developer: 'gabrielecirulli',
        description: 'Classic 2048 puzzle game.',
        iconUrl: 'https://github.com/gabrielecirulli.png',
        rating: 4.4,
        downloads: 2000000,
        category: 'game',
        version: '1.0',
        size: '2 MB',
        downloadUrl: 'https://github.com/gabrielecirulli/2048',
        githubUrl: 'https://github.com/gabrielecirulli/2048',
      ),
      AppModel(
        id: '6',
        name: 'Flappy Bird Clone',
        developer: 'sample',
        description: 'A simple Flappy Bird clone made with Flutter.',
        iconUrl: 'https://avatars.githubusercontent.com/u/1?v=4',
        rating: 4.2,
        downloads: 50000,
        category: 'game',
        version: '1.2.0',
        size: '8 MB',
        downloadUrl: 'https://github.com',
        githubUrl: 'https://github.com',
      ),
      AppModel(
        id: '7',
        name: 'OpenBoard',
        developer: 'openboard-team',
        description: '100% FOSS keyboard, based on AOSP.',
        iconUrl: 'https://github.com/openboard-team.png',
        rating: 4.3,
        downloads: 500000,
        category: 'app',
        version: '1.4.5',
        size: '5 MB',
        downloadUrl: 'https://github.com/openboard-team/openboard/releases',
        githubUrl: 'https://github.com/openboard-team/openboard',
      ),
      AppModel(
        id: '8',
        name: 'RetroArch',
        developer: 'libretro',
        description: 'Cross-platform, sophisticated frontend for the libretro API.',
        iconUrl: 'https://github.com/libretro.png',
        rating: 4.6,
        downloads: 3000000,
        category: 'game',
        version: '1.19.0',
        size: '80 MB',
        downloadUrl: 'https://github.com/libretro/RetroArch/releases',
        githubUrl: 'https://github.com/libretro/RetroArch',
      ),
    ];
    if (category == 'game') {
      return samples.where((a) => a.category == 'game').toList();
    } else if (category == 'app') {
      return samples.where((a) => a.category == 'app').toList();
    }
    return samples;
  }
}
