import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import '../models/app_model.dart';
import 'app_detail_screen.dart';
import '../widgets/role_chip.dart';

class UserProfileScreen extends StatefulWidget {
  final String? username; // null = 当前用户
  const UserProfileScreen({super.key, this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _auth = AuthService();
  final _com = CommunityService();
  Map<String, dynamic>? _profile;
  List<AppModel> _apps = [];
  bool _loading = true;
  bool _isSelf = false;
  String _username = '';
  String _role = 'user';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final me = await _auth.getCurrentUserModel();
    _username = widget.username ?? me?.username ?? '';
    _isSelf = me != null && me.username == _username;
    _profile = await _com.getProfile(_username);
    _role = _profile?['role']?.toString() ?? await _com.getUserRole(_username);
    _apps = await _com.appsByUser(_username);
    // 主页只展示已通过的
    _apps = _apps.where((a) => a.status == 'approved' || a.status == null).toList();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit() async {
    final nameC = TextEditingController(text: _profile?['display_name']?.toString() ?? _username);
    final avatarC = TextEditingController(text: _profile?['avatar_url']?.toString() ?? '');
    final bioC = TextEditingController(text: _profile?['bio']?.toString() ?? '');
    final tagsC = TextEditingController(text: _profile?['tags']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑资料'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: '显示名称')),
              TextField(controller: avatarC, decoration: const InputDecoration(labelText: '头像 URL')),
              TextField(controller: bioC, decoration: const InputDecoration(labelText: '简介')),
              TextField(controller: tagsC, decoration: const InputDecoration(labelText: '标签（逗号分隔）')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
        ],
      ),
    );
    if (ok == true) {
      await _com.updateProfile(
        username: _username,
        displayName: nameC.text.trim(),
        avatarUrl: avatarC.text.trim(),
        bio: bioC.text.trim(),
        tags: tagsC.text.trim(),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = _profile?['display_name']?.toString() ?? _username;
    final avatar = _profile?['avatar_url']?.toString();
    final bio = _profile?['bio']?.toString() ?? '';
    final tags = (_profile?['tags']?.toString() ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户主页'),
        actions: [
          if (_isSelf) IconButton(icon: const Icon(Icons.edit_rounded), onPressed: _edit),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                      child: avatar == null || avatar.isEmpty
                          ? Text(display.isNotEmpty ? display[0].toUpperCase() : '?')
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(display, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          RoleChip(role: _role),
                          if (bio.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(bio, style: theme.textTheme.bodyMedium),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: tags.map((t) => Chip(label: Text(t), visualDensity: VisualDensity.compact)).toList(),
                  ),
                ],
                const SizedBox(height: 8),
                Text('已上架 ${_apps.length} 个应用', style: theme.textTheme.bodySmall),
                const Divider(height: 32),
                Text('发布的应用', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_apps.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('暂无已上架应用')),
                  )
                else
                  ..._apps.map((app) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: app.iconUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.android),
                        ),
                      ),
                      title: Text(app.name),
                      subtitle: Text('v${app.version} · ${app.size}${app.changelog != null ? '\n${app.changelog}' : ''}'),
                      isThreeLine: app.changelog != null,
                      trailing: RoleChip(role: app.submitterRole ?? _role),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AppDetailScreen(app: app)),
                        );
                      },
                    );
                  }),
              ],
            ),
    );
  }
}
