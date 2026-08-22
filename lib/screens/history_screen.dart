import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/local_data_service.dart';
import '../models/app_model.dart';
import 'app_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _local = LocalDataService();
  List<AppModel> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _local.getHistory();
    if (mounted) setState(() { _list = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('浏览历史'),
        actions: [
          if (_list.isNotEmpty)
            TextButton(
              onPressed: () async {
                await _local.clearHistory();
                _load();
              },
              child: const Text('清空'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('暂无浏览记录', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _list.length,
                  itemBuilder: (context, i) {
                    final app = _list[i];
                    return ListTile(
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
                      subtitle: Text(app.developer),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AppDetailScreen(app: app)),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
