import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_model.dart';
import '../services/download_service.dart';
import '../services/local_data_service.dart';

class AppDetailScreen extends StatefulWidget {
  final AppModel app;
  const AppDetailScreen({super.key, required this.app});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  final _local = LocalDataService();
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _local.addHistory(widget.app);
    _local.isFavorite(widget.app.id).then((v) {
      if (mounted) setState(() => _isFav = v);
    });
  }

  Future<void> _toggleFav() async {
    await _local.toggleFavorite(widget.app);
    final v = await _local.isFavorite(widget.app.id);
    if (mounted) {
      setState(() => _isFav = v);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(v ? '已加入收藏' : '已取消收藏')),
      );
    }
  }

  void _downloadAsset(DownloadService ds, Map<String, dynamic> asset) {
    final url = asset['url']?.toString() ?? '';
    final name = asset['name']?.toString() ?? widget.app.name;
    if (url.isEmpty) return;
    ds.startDownload(
      id: '${widget.app.id}_$name',
      name: name,
      url: url,
      iconUrl: widget.app.iconUrl,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('开始下载 $name')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final downloadService = context.watch<DownloadService>();
    final isDownloading = downloadService.tasks
        .any((t) => t.id == app.id && t.status == DownloadStatus.downloading);
    final completed = downloadService.tasks
        .where((t) => t.id == app.id && t.status == DownloadStatus.completed)
        .firstOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                  _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isFav ? Colors.red : null,
                ),
                onPressed: _toggleFav,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: colorScheme.primaryContainer,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CachedNetworkImage(
                      imageUrl: app.iconUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          Icon(Icons.android_rounded, size: 80, color: colorScheme.primary),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.name,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(app.developer,
                      style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _chip(Icons.category_outlined, app.categoryLabel),
                      if (app.fileType != null) _chip(Icons.insert_drive_file_outlined, app.fileTypeLabel),
                      if (app.language != null) _chip(Icons.code_rounded, app.language!),
                      _chip(Icons.star_rounded, app.rating.toStringAsFixed(1)),
                      _chip(Icons.sd_storage_outlined, app.size),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 主下载按钮
                  SizedBox(
                    width: double.infinity,
                    child: completed != null
                        ? FilledButton.icon(
                            onPressed: () => downloadService.openFile(completed.localPath!),
                            icon: const Icon(Icons.folder_open_rounded),
                            label: const Text('打开已下载文件'),
                            style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14)),
                          )
                        : isDownloading
                            ? FilledButton.icon(
                                onPressed: null,
                                icon: const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                label: const Text('下载中...'),
                                style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14)),
                              )
                            : FilledButton.icon(
                                onPressed: () {
                                  if (app.assets.isNotEmpty) {
                                    _downloadAsset(downloadService, app.assets.first);
                                  } else if (app.downloadUrl.isNotEmpty &&
                                      !app.downloadUrl.contains('github.com/')) {
                                    downloadService.startDownload(
                                      id: app.id,
                                      name: app.name,
                                      url: app.downloadUrl,
                                      iconUrl: app.iconUrl,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('开始下载 ${app.name}')),
                                    );
                                  } else if (app.githubUrl != null) {
                                    launchUrl(Uri.parse(app.githubUrl!),
                                        mode: LaunchMode.externalApplication);
                                  }
                                },
                                icon: const Icon(Icons.download_rounded),
                                label: Text(
                                  app.assets.isNotEmpty
                                      ? '下载 ${app.assets.first['name']}'
                                      : '下载',
                                ),
                                style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14)),
                              ),
                  ),
                  if (app.githubUrl != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri.parse(app.githubUrl!),
                            mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.code_rounded),
                        label: const Text('在 GitHub 查看'),
                      ),
                    ),
                  ],
                  // 全部可下载文件
                  if (app.assets.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text('可下载文件',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...app.assets.map((asset) {
                      final name = asset['name']?.toString() ?? 'file';
                      final size = asset['size']?.toString() ?? '';
                      final ft = asset['fileType']?.toString() ?? 'other';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(_iconForType(ft)),
                          title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text('$size · ${_typeLabel(ft)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.download_rounded),
                            onPressed: () => _downloadAsset(downloadService, asset),
                          ),
                          onTap: () => _downloadAsset(downloadService, asset),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 24),
                  Text('关于此应用',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(app.description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  Text('版本 ${app.version}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  IconData _iconForType(String ft) {
    switch (ft) {
      case 'apk':
        return Icons.android_rounded;
      case 'archive':
        return Icons.folder_zip_rounded;
      case 'windows':
        return Icons.desktop_windows_rounded;
      case 'linux':
        return Icons.terminal_rounded;
      case 'macos':
        return Icons.laptop_mac_rounded;
      case 'ipa':
        return Icons.phone_iphone_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _typeLabel(String ft) {
    switch (ft) {
      case 'apk':
        return 'Android 应用';
      case 'archive':
        return '压缩包';
      case 'windows':
        return 'Windows';
      case 'linux':
        return 'Linux';
      case 'macos':
        return 'macOS';
      case 'ipa':
        return 'iOS';
      case 'java':
        return 'Java';
      default:
        return '文件';
    }
  }
}
