import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final s = await _local.loadSettings();
    if (mounted) setState(() { _settings = s; _loading = false; });
  }

  Future<void> _update(String key, dynamic value) async {
    setState(() => _settings[key] = value);
    await _local.saveSettings(_settings);
  }

  Future<void> _openQQGroup() async {
    final uri = Uri.parse(
      'mqqapi://card/show_pslcard?src_type=internal&version=1&card_type=group&source=external&uin=1045956482',
    );
    final web = Uri.parse(
      'https://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=&jump_from=webapi&authKey=&group_code=1045956482',
    );
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

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final items = <Widget>[
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
          if (v != null) await _update('darkMode', v);
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
        onTap: () async {
          await Clipboard.setData(const ClipboardData(text: '1045956482'));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('群号已复制')),
            );
          }
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
            applicationLegalese:
                '用户发布的应用商店\n包名 com.andrux.nexus\n官方群：1045956482',
          );
        },
      ),
      // 仅少量底部留白，方便滚到最后一项，不再大片空白
      const SizedBox(height: 32),
    ];

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            expandedHeight: 132.0,
            floating: false,
            pinned: true,
            snap: false,
            centerTitle: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              // 参考第二视频：折叠后紧挨返回键，展开时大标题在下方左侧
              titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
              expandedTitleScale: 1.6,
              title: Text(
                '设置',
                style: TextStyle(
                  color: onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              collapseMode: CollapseMode.pin,
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverList(delegate: SliverChildListDelegate(items)),
        ],
      ),
    );
  }
}
