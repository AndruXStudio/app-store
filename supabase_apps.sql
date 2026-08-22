-- AnNexus 信任库：在 Supabase SQL Editor 中整段执行

create table if not exists public.apps (
  id bigint generated always as identity primary key,
  name text not null,
  package_name text,
  developer text default 'AnNexus',
  description text default '',
  icon_url text,
  version text default '1.0.0',
  size_label text default '',
  download_url text not null,
  homepage text,
  category text default 'app' check (category in ('app', 'game')),
  language text,
  rating numeric(2,1) default 4.5,
  downloads int default 0,
  published boolean default true,
  sort_order int default 0,
  created_at timestamptz default now()
);

-- 索引
create index if not exists apps_published_idx on public.apps (published);
create index if not exists apps_name_idx on public.apps (name);

-- RLS：所有人可读已上架；写入请在后台用 service role 或暂时关 RLS 调试
alter table public.apps enable row level security;

drop policy if exists "public read published apps" on public.apps;
create policy "public read published apps"
  on public.apps for select
  using (published = true);

-- 如需在客户端投稿上架（谨慎），可再开 insert 策略；默认仅后台添加

-- 示例数据（把 download_url 换成你有权分发的真实 APK 地址）
insert into public.apps
  (name, package_name, developer, description, icon_url, version, size_label, download_url, category, sort_order)
values
  (
    '示例应用',
    'com.example.demo',
    'AnNexus',
    '这是信任库示例，请替换为真实 APK 直链',
    'https://ui-avatars.com/api/?name=Demo&background=01875F&color=fff',
    '1.0.0',
    '5 MB',
    'https://example.com/demo.apk',
    'app',
    0
  );
