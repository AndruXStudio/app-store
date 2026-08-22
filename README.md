# AnNexus

开源应用商店 · Flutter Material 3 · Supabase Auth · GitHub 应用源

## 包名
`com.andrux.nexus`

## 功能
- 登录 / 注册（支持用户名或邮箱登录）
- Material 3 + 底部 NavigationBar
- GitHub 搜索应用 / 游戏
- 应用内下载管理
- 个人中心

## 运行
```bash
flutter pub get
flutter run
flutter build apk --release
```

## Supabase
- URL / anon key 已写在 `lib/config/supabase_config.dart`
- Auth 使用 email+password
- `public.users` 表可选：用于用户名→邮箱解析和资料展示
  - 建议字段：`id (uuid, PK, = auth.users.id)`, `username (text unique)`, `email (text)`, `avatar_url (text)`
