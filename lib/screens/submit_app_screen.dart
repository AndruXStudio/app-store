import 'package:flutter/material.dart';
import '../services/catalog_service.dart';

class SubmitAppScreen extends StatefulWidget {
  const SubmitAppScreen({super.key});

  @override
  State<SubmitAppScreen> createState() => _SubmitAppScreenState();
}

class _SubmitAppScreenState extends State<SubmitAppScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _pkg = TextEditingController();
  final _dev = TextEditingController();
  final _desc = TextEditingController();
  final _icon = TextEditingController();
  final _version = TextEditingController(text: '1.0.0');
  final _size = TextEditingController();
  final _url = TextEditingController();
  String _category = 'app';
  bool _loading = false;
  final _catalog = CatalogService();

  @override
  void dispose() {
    _name.dispose();
    _pkg.dispose();
    _dev.dispose();
    _desc.dispose();
    _icon.dispose();
    _version.dispose();
    _size.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _catalog.submitApp(
        name: _name.text.trim(),
        packageName: _pkg.text.trim().isEmpty ? null : _pkg.text.trim(),
        developer: _dev.text.trim().isEmpty ? null : _dev.text.trim(),
        description: _desc.text.trim(),
        iconUrl: _icon.text.trim().isEmpty ? null : _icon.text.trim(),
        version: _version.text.trim(),
        sizeLabel: _size.text.trim(),
        downloadUrl: _url.text.trim(),
        category: _category,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已提交，等待管理员/开发者审核'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('投稿应用')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('提交后需审核通过才会上架', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: '应用名称 *', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? '必填' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _url,
              decoration: const InputDecoration(labelText: 'APK 直链 *', border: OutlineInputBorder()),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '必填';
                if (!v.startsWith('http')) return '需要 http(s) 链接';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pkg,
              decoration: const InputDecoration(labelText: '包名', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dev,
              decoration: const InputDecoration(labelText: '开发者/发布者', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _icon,
              decoration: const InputDecoration(labelText: '图标 URL', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _version,
                    decoration: const InputDecoration(labelText: '版本', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _size,
                    decoration: const InputDecoration(labelText: '大小', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: '分类', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'app', child: Text('应用')),
                DropdownMenuItem(value: 'game', child: Text('游戏')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'app'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              decoration: const InputDecoration(labelText: '简介', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('提交审核'),
            ),
          ],
        ),
      ),
    );
  }
}
