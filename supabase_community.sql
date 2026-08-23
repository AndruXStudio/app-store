-- AnNexus 社区 + 投稿审核 + 角色（SQL Editor 执行）

-- 用户资料扩展（与登录 users 表兼容：users 列是用户名）
alter table public.users add column if not exists display_name text;
alter table public.users add column if not exists avatar_url text;
alter table public.users add column if not exists bio text;
alter table public.users add column if not exists tags text default ''; -- 逗号分隔自定义标签
alter table public.users add column if not exists role text default 'user'; -- user | developer | admin | creator

-- 应用表增强
alter table public.apps add column if not exists status text default 'pending'; -- pending | approved | rejected
alter table public.apps add column if not exists submitter_username text;
alter table public.apps add column if not exists submitter_role text default 'user';
alter table public.apps add column if not exists reject_reason text;
alter table public.apps add column if not exists changelog text; -- 版本说明
-- published 保留：approved 时设 true

-- 评论
create table if not exists public.app_comments (
  id bigint generated always as identity primary key,
  app_id bigint references public.apps(id) on delete cascade,
  username text not null,
  content text not null,
  created_at timestamptz default now()
);

-- 点赞（应用）
create table if not exists public.app_likes (
  id bigint generated always as identity primary key,
  app_id bigint references public.apps(id) on delete cascade,
  username text not null,
  created_at timestamptz default now(),
  unique(app_id, username)
);

-- 举报
create table if not exists public.reports (
  id bigint generated always as identity primary key,
  target_type text not null, -- comment | app
  target_id text not null,
  reporter text not null,
  reason text default '',
  created_at timestamptz default now()
);

-- RLS 放宽（演示用；上线请收紧）
alter table public.apps enable row level security;
alter table public.app_comments enable row level security;
alter table public.app_likes enable row level security;
alter table public.reports enable row level security;

drop policy if exists "read apps" on public.apps;
create policy "read apps" on public.apps for select using (true);

drop policy if exists "insert apps" on public.apps;
create policy "insert apps" on public.apps for insert with check (true);

drop policy if exists "update apps" on public.apps;
create policy "update apps" on public.apps for update using (true);

drop policy if exists "read comments" on public.app_comments;
create policy "read comments" on public.app_comments for select using (true);
drop policy if exists "insert comments" on public.app_comments;
create policy "insert comments" on public.app_comments for insert with check (true);
drop policy if exists "delete comments" on public.app_comments;
create policy "delete comments" on public.app_comments for delete using (true);

drop policy if exists "read likes" on public.app_likes;
create policy "read likes" on public.app_likes for select using (true);
drop policy if exists "insert likes" on public.app_likes;
create policy "insert likes" on public.app_likes for insert with check (true);
drop policy if exists "delete likes" on public.app_likes;
create policy "delete likes" on public.app_likes for delete using (true);

drop policy if exists "insert reports" on public.reports;
create policy "insert reports" on public.reports for insert with check (true);
drop policy if exists "read reports" on public.reports;
create policy "read reports" on public.reports for select using (true);

-- 用户表可读可改自己资料（演示：全开）
drop policy if exists "read users" on public.users;
create policy "read users" on public.users for select using (true);
drop policy if exists "update users" on public.users;
create policy "update users" on public.users for update using (true);

-- 把某个账号设为创建者（改成你的用户名）
-- update public.users set role = 'creator' where users = '你的用户名';
-- update public.users set role = 'admin' where users = '管理员用户名';
