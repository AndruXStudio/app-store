import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import '../models/app_model.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final _auth = AuthService();
  final _com = CommunityService();
  List<AppModel> _list = [];
  bool _loading = true;
  String? _username;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await _auth.getCurrentUserModel();
    _username = u?.username;
    if (_username != null) {
      _list = await _com.myPosts(_username!);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(AppModel app) async {
    final id = app.catalogId;
    if (id == null || _username == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除投稿'),
        content: Text('确定删除「${app.name}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await _com.deleteMyApp(id, _username!);
      _load();
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'approved':
        return '已上架';
      case 'rejected':
        return '已拒绝';
      case 'pending':
        return '审核中';
      default:
        return s ?? '未知';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('帖子管理')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? const Center(child: Text('你还没有提交过应用'))
              : ListView.builder(
                  itemCount: _list.length,
                  itemBuilder: (context, i) {
                    final app = _list[i];
                    return ListTile(
                      title: Text(app.name),
                      subtitle: Text('${_statusLabel(app.status)} · ${app.version}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(app),
                      ),
                    );
                  },
                ),
    );
  }
}
