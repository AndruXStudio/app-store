import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';

enum DownloadStatus { queued, downloading, completed, failed, paused }

class DownloadTask {
  final String id;
  final String name;
  final String url;
  final String? iconUrl;
  double progress;
  DownloadStatus status;
  String? localPath;
  String? error;
  CancelToken? cancelToken;

  DownloadTask({
    required this.id,
    required this.name,
    required this.url,
    this.iconUrl,
    this.progress = 0.0,
    this.status = DownloadStatus.queued,
    this.localPath,
    this.error,
    this.cancelToken,
  });
}

class DownloadService extends ChangeNotifier {
  final Dio _dio = Dio();
  final List<DownloadTask> _tasks = [];

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);
  List<DownloadTask> get activeTasks => _tasks
      .where((t) => t.status == DownloadStatus.downloading || t.status == DownloadStatus.queued)
      .toList();
  List<DownloadTask> get completedTasks =>
      _tasks.where((t) => t.status == DownloadStatus.completed).toList();

  static String guessExtension(String url, String? name) {
    final path = Uri.parse(url).path.toLowerCase();
    final n = (name ?? '').toLowerCase();
    const exts = [
      '.apk', '.aab', '.ipa', '.zip', '.rar', '.7z', '.tar', '.tar.gz', '.tgz',
      '.gz', '.bz2', '.xz', '.exe', '.msi', '.dmg', '.pkg', '.deb', '.rpm',
      '.appimage', '.jar', '.bin', '.so', '.dll', '.txt', '.pdf', '.json',
    ];
    for (final e in exts) {
      if (path.endsWith(e) || n.endsWith(e)) return e;
    }
    // path segments
    final last = path.split('/').last;
    if (last.contains('.')) {
      final idx = last.lastIndexOf('.');
      if (idx > 0) return last.substring(idx);
    }
    return '.bin';
  }

  Future<void> startDownload({
    required String id,
    required String name,
    required String url,
    String? iconUrl,
  }) async {
    if (_tasks.any((t) => t.id == id && t.status == DownloadStatus.downloading)) {
      return;
    }

    final task = DownloadTask(
      id: id,
      name: name,
      url: url,
      iconUrl: iconUrl,
      status: DownloadStatus.downloading,
      cancelToken: CancelToken(),
    );
    _tasks.insert(0, task);
    notifyListeners();

    try {
      if (kIsWeb) {
        task.status = DownloadStatus.completed;
        task.progress = 1.0;
        notifyListeners();
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      await Directory('${dir.path}/downloads').create(recursive: true);
      final baseName = name.replaceAll(RegExp(r'[^\w\s\.\-]'), '_');
      final ext = guessExtension(url, name);
      final filePath = '${dir.path}/downloads/$baseName${baseName.toLowerCase().endsWith(ext) ? '' : ext}';

      await _dio.download(
        url,
        filePath,
        cancelToken: task.cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            task.progress = received / total;
            notifyListeners();
          }
        },
      );

      task.progress = 1.0;
      task.status = DownloadStatus.completed;
      task.localPath = filePath;
      notifyListeners();
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        task.status = DownloadStatus.paused;
      } else {
        task.status = DownloadStatus.failed;
        task.error = e.toString();
      }
      notifyListeners();
    }
  }

  void cancelDownload(String id) {
    final task = _tasks.cast<DownloadTask?>().firstWhere(
          (t) => t?.id == id,
          orElse: () => null,
        );
    if (task != null) {
      task.cancelToken?.cancel();
      task.status = DownloadStatus.paused;
      notifyListeners();
    }
  }

  Future<void> openFile(String path) async {
    if (!kIsWeb) {
      await OpenFilex.open(path);
    }
  }

  void removeTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void clearCompleted() {
    _tasks.removeWhere(
        (t) => t.status == DownloadStatus.completed || t.status == DownloadStatus.failed);
    notifyListeners();
  }
}
