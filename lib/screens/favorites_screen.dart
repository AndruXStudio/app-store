import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/local_data_service.dart';
import '../models/app_model.dart';
import 'app_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _local = LocalDataService();
  List<AppModel> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _local.getFavorites();
    if (mounted) setState(() { _list = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的收藏')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('暂无收藏', style: TextStyle(color: Colors.grey.shade600)),
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
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite_rounded, color: Colors.red),
                        onPressed: () async {
                          await _local.toggleFavorite(app);
                          _load();
                        },
                      ),
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
