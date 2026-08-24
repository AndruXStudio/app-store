import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  String? _pickedName;
  File? _apkFile;
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

  Future<void> _pickApk() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    if (f.path == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法读取文件路径')),
        );
      }
      return;
    }
    setState(() {
      _apkFile = File(f.path!);
      _pickedName = f.name;
      final bytes = f.size;
      if (bytes > 0) {
        if (bytes < 1024 * 1024) {
          _size.text = '${(bytes / 1024).toStringAsFixed(0)} KB';
        } else {
          _size.text = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
      }
      if (_name.text.trim().isEmpty) {
        _name.text = f.name.replaceAll(RegExp(r'\.apk$', caseSensitive: false), '');
      }
    });
  }

  Future<String?> _uploadApk(String username) async {
    if (_apkFile == null) return null;
    final client = Supabase.instance.client;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final safeName = (_pickedName ?? 'app.apk').replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final path = 'apks/$username/${ts}_$safeName';
    final bytes = await _apkFile!.readAsBytes();
    await client.storage.from('apps').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'application/vnd.android.package-archive', upsert: true),
        );
    final publicUrl = client.storage.from('apps').getPublicUrl(path);
    return publicUrl;
  }


  Future<void> _pickIcon() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    final bytes = f.bytes ?? (f.path != null ? await File(f.path!).readAsBytes() : null);
    if (bytes == null) return;
    // limit ~200KB for base64 in DB
    if (bytes.length > 300 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('图标请小于 300KB，或使用图标 URL')),
        );
      }
      return;
    }
    final b64 = base64Encode(bytes);
    final mime = (f.extension ?? 'png').toLowerCase() == 'jpg' || (f.extension ?? '') == 'jpeg'
        ? 'image/jpeg'
        : 'image/png';
    setState(() {
      _icon.text = 'data:$mime;base64,$b64';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已选择图标（将以 base64 保存）')));
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_apkFile == null && _url.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择本地 APK 或填写下载链接')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await _auth.getCurrentUserModel();
      if (user == null) throw Exception('请先登录');
      final role = await _com.getUserRole(user.username);

      String downloadUrl = _url.text.trim();
      if (_apkFile != null) {
        final uploaded = await _uploadApk(user.username);
        if (uploaded == null || uploaded.isEmpty) {
          throw Exception('APK 上传失败，请检查 Storage 桶 apps 是否已创建并公开');
        }
        downloadUrl = uploaded;
      }

      await _com.submitApp(
        name: _name.text.trim(),
        packageName: _pkg.text.trim(),
        developer: _dev.text.trim().isEmpty ? user.username : _dev.text.trim(),
        description: _desc.text.trim(),
        downloadUrl: downloadUrl,
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
          const SnackBar(content: Text('已提交，等待审核通过后上架')),
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
      appBar: AppBar(title: const Text('发布应用')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '支持本地选择 APK 上传，或填写直链。提交后需审核通过才会显示。',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickApk,
              icon: const Icon(Icons.android_rounded),
              label: Text(_pickedName == null ? '从本机选择 APK' : '已选：$_pickedName'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _url,
              decoration: const InputDecoration(
                labelText: '或填写 APK 直链（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: '应用名称 *', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? '必填' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pkg,
              decoration: const InputDecoration(
                labelText: '包名 *',
                hintText: 'com.example.app',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? '必填' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dev,
              decoration: const InputDecoration(labelText: '发布者（可留空）', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _icon,
              decoration: const InputDecoration(
                labelText: '图标 URL 或 base64（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickIcon,
              icon: const Icon(Icons.image_outlined),
              label: const Text('从相册选择图标（转 base64）'),
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
                    decoration: const InputDecoration(labelText: '大小', border: OutlineInputBorder()),
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
              decoration: const InputDecoration(labelText: '版本说明', border: OutlineInputBorder()),
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
