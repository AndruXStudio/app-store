
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_model.dart';
import '../services/download_service.dart';
import '../services/local_data_service.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import '../widgets/role_chip.dart';
import 'user_profile_screen.dart';

class AppDetailScreen extends StatefulWidget {
  final AppModel app;
  const AppDetailScreen({super.key, required this.app});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  final _local = LocalDataService();
  final _auth = AuthService();
  final _com = CommunityService();
  bool _isFav = false;
  bool _liked = false;
  int _likes = 0;
  List<Map<String, dynamic>> _comments = [];
  final _commentCtrl = TextEditingController();
  String? _myName;

  @override
  void initState() {
    super.initState();
    _local.addHistory(widget.app);
    _local.isFavorite(widget.app.id).then((v) {
      if (mounted) setState(() => _isFav = v);
    });
    _loadSocial();
  }

  Future<void> _loadSocial() async {
    final me = await _auth.getCurrentUserModel();
    _myName = me?.username;
    final id = widget.app.catalogId;
    if (id == null) return;
    try {
      _likes = await _com.likeCount(id);
      if (_myName != null) _liked = await _com.hasLiked(id, _myName!);
      _comments = await _com.comments(id);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _toggleFav() async {
    await _local.toggleFavorite(widget.app);
    final v = await _local.isFavorite(widget.app.id);
    if (mounted) {
      setState(() => _isFav = v);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(v ? '已收藏' : '已取消收藏')));
    }
  }

  Future<void> _toggleLike() async {
    final id = widget.app.catalogId;
    if (id == null || _myName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('仅信任库应用支持点赞')));
      return;
    }
    await _com.toggleLike(id, _myName!);
    await _loadSocial();
  }

  Future<void> _sendComment() async {
    final id = widget.app.catalogId;
    final text = _commentCtrl.text.trim();
    if (id == null || _myName == null || text.isEmpty) return;
    await _com.addComment(id, _myName!, text);
    _commentCtrl.clear();
    await _loadSocial();
  }

  void _onCommentLongPress(Map<String, dynamic> c) {
    final id = c['id'];
    final isMine = c['username']?.toString() == _myName;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMine)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('删除'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _com.deleteComment(id as int);
                  _loadSocial();
                },
              ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('举报'),
              onTap: () async {
                Navigator.pop(ctx);
                if (_myName != null) {
                  await _com.report(
                    targetType: 'comment',
                    targetId: '$id',
                    reporter: _myName!,
                    reason: 'user_report',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已举报')));
                  }
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
    ds.startDownload(id: '${widget.app.id}_$name', name: name, url: url, iconUrl: widget.app.iconUrl);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('开始下载 $name')));
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final downloadService = context.watch<DownloadService>();
    final role = app.submitterRole ?? 'user';

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
                      errorWidget: (_, __, ___) => Icon(Icons.android_rounded, size: 80, color: colorScheme.primary),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: app.submitterUsername != null
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserProfileScreen(username: app.submitterUsername),
                                    ),
                                  );
                                }
                              : null,
                          child: Text(app.developer,
                              style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
                        ),
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _toggleLike,
                        icon: Icon(_liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            color: _liked ? colorScheme.primary : null),
                      ),
                      Text('$_likes'),
                      const SizedBox(width: 16),
                      Icon(Icons.favorite, size: 18, color: Colors.red.shade300),
                      const SizedBox(width: 4),
                      const Text('收藏'),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                    ...app.assets.map((asset) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(asset['name']?.toString() ?? ''),
                          subtitle: Text(asset['size']?.toString() ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.download_rounded),
                            onPressed: () => _downloadAsset(downloadService, asset),
                          ),
                        )),
                  ],
                  if (app.changelog != null && app.changelog!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('版本说明', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(app.changelog!),
                  ],
                  const SizedBox(height: 16),
                  Text('关于', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(app.description),
                  Text('版本 ${app.version}', style: theme.textTheme.bodySmall),
                  if (app.catalogId != null) ...[
                    const Divider(height: 32),
                    Text('评论', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentCtrl,
                            decoration: const InputDecoration(
                              hintText: '写评论...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(onPressed: _sendComment, icon: const Icon(Icons.send_rounded)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._comments.map((c) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(c['username']?.toString() ?? ''),
                        subtitle: Text(c['content']?.toString() ?? ''),
                        onLongPress: () => _onCommentLongPress(c),
                      );
                    }),
                  ],
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
}
