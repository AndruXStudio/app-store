import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_model.dart';
import 'app_detail_screen.dart';
import 'search_screen.dart';
import 'downloads_screen.dart';
import '../services/download_service.dart';
import '../widgets/app_icon.dart';

class GamesTab extends StatefulWidget {
  const GamesTab({super.key});

  @override
  State<GamesTab> createState() => _GamesTabState();
}

class _GamesTabState extends State<GamesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final downloadService = context.watch<DownloadService>();
    final list = provider.games;

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ignore: prefer_const_constructors
          SliverAppBar.large(
            pinned: true,
            floating: false,
            title: const Text('游戏'),
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
          if (provider.loadingGames)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (list.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('暂无已上架游戏\n发布时把分类选成「游戏」')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: //
                    SliverChildBuilderDelegate(
                  (context, index) => _GameCard(app: list[index]),
                  childCount: list.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final AppModel app;
  const _GameCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AppDetailScreen(app: app)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: colorScheme.surfaceContainerHighest,
                child: Center(
                  child: AppIcon(url: app.iconUrl, name: app.name, size: 72, radius: 16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(app.developer, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
                      Text(' ${app.rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12)),
                      const Spacer(),
                      Text(app.size, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
