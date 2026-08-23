import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/catalog_service.dart';
import 'login_screen.dart';
import 'downloads_screen.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'submit_app_screen.dart';
import 'admin_review_screen.dart';
import 'user_profile_screen.dart';
import '../widgets/role_chip.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _auth = AuthService();
  final _catalog = CatalogService();
  String _username = 'User';
  String? _email;
  String? _avatarUrl;
  String _role = 'user';
  bool _isStaff = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _auth.getCurrentUserModel();
    final role = await _catalog.getMyRole();
    if (user != null && mounted) {
      setState(() {
        _username = user.username;
        _email = user.email;
        _avatarUrl = user.avatarUrl;
        _role = role;
        _isStaff = role == 'admin' || role == 'creator';
      });
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
              child: _avatarUrl == null
                  ? Text(
                      _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 36,
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _username,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
          Center(child: RoleChip(role: _role)),
          if (_email != null)
            Center(
              child: Text(
                _email!,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.tonalIcon(
              onPressed: _openQQGroup,
              icon: const Icon(Icons.groups_rounded),
              label: const Text('加入官方 QQ 群  1045956482'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _tile(Icons.person_rounded, '我的主页', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()));
          }),
          _tile(Icons.upload_rounded, '投稿应用', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitAppScreen()));
          }),
          if (_isStaff)
            _tile(Icons.admin_panel_settings_rounded, '管理审核', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReviewScreen()));
            }),
          _tile(Icons.download_rounded, '下载管理', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen()));
          }),
          _tile(Icons.favorite_outline_rounded, '我的收藏', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
          }),
          _tile(Icons.history_rounded, '浏览历史', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
          }),
          _tile(Icons.settings_outlined, '设置', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
          _tile(Icons.info_outline_rounded, '关于', () {
            showAboutDialog(
              context: context,
              applicationName: 'AnNexus',
              applicationVersion: '1.0.0',
              applicationLegalese: '开源应用商店\n官方群：1045956482',
            );
          }),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('退出登录'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
