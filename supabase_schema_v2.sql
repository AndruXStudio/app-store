-- AnNexus 完整社区版 Schema（SQL Editor 执行）

-- 用户资料（与登录 users 表兼容：若已有 users 表可 ALTER）
create table if not exists public.users (
  id text primary key,
  users text unique,
  password text,
  email text,
  display_name text,
  avatar_url text,
  bio text,
  tags text default '',
  role text default 'user' check (role in ('user', 'admin', 'creator')),
  created_at timestamptz default now()
);

-- 若表已存在，补齐字段
alter table public.users add column if not exists display_name text;
alter table public.users add column if not exists avatar_url text;
alter table public.users add column if not exists bio text;
alter table public.users add column if not exists tags text default '';
alter table public.users add column if not exists role text default 'user';

-- 应用信任库 / 投稿
create table if not exists public.apps (
  id bigint generated always as identity primary key,
  name text not null,
  package_name text,
  developer text default '',
  description text default '',
  icon_url text,
  version text default '1.0.0',
  size_label text default '',
  download_url text not null,
  homepage text,
  category text default 'app',
  language text,
  rating numeric(2,1) default 4.5,
  downloads int default 0,
  likes_count int default 0,
  comments_count int default 0,
  favorites_count int default 0,
  published boolean default false,
  status text default 'pending' check (status in ('pending', 'approved', 'rejected')),
  submitter_id text,
  publisher_role text default 'user',
  sort_order int default 0,
  created_at timestamptz default now(),
  reviewed_at timestamptz,
  review_note text
);

alter table public.apps add column if not exists likes_count int default 0;
alter table public.apps add column if not exists comments_count int default 0;
alter table public.apps add column if not exists favorites_count int default 0;
alter table public.apps add column if not exists status text default 'pending';
alter table public.apps add column if not exists submitter_id text;
alter table public.apps add column if not exists publisher_role text default 'user';
alter table public.apps add column if not exists reviewed_at timestamptz;
alter table public.apps add column if not exists review_note text;

-- 历史版本
create table if not exists public.app_versions (
  id bigint generated always as identity primary key,
  app_id bigint references public.apps(id) on delete cascade,
  version text not null,
  size_label text,
  download_url text not null,
  changelog text default '',
  created_at timestamptz default now()
);

-- 评论
create table if not exists public.app_comments (
  id bigint generated always as identity primary key,
  app_id bigint references public.apps(id) on delete cascade,
  user_id text not null,
  username text,
  content text not null,
  created_at timestamptz default now()
);

-- 点赞（应用）
create table if not exists public.app_likes (
  app_id bigint references public.apps(id) on delete cascade,
  user_id text not null,
  created_at timestamptz default now(),
  primary key (app_id, user_id)
);

-- 收藏
create table if not exists public.app_favorites (
  app_id bigint references public.apps(id) on delete cascade,
  user_id text not null,
  created_at timestamptz default now(),
  primary key (app_id, user_id)
);

-- 举报
create table if not exists public.reports (
  id bigint generated always as identity primary key,
  target_type text not null,
  target_id text not null,
  reporter_id text,
  reason text,
  created_at timestamptz default now()
);

-- RLS
alter table public.apps enable row level security;
alter table public.app_comments enable row level security;
alter table public.app_likes enable row level security;
alter table public.app_favorites enable row level security;
alter table public.app_versions enable row level security;
alter table public.reports enable row level security;
alter table public.users enable row level security;

-- 已上架可读
drop policy if exists "read approved apps" on public.apps;
create policy "read approved apps" on public.apps for select using (
  status = 'approved' and published = true
);

-- 投稿人可读自己的
drop policy if exists "read own submissions" on public.apps;
create policy "read own submissions" on public.apps for select using (true);

-- 任何人可投稿（pending）
drop policy if exists "insert apps" on public.apps;
create policy "insert apps" on public.apps for insert with check (true);

-- 更新（审核/自己删改）—— 简化：允许 update（生产应收紧）
drop policy if exists "update apps" on public.apps;
create policy "update apps" on public.apps for update using (true);

drop policy if exists "delete apps" on public.apps;
create policy "delete apps" on public.apps for delete using (true);

drop policy if exists "read comments" on public.app_comments;
create policy "read comments" on public.app_comments for select using (true);
drop policy if exists "insert comments" on public.app_comments;
create policy "insert comments" on public.app_comments for insert with check (true);
drop policy if exists "delete comments" on public.app_comments;
create policy "delete comments" on public.app_comments for delete using (true);

drop policy if exists "likes all" on public.app_likes;
create policy "likes all" on public.app_likes for all using (true) with check (true);

drop policy if exists "favs all" on public.app_favorites;
create policy "favs all" on public.app_favorites for all using (true) with check (true);

drop policy if exists "versions read" on public.app_versions;
create policy "versions read" on public.app_versions for select using (true);
drop policy if exists "versions write" on public.app_versions;
create policy "versions write" on public.app_versions for all using (true) with check (true);

drop policy if exists "reports insert" on public.reports;
create policy "reports insert" on public.reports for insert with check (true);

drop policy if exists "users read" on public.users;
create policy "users read" on public.users for select using (true);
drop policy if exists "users update" on public.users;
create policy "users update" on public.users for update using (true);

-- 把某个账号设为创建者（改成你的用户名）
-- update public.users set role = 'creator' where users = '你的用户名';
-- update public.users set role = 'admin' where users = '管理员用户名';
