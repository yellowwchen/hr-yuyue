-- ============================================================
--  HR 业务预约 - 表结构 + 带登录隔离的权限策略（v2）
--  在 Supabase 控制台的 SQL Editor 中一次性执行本文件。
--  注意：本文件会替换旧的匿名读写策略，改为“登录后只能看自己的”。
-- ============================================================

-- 1) 建表（如已存在则补 user_id 列）
create table if not exists public.reservations (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade,
  oa_account  text not null,
  biz_type    text not null,
  location    text not null,
  date        text not null,
  time        text not null,
  status      text not null default 'pending',
  created_at  timestamptz not null default now()
);

-- 已有旧表补列（首次执行时列已存在，不会报错）
alter table public.reservations add column if not exists user_id uuid references auth.users(id) on delete cascade;

-- 2) 管理员表：用 OA 账号标识哪些人能看全部记录
create table if not exists public.admins (
  oa_account text primary key
);
insert into public.admins (oa_account) values
  ('yellowwchen'),
  ('narcisszhao')
on conflict (oa_account) do nothing;

-- 3) 让实时（Realtime）监听这张表
alter publication supabase_realtime add table public.reservations;

-- 4) 开启行级安全（RLS），并删除旧的匿名策略
alter table public.reservations enable row level security;

drop policy if exists "anon_select" on public.reservations;
drop policy if exists "anon_insert" on public.reservations;
drop policy if exists "anon_update" on public.reservations;
drop policy if exists "auth_select_own_or_admin" on public.reservations;
drop policy if exists "auth_insert_own" on public.reservations;
drop policy if exists "auth_update_own_or_admin" on public.reservations;

-- 辅助函数：从登录邮箱（格式 oa@oa.local）中取出 OA 账号
create or replace function public.current_oa() returns text
  language sql stable as $$
    select split_part(auth.email(), '@', 1);
  $$;

-- 5) 新策略：登录用户只能看/改“自己”的；管理员可看全部
create policy "auth_select_own_or_admin" on public.reservations
  for select to authenticated
  using (auth.uid() = user_id OR public.current_oa() in (select oa_account from public.admins));

create policy "auth_insert_own" on public.reservations
  for insert to authenticated
  with check (auth.uid() = user_id);

create policy "auth_update_own_or_admin" on public.reservations
  for update to authenticated
  using (auth.uid() = user_id OR public.current_oa() in (select oa_account from public.admins));

-- 6) 清理无主的旧测试数据（首次上线前执行一次即可；之后可注释掉）
--    RLS 下 user_id 为 NULL 的旧记录任何人都看不到，留着也无害。
-- delete from public.reservations where user_id is null;
