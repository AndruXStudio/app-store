import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_provider.dart';
import '../models/app_model.dart';
import 'app_detail_screen.dart';
import 'search_screen.dart';
import 'downloads_screen.dart';
import '../services/download_service.dart';

class AppsTab extends StatefulWidget {
  const AppsTab({super.key});

  @override
  State<AppsTab> createState() => _AppsTabState();
}

class _AppsTabState extends State<AppsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadApps();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final downloadService = context.watch<DownloadService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('应用'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
            },
          ),
          Badge(
            isLabelVisible: downloadService.activeTasks.isNotEmpty,
            label: Text('${downloadService.activeTasks.length}'),
            child: IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen()));
              },
            ),
          ),
        ],
      ),
      body: provider.loadingApps
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<AppProvider>().loadApps(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: provider.apps.length,
                itemBuilder: (context, index) {
                  final app = provider.apps[index];
                  return _AppTile(app: app);
                },
              ),
            ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final AppModel app;
  const _AppTile({required this.app});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: app.iconUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            width: 60,
            height: 60,
            color: Colors.grey.shade200,
            child: const Icon(Icons.android_rounded),
          ),
        ),
      ),
      title: Text(app.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(app.developer, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
              Text(' ${app.rating.toStringAsFixed(1)}  ·  ${app.size}  ·  ${_formatDownloads(app.downloads)}'),
            ],
          ),
        ],
      ),
      isThreeLine: true,
      trailing: FilledButton.tonal(
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AppDetailScreen(app: app)));
        },
        child: const Text('安装'),
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => AppDetailScreen(app: app)));
      },
    );
  }

  String _formatDownloads(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
