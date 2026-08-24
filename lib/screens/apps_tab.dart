import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_model.dart';
import 'app_detail_screen.dart';
import 'search_screen.dart';
import 'downloads_screen.dart';
import '../services/download_service.dart';
import '../widgets/role_chip.dart';
import '../widgets/app_icon.dart';

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
    // 只显示 category == app（provider 已过滤）
    final list = provider.apps;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar.large(
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
        ],
        body: provider.loadingApps
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => context.read<AppProvider>().loadApps(),
                child: list.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('暂无已上架应用')),
                          SizedBox(height: 8),
                          Center(child: Text('去「我的 → 投稿应用」提交，审核通过后显示')),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: list.length,
                        itemBuilder: (context, index) => _AppTile(app: list[index]),
                      ),
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
      leading: AppIcon(url: app.iconUrl, name: app.name, size: 56, radius: 14),
      title: Text(app.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(app.developer, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            children: [
              if (app.submitterRole != null) RoleChip(role: app.submitterRole!),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${app.version} · ${app.size}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
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
    );
  }
}
