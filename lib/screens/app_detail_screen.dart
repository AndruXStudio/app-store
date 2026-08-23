import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/app_icon.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_model.dart';
import '../services/download_service.dart';
import '../services/local_data_service.dart';
import '../services/community_service.dart';
import '../services/auth_service.dart';
import '../services/catalog_service.dart';
import '../widgets/role_chip.dart';

class AppDetailScreen extends StatefulWidget {
  final AppModel app;
  const AppDetailScreen({super.key, required this.app});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  final _local = LocalDataService();
  final _community = CommunityService();
  final _auth = AuthService();
  final _catalog = CatalogService();
  final _commentCtrl = TextEditingController();

  bool _isFav = false;
  bool _liked = false;
  bool _catalogFav = false;
  List<Map<String, dynamic>> _comments = [];
  List<Map<String, dynamic>> _versions = [];
  String? _myUserId;
  String? _myUsername;

  @override
  void initState() {
    super.initState();
    _local.addHistory(widget.app);
    _local.isFavorite(widget.app.id).then((v) {
      if (mounted) setState(() => _isFav = v);
    });
    _loadCommunity();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCommunity() async {
    final me = await _auth.getCurrentUserModel();
    _myUserId = me?.id;
    _myUsername = me?.username;
    final cid = widget.app.catalogId;
    if (cid != null) {
      final comments = await _community.fetchComments(cid);
      final liked = await _community.isLiked(cid);
      final fav = await _community.isFavorited(cid);
      final versions = await _catalog.fetchVersions(cid);
      if (mounted) {
        setState(() {
          _comments = comments;
          _liked = liked;
          _catalogFav = fav;
          _versions = versions;
        });
      }
    }
  }

  Future<void> _toggleFav() async {
    await _local.toggleFavorite(widget.app);
    final v = await _local.isFavorite(widget.app.id);
    final cid = widget.app.catalogId;
    if (cid != null) {
      try {
        await _community.toggleFavorite(cid);
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _isFav = v;
        _catalogFav = v;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(v ? '已加入收藏' : '已取消收藏')),
      );
    }
  }

  Future<void> _toggleLike() async {
    final cid = widget.app.catalogId;
    if (cid == null) return;
    try {
      await _community.toggleLike(cid);
      final v = await _community.isLiked(cid);
      if (mounted) setState(() => _liked = v);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _sendComment() async {
    final cid = widget.app.catalogId;
    final text = _commentCtrl.text.trim();
    if (cid == null || text.isEmpty) return;
    try {
      await _community.addComment(cid, text);
      _commentCtrl.clear();
      await _loadCommunity();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _onCommentLongPress(Map<String, dynamic> c) {
    final id = c['id'];
    final uid = c['user_id']?.toString() ?? '';
    final isMine = uid == _myUserId || uid == _myUsername || c['username'] == _myUsername;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMine)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('删除'),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (id != null) {
                    await _community.deleteComment(id is int ? id : int.parse('$id'));
                    _loadCommunity();
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('举报'),
              onTap: () async {
                Navigator.pop(ctx);
                await _community.report(
                  targetType: 'comment',
                  targetId: '$id',
                  reason: 'user_report',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已提交举报')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('取消'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('开始下载 $name')));
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final downloadService = context.watch<DownloadService>();
    final role = app.publisherRole ?? 'user';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              if (app.catalogId != null)
                IconButton(
                  icon: Icon(_liked ? Icons.thumb_up : Icons.thumb_up_outlined),
                  onPressed: _toggleLike,
                ),
              IconButton(
                icon: Icon(
                  _isFav || _catalogFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: (_isFav || _catalogFav) ? Colors.red : null,
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
          AmSliverPad(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(app.developer,
                          style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
                    ),
                    RoleChip(role: role),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(Icons.category_outlined, app.categoryLabel),
                    if (app.fileType != null) _chip(Icons.android, 'APK'),
                    if (app.language != null) _chip(Icons.code_rounded, app.language!),
                    _chip(Icons.star_rounded, app.rating.toStringAsFixed(1)),
                    _chip(Icons.sd_storage_outlined, app.size),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (app.assets.isNotEmpty) {
                        _downloadAsset(downloadService, app.assets.first);
                      } else if (app.downloadUrl.isNotEmpty) {
                        downloadService.startDownload(
                          id: app.id,
                          name: app.name,
                          url: app.downloadUrl,
                          iconUrl: app.iconUrl,
                        );
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('开始下载 ${app.name}')));
                      }
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('下载 APK'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                if (app.assets.length > 1) ...[
                  const SizedBox(height: 16),
                  Text('可下载文件', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ...app.assets.map((asset) => Card(
                        margin: const EdgeInsets.only(top: 8),
                        child: ListTile(
                          leading: const Icon(Icons.android),
                          title: Text(asset['name']?.toString() ?? 'file'),
                          subtitle: Text('${asset['size'] ?? ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.download_rounded),
                            onPressed: () => _downloadAsset(downloadService, asset),
                          ),
                        ),
                      )),
                ],
                if (_versions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('历史版本', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ..._versions.map((v) => ListTile(
                        dense: true,
                        title: Text(v['version']?.toString() ?? ''),
                        subtitle: Text(v['changelog']?.toString() ?? v['size_label']?.toString() ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () {
                            final url = v['download_url']?.toString() ?? '';
                            if (url.isEmpty) return;
                            downloadService.startDownload(
                              id: '${app.id}_${v['version']}',
                              name: '${app.name}-${v['version']}',
                              url: url,
                              iconUrl: app.iconUrl,
                            );
                          },
                        ),
                      )),
                ],
                const SizedBox(height: 20),
                Text('关于', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(app.description, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text('版本 ${app.version}',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                if (app.catalogId != null) ...[
                  const SizedBox(height: 28),
                  Text('评论', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          decoration: const InputDecoration(
                            hintText: '写评论…',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(onPressed: _sendComment, icon: const Icon(Icons.send)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('暂无评论，来抢沙发'),
                    )
                  else
                    ..._comments.map((c) {
                      return InkWell(
                        onLongPress: () => _onCommentLongPress(c),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text((c['username']?.toString() ?? '?')[0].toUpperCase()),
                          ),
                          title: Text(c['username']?.toString() ?? '用户'),
                          subtitle: Text(c['content']?.toString() ?? ''),
                        ),
                      );
                    }),
                ],
                const SizedBox(height: 40),
              ],
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
}

class AmSliverPad extends StatelessWidget {
  final Widget child;
  const AmSliverPad({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: child));
  }
}
