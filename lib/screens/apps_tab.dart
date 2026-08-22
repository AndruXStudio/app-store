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
    final list = provider.apps;

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
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _sourceChip(provider, '全部源', 'all'),
                _sourceChip(provider, 'F-Droid', 'fdroid'),
                _sourceChip(provider, 'GitHub APK', 'github'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '仅显示可下载的 APK（聚合多站点）',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          Expanded(
            child: provider.loadingApps
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context.read<AppProvider>().refreshAll(),
                    child: list.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text('暂无 APK，下拉刷新或切换源')),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: list.length,
                            itemBuilder: (context, index) => _AppTile(app: list[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sourceChip(AppProvider provider, String label, String value) {
    final selected = provider.source == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => provider.setSource(value),
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final AppModel app;
  const _AppTile({required this.app});

  @override
  Widget build(BuildContext context) {
    final src = app.source == 'fdroid'
        ? 'F-Droid'
        : app.source == 'github'
            ? 'GitHub'
            : (app.source ?? '');
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
          Wrap(
            spacing: 6,
            children: [
              if (src.isNotEmpty) _tag(src),
              _tag('APK'),
              if (app.language != null) _tag(app.language!),
              Text(
                '${app.version} · ${app.size}',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
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
        child: const Text('下载'),
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => AppDetailScreen(app: app)));
      },
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }
}
