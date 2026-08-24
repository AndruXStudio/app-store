-- 1) 允许更新 apps（审核用）—— 必须执行，否则对号无效
drop policy if exists "update apps" on public.apps;
create policy "update apps" on public.apps
  for update using (true) with check (true);

-- 2) 确保可读取
drop policy if exists "select apps" on public.apps;
create policy "select apps" on public.apps
  for select using (true);

-- 3) 确保可插入投稿
drop policy if exists "insert apps" on public.apps;
create policy "insert apps" on public.apps
  for insert with check (true);

-- 4) 补列（没有会报错）
alter table public.apps add column if not exists changelog text;
alter table public.apps add column if not exists status text default 'pending';
alter table public.apps add column if not exists published boolean default false;
alter table public.apps add column if not exists category text default 'app';
alter table public.apps add column if not exists reviewed_at timestamptz;
alter table public.apps add column if not exists review_note text;
alter table public.apps add column if not exists reject_reason text;
alter table public.apps add column if not exists publisher_role text;
alter table public.apps add column if not exists submitter_username text;
alter table public.apps add column if not exists submitter_role text;
alter table public.apps add column if not exists submitter_id text;
alter table public.apps add column if not exists size_label text;
alter table public.apps add column if not exists package_name text;
alter table public.apps add column if not exists icon_url text;
alter table public.apps add column if not exists download_url text;
alter table public.apps add column if not exists sort_order int default 0;

-- 5) 手动通过「测试程序」（如果还在 pending）
update public.apps
set status = 'approved', published = true
where status = 'pending';
