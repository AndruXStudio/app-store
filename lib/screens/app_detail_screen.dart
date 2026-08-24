import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_icon.dart';
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
  final _community = CommunityService();
  bool _isFav = false;
  bool _liked = false;
  int _likes = 0;
  List<Map<String, dynamic>> _comments = [];
  final _commentCtrl = TextEditingController();
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

  Future<void> _loadCommunity() async {
    final me = await _auth.getCurrentUserModel();
    _myUsername = me?.username;
    final cid = widget.app.catalogId;
    if (cid == null) return;
    try {
      _likes = await _community.likeCount(cid);
      if (_myUsername != null) {
        _liked = await _community.hasLiked(cid, _myUsername!);
      }
      _comments = await _community.comments(cid);
    } catch (_) {}
    if (mounted) setState(() {});
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

  Future<void> _toggleLike() async {
    final cid = widget.app.catalogId;
    if (cid == null || _myUsername == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录后再点赞')),
      );
      return;
    }
    try {
      await _community.toggleLike(cid, _myUsername!);
      final v = await _community.hasLiked(cid, _myUsername!);
      final count = await _community.likeCount(cid);
      if (mounted) setState(() { _liked = v; _likes = count; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _sendComment() async {
    final cid = widget.app.catalogId;
    final text = _commentCtrl.text.trim();
    if (cid == null || text.isEmpty) return;
    if (_myUsername == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先登录')));
      return;
    }
    try {
      await _community.addComment(cid, _myUsername!, text);
      _commentCtrl.clear();
      await _loadCommunity();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _onCommentLongPress(Map<String, dynamic> c) {
    final id = c['id'];
    final isMine = c['username']?.toString() == _myUsername;
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
                if (_myUsername != null) {
                  await _community.report(
                    targetType: 'comment',
                    targetId: '$id',
                    reporter: _myUsername!,
                    reason: 'user_report',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已提交举报')),
                    );
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
    ds.startDownload(
      id: '${widget.app.id}_$name',
      name: name,
      url: url,
      iconUrl: widget.app.iconUrl,
    );
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
                  child: AppIcon(url: app.iconUrl, name: app.name, size: 100, radius: 24),
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
                                      builder: (_) =>
                                          UserProfileScreen(username: app.submitterUsername),
                                    ),
                                  );
                                }
                              : null,
                          child: Text(
                            app.developer,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: colorScheme.primary),
                          ),
                        ),
                      ),
                      RoleChip(role: role),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text(app.categoryLabel), visualDensity: VisualDensity.compact),
                      Chip(label: Text('APK'), visualDensity: VisualDensity.compact),
                      Chip(label: Text(app.size), visualDensity: VisualDensity.compact),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _toggleLike,
                        icon: Icon(
                          _liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                          color: _liked ? colorScheme.primary : null,
                        ),
                      ),
                      Text('$_likes'),
                    ],
                  ),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('开始下载 ${app.name}')),
                          );
                        }
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('下载 APK'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (app.changelog != null && app.changelog!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('版本说明',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(app.changelog!),
                  ],
                  const SizedBox(height: 16),
                  Text('关于',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(app.description),
                  Text('版本 ${app.version}', style: theme.textTheme.bodySmall),
                  if (app.catalogId != null) ...[
                    const Divider(height: 32),
                    Text('评论',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                        IconButton(
                          onPressed: _sendComment,
                          icon: const Icon(Icons.send_rounded),
                        ),
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
}
