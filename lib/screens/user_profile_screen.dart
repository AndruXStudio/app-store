import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/catalog_service.dart';
import '../models/app_model.dart';
import 'app_detail_screen.dart';
import '../widgets/role_chip.dart';

class UserProfileScreen extends StatefulWidget {
  /// 为空则看自己
  final String? username;
  final String? userId;

  const UserProfileScreen({super.key, this.username, this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _auth = AuthService();
  final _catalog = CatalogService();
  final _client = Supabase.instance.client;

  bool _loading = true;
  bool _isMe = false;
  String _displayName = '';
  String _username = '';
  String? _avatar;
  String _bio = '';
  String _tags = '';
  String _role = 'user';
  List<AppModel> _apps = [];

  final _nameCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _avatarCtrl.dispose();
    _bioCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final me = await _auth.getCurrentUserModel();
    final targetName = widget.username ?? me?.username ?? '';
    final targetId = widget.userId ?? me?.id ?? '';
    _isMe = me != null &&
        (widget.username == null ||
            widget.username == me.username ||
            widget.userId == me.id);

    Map<String, dynamic>? row;
    try {
      if (targetId.isNotEmpty) {
        row = await _client.from('users').select().eq('id', targetId).maybeSingle();
      }
      row ??= await _client.from('users').select().eq('users', targetName).maybeSingle();
    } catch (_) {}

    _username = row?['users']?.toString() ?? targetName;
    _displayName = row?['display_name']?.toString() ?? _username;
    _avatar = row?['avatar_url']?.toString();
    _bio = row?['bio']?.toString() ?? '';
    _tags = row?['tags']?.toString() ?? '';
    _role = row?['role']?.toString() ?? 'user';

    _nameCtrl.text = _displayName;
    _avatarCtrl.text = _avatar ?? '';
    _bioCtrl.text = _bio;
    _tagsCtrl.text = _tags;

    final sid = targetId.isNotEmpty ? targetId : _username;
    _apps = await _catalog.fetchBySubmitter(sid);
    // 自己也能看 pending；别人只看 approved
    if (!_isMe) {
      _apps = _apps.where((a) => a.status == 'approved').toList();
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    final me = await _auth.getCurrentUserModel();
    if (me == null) return;
    try {
      await _client.from('users').update({
        'display_name': _nameCtrl.text.trim(),
        'avatar_url': _avatarCtrl.text.trim().isEmpty ? null : _avatarCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'tags': _tagsCtrl.text.trim(),
      }).or('id.eq.${me.id},users.eq.${me.username}');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('资料已保存')));
      setState(() => _loading = true);
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    }
  }

  Future<void> _deleteApp(AppModel app) async {
    final id = app.catalogId;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除应用'),
        content: Text('确定删除「${app.name}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await _catalog.deleteApp(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isMe ? '我的主页' : '用户主页'),
        actions: [
          if (_isMe)
            TextButton(onPressed: _saveProfile, child: const Text('保存')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundImage: _avatar != null && _avatar!.isNotEmpty ? NetworkImage(_avatar!) : null,
              child: (_avatar == null || _avatar!.isEmpty)
                  ? Text(
                      _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 32),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(child: RoleChip(role: _role)),
          const SizedBox(height: 8),
          if (_isMe) ...[
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '显示名称', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _avatarCtrl, decoration: const InputDecoration(labelText: '头像 URL', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _tagsCtrl, decoration: const InputDecoration(labelText: '自定义标签（逗号分隔）', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _bioCtrl, maxLines: 2, decoration: const InputDecoration(labelText: '简介', border: OutlineInputBorder())),
          ] else ...[
            Center(
              child: Text(_displayName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ),
            if (_tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  children: _tags.split(',').where((e) => e.trim().isNotEmpty).map((t) {
                    return Chip(label: Text(t.trim(), style: const TextStyle(fontSize: 12)), visualDensity: VisualDensity.compact);
                  }).toList(),
                ),
              ),
            if (_bio.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_bio, textAlign: TextAlign.center),
              ),
          ],
          const SizedBox(height: 20),
          Text('发布的应用', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_apps.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('暂无发布')),
            )
          else
            ..._apps.map((app) {
              return Card(
                child: ListTile(
                  title: Text(app.name),
                  subtitle: Text(
                    '${app.version} · ${app.status == 'approved' ? '已上架' : app.status == 'pending' ? '审核中' : app.status ?? ''}',
                  ),
                  trailing: _isMe
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteApp(app),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: app.status == 'approved' || _isMe
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AppDetailScreen(app: app)),
                          );
                        }
                      : null,
                ),
              );
            }),
        ],
      ),
    );
  }
}
