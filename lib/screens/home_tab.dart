import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/local_data_service.dart';
import 'settings_screen.dart';

/// 首页：嵌入静态网页（网盘目录站 / 数据管理前台等）
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _local = LocalDataService();
  WebViewController? _controller;
  String _url = '';
  bool _loading = true;
  bool _pageLoading = false;
  String? _error;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final s = await _local.loadSettings();
    final url = (s['homePageUrl'] as String?)?.trim() ?? '';
    if (!mounted) return;
    setState(() {
      _url = url;
      _loading = false;
    });
    if (url.isNotEmpty) {
      _setupWebView(url);
    }
  }

  void _setupWebView(String url) {
    final c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() { _pageLoading = true; _progress = 0; _error = null; });
          },
          onProgress: (p) {
            if (mounted) setState(() => _progress = p / 100.0);
          },
          onPageFinished: (_) {
            if (mounted) setState(() { _pageLoading = false; _progress = 1; });
          },
          onWebResourceError: (e) {
            if (mounted) {
              setState(() {
                _pageLoading = false;
                _error = e.description;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
    setState(() => _controller = c);
  }

  Future<void> _reloadSettingsAndOpen() async {
    setState(() => _loading = true);
    await _init();
  }

  Future<void> _editUrl() async {
    final ctrl = TextEditingController(text: _url);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('首页网页地址'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'https://你的静态站地址',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final s = await _local.loadSettings();
    s['homePageUrl'] = result;
    await _local.saveSettings(s);
    if (!mounted) return;
    setState(() {
      _url = result;
      _error = null;
      _controller = null;
    });
    if (result.isNotEmpty) {
      _setupWebView(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 未配置 URL：引导填写
    if (_url.isEmpty || _controller == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('首页'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                _reloadSettingsAndOpen();
              },
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language_rounded, size: 64, color: colorScheme.primary),
                const SizedBox(height: 16),
                const Text(
                  '首页将嵌入你的静态网页',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '填写网盘目录站 / 数据管理前台的网址后即可显示。\n用户点链接会跳转网盘下载。',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _editUrl,
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('设置网页地址'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: [
          if (_pageLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller?.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.link_rounded),
            tooltip: '更换地址',
            onPressed: _editUrl,
          ),
        ],
        bottom: _pageLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress == 0 ? null : _progress),
              )
            : null,
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48),
                    const SizedBox(height: 12),
                    Text('加载失败\n$_error', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: () => _controller?.reload(), child: const Text('重试')),
                    TextButton(onPressed: _editUrl, child: const Text('更换地址')),
                  ],
                ),
              ),
            )
          : WebViewWidget(controller: _controller!),
    );
  }
}
