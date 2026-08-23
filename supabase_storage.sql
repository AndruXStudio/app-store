-- Supabase Storage：用于用户上传 APK
-- 1. 控制台 → Storage → New bucket → 名称 apps → 勾选 Public bucket
-- 2. 再执行下面策略（允许登录用户上传；公开可读）

-- 若用 SQL 创建桶（也可在界面点）：
insert into storage.buckets (id, name, public)
values ('apps', 'apps', true)
on conflict (id) do update set public = true;

drop policy if exists "public read apps bucket" on storage.objects;
create policy "public read apps bucket"
  on storage.objects for select
  using (bucket_id = 'apps');

drop policy if exists "anyone upload apps" on storage.objects;
create policy "anyone upload apps"
  on storage.objects for insert
  with check (bucket_id = 'apps');

drop policy if exists "anyone update apps" on storage.objects;
create policy "anyone update apps"
  on storage.objects for update
  using (bucket_id = 'apps');
