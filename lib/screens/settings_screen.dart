import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/local_data_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _local = LocalDataService();
  Map<String, dynamic> _settings = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _local.getSettings();
    if (mounted) {
      setState(() {
        _settings = s;
        _loading = false;
      });
    }
  }

  Future<void> _update(String key, dynamic value) async {
    setState(() => _settings[key] = value);
    await _local.saveSettings(_settings);
  }

  Future<void> _openQQGroup() async {
    // QQ 群号 1045956482
    final uri = Uri.parse(
      'mqqapi://card/show_pslcard?src_type=internal&version=1&card_type=group&source=external&uin=1045956482',
    );
    final web = Uri.parse('https://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=&jump_from=webapi&authKey=&group_code=1045956482');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(web, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _section('外观'),
                ListTile(
                  leading: const Icon(Icons.brightness_6_rounded),
                  title: const Text('深色模式'),
                  subtitle: Text(_darkLabel(_settings['darkMode'] ?? 'system')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final v = await showModalBottomSheet<String>(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('跟随系统'),
                              onTap: () => Navigator.pop(ctx, 'system'),
                            ),
                            ListTile(
                              title: const Text('浅色'),
                              onTap: () => Navigator.pop(ctx, 'light'),
                            ),
                            ListTile(
                              title: const Text('深色'),
                              onTap: () => Navigator.pop(ctx, 'dark'),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (v != null) {
                      await _update('darkMode', v);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('主题将在下次启动时完整生效，部分页面已即时更新')),
                        );
                      }
                    }
                  },
                ),
                _section('下载'),
                SwitchListTile(
                  secondary: const Icon(Icons.wifi_rounded),
                  title: const Text('仅 Wi‑Fi 下载'),
                  subtitle: const Text('开启后移动网络下不自动下载'),
                  value: _settings['wifiOnlyDownload'] == true,
                  onChanged: (v) => _update('wifiOnlyDownload', v),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.science_outlined),
                  title: const Text('显示预发布版本'),
                  subtitle: const Text('GitHub 搜索包含 pre-release'),
                  value: _settings['showPreRelease'] != false,
                  onChanged: (v) => _update('showPreRelease', v),
                ),
                _section('社区'),
                ListTile(
                  leading: const Icon(Icons.groups_rounded, color: Colors.blue),
                  title: const Text('加入官方 QQ 群'),
                  subtitle: const Text('群号：1045956482'),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: _openQQGroup,
                ),
                ListTile(
                  leading: const Icon(Icons.tag_rounded),
                  title: const Text('复制群号'),
                  subtitle: const Text('1045956482'),
                  onTap: () {
                    // simple feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('群号 1045956482（请手动复制）')),
                    );
                  },
                ),
                _section('关于'),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('关于 AnNexus'),
                  subtitle: const Text('版本 1.0.0'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'AnNexus',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '开源应用商店\n基于 Flutter · Supabase · GitHub\n包名 com.andrux.nexus',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.code_rounded),
                  title: const Text('开源仓库'),
                  subtitle: const Text('github.com/AndruXStudio/app-store'),
                  onTap: () {
                    launchUrl(
                      Uri.parse('https://github.com/AndruXStudio/app-store'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'AnNexus · 发现优质开源应用',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  String _darkLabel(String v) {
    switch (v) {
      case 'light':
        return '浅色';
      case 'dark':
        return '深色';
      default:
        return '跟随系统';
    }
  }
}
