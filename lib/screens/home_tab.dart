import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_provider.dart';
import '../services/download_service.dart';
import '../models/app_model.dart';
import 'app_detail_screen.dart';
import 'search_screen.dart';
import 'downloads_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadFeatured();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<AppProvider>();
    final downloadService = context.watch<DownloadService>();

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              title: const Text('App Store'),
              actions: [
                Badge(
                  isLabelVisible: downloadService.activeTasks.isNotEmpty,
                  label: Text('${downloadService.activeTasks.length}'),
                  child: IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.download_rounded),
                                title: const Text('下载管理'),
                                trailing: downloadService.activeTasks.isNotEmpty
                                    ? Text('${downloadService.activeTasks.length} 进行中')
                                    : null,
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const DownloadsScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SearchBar(
                    hintText: '搜索应用、游戏...',
                    leading: const Icon(Icons.search_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      );
                    },
                    trailing: [
                      IconButton(
                        icon: const Icon(Icons.tune_rounded),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: provider.loadingFeatured
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  final p = context.read<AppProvider>();
                  // force reload
                  await p.loadFeatured();
                },
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _buildSectionHeader(context, '精选推荐', Icons.star_rounded),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: provider.featured.take(8).length,
                        itemBuilder: (context, index) {
                          final app = provider.featured[index];
                          return _FeaturedCard(app: app);
                        },
                      ),
                    ),
                    _buildSectionHeader(context, '热门应用', Icons.local_fire_department_rounded),
                    ...provider.featured.where((a) => a.category == 'app').take(6).map(
                          (app) => _AppListTile(app: app),
                        ),
                    _buildSectionHeader(context, '热门游戏', Icons.sports_esports_rounded),
                    ...provider.featured.where((a) => a.category == 'game').take(4).map(
                          (app) => _AppListTile(app: app),
                        ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final AppModel app;
  const _FeaturedCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AppDetailScreen(app: app)),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: colorScheme.surfaceContainerHighest,
                  child: CachedNetworkImage(
                    imageUrl: app.iconUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (_, __, ___) => Icon(Icons.android_rounded, size: 48, color: colorScheme.primary),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app.developer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
                        const SizedBox(width: 2),
                        Text(app.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppListTile extends StatelessWidget {
  final AppModel app;
  const _AppListTile({required this.app});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: app.iconUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(width: 56, height: 56, color: Colors.grey.shade200),
          errorWidget: (_, __, ___) => Container(
            width: 56,
            height: 56,
            color: Colors.grey.shade200,
            child: const Icon(Icons.android),
          ),
        ),
      ),
      title: Text(app.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${app.developer} · ${app.size}'),
      trailing: FilledButton.tonal(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AppDetailScreen(app: app)),
          );
        },
        child: const Text('查看'),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AppDetailScreen(app: app)),
        );
      },
    );
  }
}
