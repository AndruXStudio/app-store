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

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final downloadService = context.watch<DownloadService>();
    final isDownloading = downloadService.tasks.any((t) => t.id == app.id && t.status == DownloadStatus.downloading);
    final completed = downloadService.tasks.where((t) => t.id == app.id && t.status == DownloadStatus.completed).firstOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(_isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isFav ? Colors.red : null),
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
                  Text(app.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(app.developer, style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _InfoChip(icon: Icons.star_rounded, label: app.rating.toStringAsFixed(1), color: Colors.amber.shade700),
                      const SizedBox(width: 12),
                      _InfoChip(icon: Icons.download_rounded, label: _format(app.downloads)),
                      const SizedBox(width: 12),
                      _InfoChip(icon: Icons.sd_storage_rounded, label: app.size),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: completed != null
                        ? FilledButton.icon(
                            onPressed: () => downloadService.openFile(completed.localPath!),
                            icon: const Icon(Icons.install_mobile_rounded),
                            label: const Text('安装 / 打开'),
                            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          )
                        : isDownloading
                            ? FilledButton.icon(
                                onPressed: null,
                                icon: const SizedBox(
                                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                label: const Text('下载中...'),
                                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                              )
                            : FilledButton.icon(
                                onPressed: () {
                                  if (app.downloadUrl.isEmpty ||
                                      (app.downloadUrl.contains('github.com') &&
                                          !app.downloadUrl.contains('releases') &&
                                          !app.downloadUrl.contains('download'))) {
                                    launchUrl(Uri.parse(app.githubUrl ?? app.downloadUrl),
                                        mode: LaunchMode.externalApplication);
                                  } else {
                                    downloadService.startDownload(
                                      id: app.id,
                                      name: app.name,
                                      url: app.downloadUrl,
                                      iconUrl: app.iconUrl,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('开始下载 ${app.name}')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.download_rounded),
                                label: const Text('下载'),
                                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                              ),
                  ),
                  if (app.githubUrl != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            launchUrl(Uri.parse(app.githubUrl!), mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.code_rounded),
                        label: const Text('在 GitHub 查看'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text('关于此应用', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(app.description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  Text('版本 ${app.version}',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M+';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K+';
    return '$n';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color ?? Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
