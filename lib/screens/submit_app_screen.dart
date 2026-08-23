import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';

class SubmitAppScreen extends StatefulWidget {
  const SubmitAppScreen({super.key});

  @override
  State<SubmitAppScreen> createState() => _SubmitAppScreenState();
}

class _SubmitAppScreenState extends State<SubmitAppScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _pkg = TextEditingController();
  final _dev = TextEditingController();
  final _desc = TextEditingController();
  final _url = TextEditingController();
  final _ver = TextEditingController(text: '1.0.0');
  final _size = TextEditingController();
  final _icon = TextEditingController();
  final _log = TextEditingController();
  String _cat = 'app';
  bool _loading = false;
  final _auth = AuthService();
  final _com = CommunityService();

  @override
  void dispose() {
    _name.dispose();
    _pkg.dispose();
    _dev.dispose();
    _desc.dispose();
    _url.dispose();
    _ver.dispose();
    _size.dispose();
    _icon.dispose();
    _log.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await _auth.getCurrentUserModel();
      if (user == null) throw Exception('请先登录');
      final role = await _com.getUserRole(user.username);
      await _com.submitApp(
        name: _name.text.trim(),
        packageName: _pkg.text.trim(),
        developer: _dev.text.trim().isEmpty ? user.username : _dev.text.trim(),
        description: _desc.text.trim(),
        downloadUrl: _url.text.trim(),
        version: _ver.text.trim(),
        sizeLabel: _size.text.trim(),
        submitterUsername: user.username,
        submitterRole: role,
        iconUrl: _icon.text.trim().isEmpty ? null : _icon.text.trim(),
        category: _cat,
        changelog: _log.text.trim().isEmpty ? null : _log.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已提交，等待管理员/开发者审核')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('提交应用')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('提交后需管理员或开发者审核通过才会上架',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: '应用名称 *', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? '必填' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pkg,
              decoration: const InputDecoration(labelText: '包名 *', hintText: 'com.example.app', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? '必填' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dev,
              decoration: const InputDecoration(labelText: '发布者（可留空=你的用户名）', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _url,
              decoration: const InputDecoration(labelText: 'APK 直链 *', border: OutlineInputBorder()),
              validator: (v) => v == null || !v.trim().startsWith('http') ? '需要 http(s) 直链' : null,
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
                    controller: _ver,
                    decoration: const InputDecoration(labelText: '版本', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _size,
                    decoration: const InputDecoration(labelText: '大小', hintText: '12 MB', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _cat,
              decoration: const InputDecoration(labelText: '分类', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'app', child: Text('应用')),
                DropdownMenuItem(value: 'game', child: Text('游戏')),
              ],
              onChanged: (v) => setState(() => _cat = v ?? 'app'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '简介', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _log,
              maxLines: 2,
              decoration: const InputDecoration(labelText: '版本说明 / 更新日志', border: OutlineInputBorder()),
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
