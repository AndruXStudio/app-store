import 'package:flutter/material.dart';
import '../services/community_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _com = CommunityService();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _list = await _com.pendingApps();
    } catch (e) {
      _list = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载失败: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _review(dynamic rawId, bool ok) async {
    final id = rawId is int ? rawId : int.tryParse('$rawId');
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无效 ID')));
      return;
    }
    String? reason;
    if (!ok) {
      reason = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final c = TextEditingController();
          return AlertDialog(
            title: const Text('拒绝原因'),
            content: TextField(controller: c, decoration: const InputDecoration(hintText: '可选')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('确定')),
            ],
          );
        },
      );
      if (reason == null) return;
    }
    try {
      await _com.reviewApp(id, approve: ok, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? '已通过并上架' : '已拒绝')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败（多半是 RLS 未允许 update）: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, inner) => [
          const SliverAppBar.large(title: Text('审核投稿')),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? const Center(child: Text('暂无待审核应用'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _list.length,
                      itemBuilder: (context, i) {
                        final a = _list[i];
                        final id = a['id'];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            title: Text(a['name']?.toString() ?? ''),
                            subtitle: Text(
                              '${a['submitter_username'] ?? a['developer'] ?? ''} · ${a['version'] ?? ''}\n${a['download_url'] ?? ''}',
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => _review(id, true),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => _review(id, false),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
