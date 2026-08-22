# App Store - Flutter Material 3 应用商店

类似 Google Play 的开源应用商店，对接 GitHub 获取应用，使用 Supabase 做用户认证。

## 功能

- 登录 / 注册（Supabase Auth，用户名+邮箱+密码）
- 登录成功动画：居中卡片 CircularProgressIndicator → 变成对勾
- Material 3 全局主题 + Material Icons
- 底部 NavigationBar（首页 / 应用 / 游戏 / 我的），带图标填充动画
- 首页：搜索栏 + 三点菜单（下载管理）+ 精选推荐
- 应用 / 游戏列表，来自 GitHub Search API（无需魔法）
- 应用详情：评分、下载量、大小、下载按钮、跳转 GitHub
- 应用内下载管理（Dio），支持 .apk / .zip 等
- 我的：头像、用户名、下载管理、退出登录

## 运行

```bash
flutter pub get
flutter run
```

## 打包 Android

```bash
flutter build apk --release
```

## Supabase 配置

已内置：
- URL: https://fnlaryjanmfqvnonqfyj.supabase.co
- 登录/注册表需支持 email + password，user_metadata 存 username

## 技术栈

- Flutter 3.32 + Material 3
- supabase_flutter
- provider
- dio / path_provider / open_filex
- cached_network_image
- http (GitHub API)

## 注意

- GitHub API 有 rate limit，未登录时约 60 次/小时，失败会回退到内置示例数据
- 真机安装 APK 需要用户手动允许「未知来源」
- Web 端下载会直接标记完成（浏览器限制）
