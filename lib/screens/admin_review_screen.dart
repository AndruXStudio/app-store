import 'package:flutter/material.dart';
import '../services/catalog_service.dart';

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  final _catalog = CatalogService();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _catalog.fetchPending();
    if (mounted) setState(() { _list = list; _loading = false; });
  }

  Future<void> _review(int id, bool approve) async {
    await _catalog.reviewApp(id, approve: approve);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(approve ? '已通过上架' : '已拒绝')),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('审核投稿')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? const Center(child: Text('暂无待审核'))
              : ListView.builder(
                  itemCount: _list.length,
                  itemBuilder: (context, i) {
                    final m = _list[i];
                    final id = m['id'] is int ? m['id'] as int : int.parse('${m['id']}');
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(m['name']?.toString() ?? ''),
                        subtitle: Text(
                          '${m['developer'] ?? ''} · ${m['version'] ?? ''}\n${m['download_url'] ?? ''}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: 4,
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
    );
  }
}
