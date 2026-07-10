-- ============================================================
--  HR 业务预约 - Supabase 表结构与权限
--  在 Supabase 控制台的 SQL Editor 中一次性执行本文件即可。
-- ============================================================

-- 1) 建表
create table if not exists public.reservations (
  id          uuid primary key default gen_random_uuid(),
  oa_account  text not null,
  biz_type    text not null,
  location    text not null,
  date        text not null,
  time        text not null,
  status      text not null default 'pending',
  created_at  timestamptz not null default now()
);

-- 2) 让实时（Realtime）监听这张表
alter publication supabase_realtime add table public.reservations;

-- 3) 开启行级安全（RLS），并放行匿名读写（内部 MVP 用）
alter table public.reservations enable row level security;

drop policy if exists "anon_select" on public.reservations;
create policy "anon_select" on public.reservations
  for select to anon using (true);

drop policy if exists "anon_insert" on public.reservations;
create policy "anon_insert" on public.reservations
  for insert to anon with check (true);

drop policy if exists "anon_update" on public.reservations;
create policy "anon_update" on public.reservations
  for update to anon using (true);
