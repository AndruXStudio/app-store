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
  String _filter = 'all'; // all | app | archive | language filters later

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadApps();
    });
  }

  List<AppModel> _filtered(List<AppModel> all) {
    if (_filter == 'all') return all;
    if (_filter == 'archive') return all.where((a) => a.category == 'archive' || a.fileType == 'archive').toList();
    if (_filter == 'app') {
      return all.where((a) => a.category == 'app' || a.fileType == 'apk' || a.fileType == null).toList();
    }
    // language filter e.g. lang:Dart
    if (_filter.startsWith('lang:')) {
      final lang = _filter.substring(5).toLowerCase();
      return all.where((a) => (a.language ?? '').toLowerCase() == lang).toList();
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final downloadService = context.watch<DownloadService>();
    final list = _filtered(provider.apps);

    // collect languages for chips
    final langs = <String>{};
    for (final a in provider.apps) {
      if (a.language != null && a.language!.isNotEmpty) langs.add(a.language!);
    }
    final langList = langs.toList()..sort();

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
                _chip('全部', 'all'),
                _chip('应用程序', 'app'),
                _chip('压缩包', 'archive'),
                ...langList.take(8).map((l) => _chip(l, 'lang:$l')),
              ],
            ),
          ),
          Expanded(
            child: provider.loadingApps
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context.read<AppProvider>().loadApps(),
                    child: list.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text('该分类下暂无内容')),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final app = list[index];
                              return _AppTile(app: app);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
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
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: [
              _miniTag(app.categoryLabel),
              if (app.fileType != null) _miniTag(app.fileTypeLabel),
              if (app.language != null) _miniTag(app.language!),
              Text(
                '${app.rating.toStringAsFixed(1)} ★ · ${app.size}',
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
        child: const Text('查看'),
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => AppDetailScreen(app: app)));
      },
    );
  }

  Widget _miniTag(String text) {
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
